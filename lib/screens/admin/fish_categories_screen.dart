// Admin — Fish Categories management.
//
// CRUD over the `fishCategories` collection. Admin-only writes
// (enforced by Firestore rules). Each card shows the slug, display
// name and active / inactive toggle. Tap the pencil to edit, the
// trash to delete (with confirm), the "+" action to create, and
// the "Seed defaults" banner to bootstrap the seven `FishType`
// values the first time the screen is opened.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/fish_type.dart';
import '../../models/fish_category_model.dart';
import '../../providers/admin_provider.dart';

class FishCategoriesScreen extends ConsumerStatefulWidget {
  const FishCategoriesScreen({super.key});

  @override
  ConsumerState<FishCategoriesScreen> createState() =>
      _FishCategoriesScreenState();
}

class _FishCategoriesScreenState extends ConsumerState<FishCategoriesScreen> {
  bool _seedPromptShown = false;

  Future<void> _openEditor(BuildContext context, {FishCategoryModel? cat}) async {
    final l10n = AppLocalizations.of(context);
    final isNew = cat == null;
    final nameCtl = TextEditingController(text: cat?.displayName ?? '');
    final slugCtl = TextEditingController(text: cat?.slug ?? '');
    final descCtl = TextEditingController(text: cat?.description ?? '');
    bool active = cat?.isActive ?? true;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.paddingLG,
              AppSizes.paddingLG,
              AppSizes.paddingLG,
              MediaQuery.of(ctx).viewInsets.bottom + AppSizes.paddingLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isNew ? l10n.newCategory : 'Edit category',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingMD),
                TextField(
                  controller: nameCtl,
                  decoration: InputDecoration(
                    labelText: l10n.categoryName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSM),
                TextField(
                  controller: slugCtl,
                  enabled: isNew,
                  decoration: InputDecoration(
                    labelText: l10n.categorySlug,
                    helperText: isNew
                        ? 'e.g. ${FishType.tuna.name}'
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSM),
                TextField(
                  controller: descCtl,
                  decoration: InputDecoration(
                    labelText: l10n.description,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMD),
                SwitchListTile(
                  value: active,
                  onChanged: (v) => setSheetState(() => active = v),
                  title: Text(l10n.categoryActive),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSizes.paddingMD),
                FilledButton.icon(
                  onPressed: () async {
                    final service =
                        ref.read(adminCategoryServiceProvider);
                    final adminUid = ref.read(adminCurrentUidProvider) ?? '';
                    try {
                      if (isNew) {
                        await service.createCategory(
                          slug: slugCtl.text.trim(),
                          displayName: nameCtl.text.trim(),
                          description: descCtl.text.trim().isEmpty
                              ? null
                              : descCtl.text.trim(),
                          iconKey: slugCtl.text.trim(),
                          actorUid: adminUid,
                        );
                      } else {
                        await service.updateCategory(
                          cat.slug,
                          displayName: nameCtl.text.trim(),
                          description: descCtl.text.trim(),
                          isActive: active,
                          actorUid: adminUid,
                        );
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorGeneric(e.toString())),
                            backgroundColor: AppColors.errorRed,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(l10n.save),
                ),
              ],
            ),
          );
        });
      },
    );
    if (ok == true) {
      ref.invalidate(adminAllCategoriesProvider);
      ref.invalidate(adminActiveCategoriesProvider);
    }
  }

  Future<void> _confirmDelete(BuildContext context, FishCategoryModel cat) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteListing),
        content: Text('Permanently delete "${cat.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final service = ref.read(adminCategoryServiceProvider);
    final adminUid = ref.read(adminCurrentUidProvider) ?? '';
    try {
      await service.deleteCategory(cat.slug, adminUid);
      ref.invalidate(adminAllCategoriesProvider);
      ref.invalidate(adminActiveCategoriesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catsAsync = ref.watch(adminAllCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCategories),
        actions: [
          IconButton(
            tooltip: l10n.newCategory,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openEditor(context),
          ),
        ],
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.loadingError(e.toString()))),
        data: (cats) {
          if (cats.isEmpty && !_seedPromptShown) {
            _seedPromptShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.seedDefaults),
                  content: Text(l10n.seedDefaultsHint),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.seedDefaults),
                    ),
                  ],
                ),
              );
              if (ok == true && mounted) {
                final service =
                    ref.read(adminCategoryServiceProvider);
                final adminUid = ref.read(adminCurrentUidProvider) ?? '';
                await service.seedDefaultCategories(adminUid);
                ref.invalidate(adminAllCategoriesProvider);
              }
            });
          }
          if (cats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_rounded,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: AppSizes.paddingMD),
                    Text(l10n.noListingsFound),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            itemCount: cats.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.paddingMD),
            itemBuilder: (_, i) =>
                _CategoryCard(category: cats[i], onEdit: () {
              _openEditor(context, cat: cats[i]);
            }, onDelete: () {
              _confirmDelete(context, cats[i]);
            }, key: ValueKey(cats[i].slug)),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final FishCategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: category.isActive
              ? cs.outline.withValues(alpha: 0.25)
              : AppColors.errorRed.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.set_meal_rounded, color: cs.primary),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.displayName,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                Text(category.slug,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    )),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (category.isActive
                            ? AppColors.accentGreen
                            : AppColors.errorRed)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.isActive
                        ? l10n.categoryActive
                        : l10n.categoryInactive,
                    style: TextStyle(
                      color: category.isActive
                          ? AppColors.accentGreen
                          : AppColors.errorRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            onPressed: onEdit,
            tooltip: l10n.edit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.errorRed,
              size: 18,
            ),
            onPressed: onDelete,
            tooltip: l10n.delete,
          ),
        ],
      ),
    );
  }
}
