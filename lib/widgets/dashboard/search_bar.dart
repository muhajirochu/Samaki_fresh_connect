// Autocomplete search bar. Shows suggestions as the buyer types. Each
// suggestion routes the buyer to the map screen pre-filtered by fish
// type, and records the search in the buyer's recent-search history
// (Phase 1's `recordSearch` method on the dashboard controller).

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/buyer_provider.dart';

class DashboardSearchBar extends ConsumerStatefulWidget {
  const DashboardSearchBar({super.key});

  @override
  ConsumerState<DashboardSearchBar> createState() =>
      _DashboardSearchBarState();
}

class _DashboardSearchBarState extends ConsumerState<DashboardSearchBar> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _showSuggestions = _focus.hasFocus && _query.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _showSuggestions = _focus.hasFocus && value.trim().isNotEmpty;
      });
    });
  }

  void _onSubmit(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    _ctrl.text = q;
    _focus.unfocus();
    setState(() => _showSuggestions = false);
    // Record the search against this buyer's history (Phase 1 controller).
    ref
        .read(buyerDashboardControllerProvider.notifier)
        .recordSearch(q, resultCount: 0);
    // Bounce to the dedicated fish-search results screen — it shows
    // every seller with the requested fish in stock before the buyer
    // hits the map.
    context.push('/buyer/search?q=${Uri.encodeQueryComponent(q)}');
  }

  void _applySuggestion(String label, String? fishTypeValue) {
    _ctrl.text = label;
    _ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: label.length),
    );
    _focus.unfocus();
    setState(() {
      _query = label;
      _showSuggestions = false;
    });
    ref
        .read(buyerDashboardControllerProvider.notifier)
        .recordSearch(label);
    context.push(
      '/buyer/search?q=${Uri.encodeQueryComponent(label)}',
    );
    // The fishType hint is preserved implicitly via the search query
    // (the screen matches against the type enum name).
    // ignore: unused_local_variable
    final _ = fishTypeValue;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions =
        ref.watch(searchSuggestionsProvider(_query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            onChanged: _onChanged,
            onSubmitted: _onSubmit,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tafuta samaki (Changu, Tuna, Kambale...)',
              hintStyle: const TextStyle(
                color: AppColors.gray500,
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.gray500),
              suffixIcon: _ctrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.gray500),
                      onPressed: () {
                        _ctrl.clear();
                        _onChanged('');
                      },
                    ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLG),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLG),
                borderSide:
                    const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: AppSizes.paddingSM,
              ),
            ),
          ),
        ),
        if (_showSuggestions && suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.paddingXS),
            child: Material(
              color: AppColors.white,
              elevation: 6,
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusLG),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.gray100,
                  ),
                  itemBuilder: (context, i) {
                    final s = suggestions[i];
                    return _SuggestionTile(
                      label: s.label,
                      imageUrl: s.imageUrl,
                      onTap: () =>
                          _applySuggestion(s.label, s.fishTypeValue),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.label,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingSM,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
              child: SizedBox(
                width: 36,
                height: 36,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppColors.gray100),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.gray100,
                          child: const Icon(Icons.set_meal_rounded,
                              color: AppColors.gray400, size: 18),
                        ),
                      )
                    : Container(
                        color: AppColors.gray100,
                        child: const Icon(Icons.search_rounded,
                            color: AppColors.gray500, size: 18),
                      ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingSM),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.north_east_rounded,
                color: AppColors.gray400, size: 18),
          ],
        ),
      ),
    );
  }
}
