// Autocomplete search bar. Shows suggestions as the buyer types. Each
// suggestion routes the buyer to the map screen pre-filtered by fish
// type, and records the search in the buyer's recent-search history
// (Phase 1's `recordSearch` method on the dashboard controller).

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../providers/buyer_provider.dart';
import '../common/premium_components.dart';

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

  void _applySuggestion(String label) {
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
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suggestions =
        ref.watch(searchSuggestionsProvider(_query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Themed rounded surface for the autocomplete input. Uses
        // `cs.surface` so it tracks both Light and Dark themes and
        // gets a soft brand-tinted shadow from `PremiumCard`.
        PremiumCard(
          padding: EdgeInsets.zero,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            onChanged: _onChanged,
            onSubmitted: _onSubmit,
            textInputAction: TextInputAction.search,
            cursorColor: cs.primary,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Tafuta samaki (Changu, Tuna, Kambale...)',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 14,
                  ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              suffixIcon: _ctrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      onPressed: () {
                        _ctrl.clear();
                        _onChanged('');
                      },
                    ),
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLG),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLG),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLG),
                borderSide:
                    BorderSide(color: cs.primary, width: 1.5),
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
            // Suggestion dropdown also wrapped in `PremiumCard` for the
            // themed surface + shadow + dividers colour token.
            child: PremiumCard(
              padding: EdgeInsets.zero,
              elevated: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: BackgroundStyle.of(context).border,
                  ),
                  itemBuilder: (context, i) {
                    final s = suggestions[i];
                    return _SuggestionTile(
                      label: s.label,
                      imageUrl: s.imageUrl,
                      onTap: () =>
                          _applySuggestion(s.label),
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
    final cs = Theme.of(context).colorScheme;
    final bg = BackgroundStyle.of(context).surfaceAlt;

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
                        placeholder: (_, __) => Container(color: bg),
                        errorWidget: (_, __, ___) => Container(
                          color: bg,
                          child: Icon(
                            Icons.set_meal_rounded,
                            color: cs.onSurface.withValues(alpha: 0.45),
                            size: 18,
                          ),
                        ),
                      )
                    : Container(
                        color: bg,
                        child: Icon(
                          Icons.search_rounded,
                          color: cs.onSurface.withValues(alpha: 0.55),
                          size: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingSM),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.north_east_rounded,
              color: cs.onSurface.withValues(alpha: 0.45),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
