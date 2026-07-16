import 'dart:io';
import 'package:flutter/material.dart' hide FormField;
import 'package:flutter/widgets.dart' as fw show FormField;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme_extensions.dart';
import '../../constants/app_colors.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/logger.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/premium_components.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data constants
// ─────────────────────────────────────────────────────────────────────────────

const _buyerTypes = ['Individual/Household', 'Restaurant', 'Hotel', 'Retail'];
const _deliveryTimes = ['Morning', 'Afternoon', 'Evening', 'Anytime'];

// ─────────────────────────────────────────────────────────────────────────────
// Route helper
// ─────────────────────────────────────────────────────────────────────────────
String _routeForRole(UserRole role) {
  switch (role) {
    case UserRole.buyer:
      return '/dashboard/buyer';
    case UserRole.streetSeller:
      return '/dashboard/street_seller';
    case UserRole.admin:
      return '/dashboard/admin';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final scrollCtrl = useScrollController();

    // ── Common fields ─────────────────────────────────────────────────────────
    final nameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final phoneCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final selectedRole = useState<UserRole?>(null);
    final profilePhoto = useState<File?>(null);
    final termsAccepted = useState(false);
    final obscurePassword = useState(true);
    final obscureConfirm = useState(true);
    final isLoading = useState(false);

    // ── Street Seller fields ──────────────────────────────────────────────────
    final transportType = useState<String?>(null);
    final equipmentPhoto = useState<File?>(null);

    // ── Buyer fields ──────────────────────────────────────────────────────────
    final buyerType = useState<String?>(null);
    final deliveryAddressCtrl = useTextEditingController();
    final preferredDeliveryTime = useState<String?>(null);
    final businessNameCtrl = useTextEditingController();

    final authService = ref.watch(authServiceProvider);
    final userService = ref.watch(userServiceProvider);
    final cloudinary = CloudinaryService();
    // ImagePicker is lightweight and stateless — construct it directly
    // rather than memoising. A useMemoized closure can become stale and
    // return the same instance if the picker invokes late callbacks
    // while the widget rebuilts, which historically caused "selected
    // photo doesn't render" bugs.
    final picker = ImagePicker();

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────
    Future<void> pickProfilePhoto() async {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const _PhotoSourceSheet(title: 'Profile Photo'),
      );
      if (source == null) return;
      final x = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 800);
      if (x != null) profilePhoto.value = File(x.path);
    }

    Future<void> pickEquipmentPhoto() async {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const _PhotoSourceSheet(title: 'Equipment Photo'),
      );
      if (source == null) return;
      final x = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1200);
      if (x != null) equipmentPhoto.value = File(x.path);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Validation helpers
    // ─────────────────────────────────────────────────────────────────────────
    String? validatePhone(String? v) {
      if (v == null || v.isEmpty) return 'Phone number is required';
      final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
      final pattern = RegExp(r'^\+255[6-7][0-9]{8}$');
      if (!pattern.hasMatch(digits)) {
        return 'Enter Tanzanian format: +255XXXXXXXXX';
      }
      return null;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Submit
    // ─────────────────────────────────────────────────────────────────────────
    Future<void> handleRegister() async {
      if (!formKey.currentState!.validate()) {
        _snack(context, 'Please fill in all required fields.', isError: true);
        return;
      }

      isLoading.value = true;
      try {
        mockUser = null;
        // 1. Firebase Auth sign up
        final user = await authService.signUp(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
          fullName: nameCtrl.text.trim(),
        );
        if (user == null || !context.mounted) return;

        // 2. Upload profile photo if provided
        String? photoUrl;
        if (profilePhoto.value != null) {
          photoUrl = await cloudinary.uploadImage(
            profilePhoto.value!,
            folder: 'profile_photos',
          );
        }

        // 3. Build role-specific metadata
        final Map<String, dynamic> extraData = {};
        final role = selectedRole.value!;
        if (role == UserRole.streetSeller) {
          extraData['transportType'] = transportType.value;
          if (equipmentPhoto.value != null) {
            final eUrl = await cloudinary.uploadImage(
              equipmentPhoto.value!,
              folder: 'equipment_photos',
            );
            extraData['equipmentPhotoUrl'] = eUrl;
          }
        } else if (role == UserRole.buyer) {
          extraData['buyerType'] = buyerType.value;
          extraData['deliveryAddress'] = deliveryAddressCtrl.text.trim();
          extraData['preferredDeliveryTime'] = preferredDeliveryTime.value;
          extraData['businessName'] = businessNameCtrl.text.trim();
        }

        // 4. Build and save UserModel
        final now = DateTime.now();
        final userModel = UserModel(
          userId: user.uid,
          email: emailCtrl.text.trim(),
          fullName: nameCtrl.text.trim(),
          phoneNumber: phoneCtrl.text.trim(),
          role: role,
          profilePictureUrl: photoUrl,
          location: extraData.isEmpty ? null : extraData,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await userService.saveUser(userModel);

        AppLogger.info('Registration complete for: ${user.uid}');
        if (context.mounted) {
          _snack(context, 'Welcome to SamakiFresh!');
          context.go(_routeForRole(role));
        }
      } catch (e) {
        AppLogger.error('Registration error: $e');
        if (context.mounted) {
          _snack(context, ErrorHandler.getErrorMessage(e), isError: true);
        }
      } finally {
        isLoading.value = false;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Build
    // ─────────────────────────────────────────────────────────────────────────
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final tokens = BackgroundStyle.of(context);
    final gradients = AppGradients.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _Header(onBack: () => context.go('/login'), gradient: gradients.hero),

          // ── Form ────────────────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: formKey,
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // ── Profile photo ────────────────────────────────────────
                  const _SectionHeader(
                      label: 'Profile Photo',
                      icon: Icons.camera_alt_rounded,
                      optional: true),
                  const SizedBox(height: 12),
                  _ProfilePhotoPicker(
                    file: profilePhoto.value,
                    onTap: pickProfilePhoto,
                  ),
                  const SizedBox(height: 24),

                  // ── Personal info ────────────────────────────────────────
                  const _SectionHeader(
                      label: 'Personal Information',
                      icon: Icons.person_rounded),
                  const SizedBox(height: 12),
                  const _FieldLabel('Full Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: themedInputDec(context, hint: 'e.g. Juma Hassan'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      if (v.trim().length < 3) {
                        return 'At least 3 characters required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Email Address'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: themedInputDec(context, hint: 'you@example.com'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Phone Number'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    ],
                    decoration: themedInputDec(context, hint: '+255712345678'),
                    validator: validatePhone,
                  ),
                  const SizedBox(height: 16),

                  // ── Password ─────────────────────────────────────────────
                  const _FieldLabel('Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword.value,
                    textInputAction: TextInputAction.next,
                    decoration: themedInputDec(
                      context,
                      hint: '••••••••',
                      suffix: _EyeButton(
                        obscure: obscurePassword.value,
                        onTap: () =>
                            obscurePassword.value = !obscurePassword.value,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Confirm Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm.value,
                    textInputAction: TextInputAction.done,
                    decoration: themedInputDec(
                      context,
                      hint: '••••••••',
                      suffix: _EyeButton(
                        obscure: obscureConfirm.value,
                        onTap: () =>
                            obscureConfirm.value = !obscureConfirm.value,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (v != passwordCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Role selection ───────────────────────────────────────
                  const _SectionHeader(
                      label: 'Your Role', icon: Icons.badge_rounded),
                  const SizedBox(height: 4),
                  const _FieldHint(
                      text: 'Select how you participate in SamakiFresh'),
                  const SizedBox(height: 14),
                  fw.FormField<UserRole>(
                    initialValue: selectedRole.value,
                    validator: (v) =>
                        v == null ? 'Please select your role' : null,
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RoleSelector(
                            selected: selectedRole.value,
                            onChanged: (role) {
                              state.didChange(role);
                              selectedRole.value = role;
                            },
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 6),
                              child: Text(
                                state.errorText ?? '',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Role-specific extra fields ────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    alignment: Alignment.topCenter,
                    curve: Curves.easeInOut,
                    child: _buildRoleFields(
                      context: context,
                      role: selectedRole.value,
                      // Street Seller
                      transportType: transportType,
                      equipmentPhoto: equipmentPhoto,
                      onPickEquipmentPhoto: pickEquipmentPhoto,
                      // Buyer
                      buyerType: buyerType,
                      deliveryAddressCtrl: deliveryAddressCtrl,
                      preferredDeliveryTime: preferredDeliveryTime,
                      businessNameCtrl: businessNameCtrl,
                    ),
                  ),

                  // ── Terms & Conditions ────────────────────────────────────
                  const SizedBox(height: 8),
                  fw.FormField<bool>(
                    initialValue: termsAccepted.value,
                    validator: (v) => v == true
                        ? null
                        : 'You must accept the Terms & Conditions',
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TermsCheckbox(
                            value: state.value ?? false,
                            onChanged: (v) {
                              state.didChange(v);
                              termsAccepted.value = v ?? false;
                            },
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 6),
                              child: Text(
                                state.errorText ?? '',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Submit ────────────────────────────────────────────────
                  GradientButton(
                    label: 'Create Account',
                    prefixIcon: Icons.person_add_rounded,
                    onPressed: isLoading.value ? null : handleRegister,
                    isLoading: isLoading.value,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.70),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role-specific extra fields builder
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildRoleFields({
  required BuildContext context,
  required UserRole? role,
  // Street Seller
  required ValueNotifier<String?> transportType,
  required ValueNotifier<File?> equipmentPhoto,
  required VoidCallback onPickEquipmentPhoto,
  // Buyer
  required ValueNotifier<String?> buyerType,
  required TextEditingController deliveryAddressCtrl,
  required ValueNotifier<String?> preferredDeliveryTime,
  required TextEditingController businessNameCtrl,
}) {
  if (role == null) return const SizedBox.shrink(key: ValueKey('none'));

  switch (role) {
    case UserRole.streetSeller:
      return _StreetSellerFields(
        key: const ValueKey('street_seller'),
        transportType: transportType,
        equipmentPhoto: equipmentPhoto,
        onPickPhoto: onPickEquipmentPhoto,
      );
    case UserRole.buyer:
      return _BuyerFields(
        key: const ValueKey('buyer'),
        buyerType: buyerType,
        deliveryAddressCtrl: deliveryAddressCtrl,
        preferredDeliveryTime: preferredDeliveryTime,
        businessNameCtrl: businessNameCtrl,
      );
    default:
      return const SizedBox.shrink(key: ValueKey('default'));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Street Seller extra fields
// ─────────────────────────────────────────────────────────────────────────────
class _StreetSellerFields extends HookWidget {
  final ValueNotifier<String?> transportType;
  final ValueNotifier<File?> equipmentPhoto;
  final VoidCallback onPickPhoto;

  const _StreetSellerFields({
    super.key,
    required this.transportType,
    required this.equipmentPhoto,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
            label: 'Street Seller Details',
            icon: Icons.storefront_rounded,
            color: Color(0xFFE65100)),
        const SizedBox(height: 12),
        const _FieldLabel('Transport Type'),
        const SizedBox(height: 10),
        _TransportPicker(
          valueNotifier: transportType,
          validator: (v) => v == null ? 'Transport type is required' : null,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Vehicle/Equipment Photo', optional: true),
        const SizedBox(height: 8),
        _SmallPhotoPicker(
          file: equipmentPhoto.value,
          onTap: onPickPhoto,
          label: 'Add equipment photo',
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buyer extra fields
// ─────────────────────────────────────────────────────────────────────────────
class _BuyerFields extends HookWidget {
  final ValueNotifier<String?> buyerType;
  final TextEditingController deliveryAddressCtrl;
  final ValueNotifier<String?> preferredDeliveryTime;
  final TextEditingController businessNameCtrl;

  const _BuyerFields({
    super.key,
    required this.buyerType,
    required this.deliveryAddressCtrl,
    required this.preferredDeliveryTime,
    required this.businessNameCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final buyerTypeVal = useValueListenable(buyerType);
    final preferredTimeVal = useValueListenable(preferredDeliveryTime);
    final showBusiness = buyerTypeVal == 'Hotel' ||
        buyerTypeVal == 'Restaurant' ||
        buyerTypeVal == 'Market';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
            label: 'Buyer Details',
            icon: Icons.shopping_bag_rounded,
            color: Color(0xFF2E8B57)),
        const SizedBox(height: 12),
        const _FieldLabel('Buyer Type'),
        const SizedBox(height: 6),
        _AppDropdown<String>(
          value: buyerTypeVal,
          hint: 'Select buyer type',
          items: _buyerTypes,
          labelOf: (v) => v,
          onChanged: (v) => buyerType.value = v,
          validator: (v) => v == null ? 'Buyer type is required' : null,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Default Delivery Address'),
        const SizedBox(height: 6),
        TextFormField(
          controller: deliveryAddressCtrl,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          minLines: 2,
          decoration: themedInputDec(context,
              hint: 'e.g. Darajani, Stone Town, Zanzibar'),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Delivery address is required'
              : null,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Preferred Delivery Time'),
        const SizedBox(height: 6),
        _AppDropdown<String>(
          value: preferredTimeVal,
          hint: 'Select preferred time',
          items: _deliveryTimes,
          labelOf: (v) => v,
          onChanged: (v) => preferredDeliveryTime.value = v,
          validator: (v) => v == null ? 'Please select a delivery time' : null,
        ),
        // Business name — shown only for business types
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: showBusiness
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const _FieldLabel('Business Name', optional: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: businessNameCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration:
                    themedInputDec(context, hint: 'e.g. Zanzibar Spice Hotel'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Gradient header with back button
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final LinearGradient gradient;
  const _Header({required this.onBack, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: top + 12, left: 8, right: 20, bottom: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.white, size: 20),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          const AppLogo(
            size: 40,
            withGlow: true,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: tt.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                "Join Zanzibar's fish supply network",
                style: tt.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section header with icon
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool optional;

  const _SectionHeader({
    required this.label,
    required this.icon,
    this.color,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = color ?? cs.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: c, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'optional',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Field label text
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool optional;
  const _FieldLabel(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Text(
      text,
      style: tt.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurface.withValues(alpha: 0.80),
      ),
    );
  }
}

/// Field hint text (small subtitle)
class _FieldHint extends StatelessWidget {
  final String text;
  const _FieldHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: cs.onSurface.withValues(alpha: 0.60),
      ),
    );
  }
}

/// Role selector — 2 styled cards: Street Seller, Buyer
class _RoleSelector extends StatelessWidget {
  final UserRole? selected;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  static const _roles = [
    (
      UserRole.streetSeller,
      'Street Seller',
      Icons.storefront_rounded,
      Color(0xFFE65100)
    ),
    (UserRole.buyer, 'Buyer', Icons.shopping_bag_rounded, Color(0xFF2E8B57)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: _roles.map((r) {
        final (role, label, icon, color) = r;
        final isSelected = selected == role;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: role == UserRole.buyer ? 0 : 10,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(role),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : cs.outline.withValues(alpha: 0.4),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          color: isSelected ? AppColors.white : color,
                          size: 28),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.white
                              : cs.onSurface.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Profile photo picker
class _ProfilePhotoPicker extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;
  const _ProfilePhotoPicker({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // The image is rendered with `Image.file` (not `Container +
            // DecorationImage + FileImage`) so that re-selecting a photo
            // always triggers a fresh decode instead of reusing the
            // ImageProvider's cache.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.primary, width: 2),
              ),
              child: file == null
                  ? Icon(Icons.person_rounded,
                      size: 44,
                      color: cs.onSurface.withValues(alpha: 0.35))
                  : ClipOval(
                      child: Image.file(
                        file!,
                        fit: BoxFit.cover,
                        width: 96,
                        height: 96,
                        cacheWidth: 240,
                        cacheHeight: 240,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: cs.surface, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small inline photo picker (for equipment)
class _SmallPhotoPicker extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;
  final String label;
  const _SmallPhotoPicker(
      {required this.file, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: file != null ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.4),
          ),
        ),
        // Image.file is used instead of Container+DecorationImage+FileImage
        // so re-selecting a photo always forces a fresh decode (the
        // DecorationImage variant kept showing the previous bytes).
        child: file == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded,
                      color: cs.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  file!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 80,
                  cacheWidth: 240,
                  cacheHeight: 240,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: cs.onSurface.withValues(alpha: 0.40),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Transport type picker (Bicycle / Mkokotoni / Both)
class _TransportPicker extends HookWidget {
  final ValueNotifier<String?> valueNotifier;
  final String? Function(String?)? validator;

  const _TransportPicker({
    required this.valueNotifier,
    this.validator,
  });

  static const _options = ['Bicycle', 'Mkokoteni (hand cart)', 'Both'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = useValueListenable(valueNotifier);
    const accentColor = Color(0xFFE65100);
    return fw.FormField<String>(
      initialValue: valueNotifier.value,
      validator: validator,
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._options.map((opt) {
              final selected = value == opt;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    state.didChange(opt);
                    valueNotifier.value = opt;
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? accentColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? accentColor
                            : (hasError
                                ? cs.error
                                : cs.outline.withValues(alpha: 0.4)),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? accentColor
                              : (hasError
                                  ? cs.error
                                  : cs.onSurface.withValues(alpha: 0.45)),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          opt,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: selected
                                ? accentColor
                                : cs.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: cs.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Terms & Conditions checkbox
class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? cs.primary.withValues(alpha: 0.05)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? cs.primary : cs.outline.withValues(alpha: 0.4),
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: cs.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'I agree to the ',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' of SamakiFresh Connect.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic dropdown widget
class _AppDropdown<T> extends HookWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _AppDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: themedInputDec(context, hint: hint).copyWith(hintText: null),
      hint: Text(hint,
          style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.40), fontSize: 15)),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child:
                    Text(labelOf(item), style: const TextStyle(fontSize: 15)),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: cs.onSurface.withValues(alpha: 0.55)),
    );
  }
}

/// Eye toggle button for password fields
class _EyeButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _EyeButton({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: cs.onSurface.withValues(alpha: 0.55),
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}

/// Bottom sheet for picking photo source
class _PhotoSourceSheet extends StatelessWidget {
  final String title;
  const _PhotoSourceSheet({required this.title});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: tt.titleMedium),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SourceTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                _SourceTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cs.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme-aware InputDecoration factory (matches `themedInputDec` in login)
// ─────────────────────────────────────────────────────────────────────────────
InputDecoration themedInputDec(
  BuildContext context, {
  required String hint,
  Widget? suffix,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: cs.surfaceContainerHighest,
    hintStyle: tt.bodyMedium
        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.40), fontSize: 15),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: 1.6),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Snackbar helper
// ─────────────────────────────────────────────────────────────────────────────
void _snack(BuildContext context, String msg, {bool isError = false}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: isError ? cs.error : cs.secondary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  ));
}