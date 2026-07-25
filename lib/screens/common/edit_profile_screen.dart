import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final cs = Theme.of(context).colorScheme;

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: user?.fullName);
    final phoneController = useTextEditingController(text: user?.phoneNumber);

    final initialLocation = useMemoized(() {
      final loc = user?.location;
      if (loc != null && loc['latitude'] != null && loc['longitude'] != null) {
        return '${loc['latitude']}, ${loc['longitude']}';
      }
      return '';
    }, [user?.location]);

    final locationController = useTextEditingController(text: initialLocation);
    final isLoading = useState(false);

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.notLoggedInSimple)));
    }

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      try {
        Map<String, dynamic>? parsedLocation;
        final locText = locationController.text.trim();
        if (locText.isNotEmpty) {
          final parts = locText.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lon = double.tryParse(parts[1].trim());
            if (lat != null && lon != null) {
              parsedLocation = {'latitude': lat, 'longitude': lon};
            }
          }
        }

        final userService = ref.read(userServiceProvider);
        await userService.updateUserProfile(user.userId, {
          'fullName': nameController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
          'location': parsedLocation,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileUpdatedSuccess),
              backgroundColor: AppColors.successGreen,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorWithMessage(e.toString())),
              backgroundColor: AppColors.errorRed),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.editProfile,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar edit section
              Center(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'profile_avatar',
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            cs.primary.withValues(alpha: 0.10),
                        backgroundImage: user.profilePictureUrl != null
                            ? NetworkImage(user.profilePictureUrl!)
                            : null,
                        child: user.profilePictureUrl == null
                            ? Icon(Icons.person_rounded,
                                size: 50, color: cs.primary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt_rounded,
                            color: cs.onPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingXXL),

              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingLG),

              CustomTextField(
                label: 'Full Name',
                controller: nameController,
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSizes.paddingLG),

              CustomTextField(
                label: 'Phone Number',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSizes.paddingLG),

              CustomTextField(
                label: 'Location (Lat, Lng)',
                controller: locationController,
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: AppSizes.paddingXXL),

              CustomButton(
                label: 'Save Changes',
                isLoading: isLoading.value,
                onPressed: save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
