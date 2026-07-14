import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/settings/theme_switcher_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header Section ───────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.paddingXXL),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.2),
                                width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.1),
                            backgroundImage: user.profilePictureUrl != null
                                ? NetworkImage(user.profilePictureUrl!)
                                : null,
                            child: user.profilePictureUrl == null
                                ? const Icon(Icons.person_rounded,
                                    size: 56, color: AppColors.primaryBlue)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLG),
                      Text(
                        user.fullName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppColors.secondaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: const TextStyle(
                            color: AppColors.secondaryTeal,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLG),

                // ── Appearance Section ───────────────────────────────────────
                // Theme switcher (White / Cream / Dark) — sits above the
                // account info so the user can quickly switch look and
                // feel without scrolling to the very bottom.
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray600,
                                ),
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      const ThemeSwitcherTile(),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLG),

                // ── Info Section ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray600,
                                ),
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLG),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Column(
                          children: [
                            _ProfileInfoTile(
                              icon: Icons.email_rounded,
                              title: 'Email',
                              subtitle: user.email,
                              showDivider: true,
                            ),
                            _ProfileInfoTile(
                              icon: Icons.phone_rounded,
                              title: 'Phone Number',
                              subtitle: user.phoneNumber,
                              showDivider: true,
                            ),
                            _ProfileInfoTile(
                              icon: Icons.location_on_rounded,
                              title: 'Location',
                              subtitle: (user.location != null &&
                                      user.location!['latitude'] != null &&
                                      user.location!['longitude'] != null)
                                  ? '${user.location!['latitude']}, ${user.location!['longitude']}'
                                  : 'Not specified',
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Logout Button
                      CustomButton(
                        label: 'Log Out',
                        prefixIcon: Icons.logout_rounded,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.errorRed,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.errorRed),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLG),
                          ),
                        ),
                        onPressed: () async {
                          mockUser = null;
                          ref.invalidate(authStateProvider);
                          ref.invalidate(currentUserProvider);
                          ref.invalidate(currentUserStreamProvider);
                          ref.invalidate(currentUserDataProvider);
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingXXL),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showDivider;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: AppSizes.paddingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
              height: 1, indent: 70, endIndent: 20, color: AppColors.gray200),
      ],
    );
  }
}
