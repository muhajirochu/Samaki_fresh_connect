// Admin — Activity Logs.
//
// Live list of every `activityLogs/{id}` doc. Filter chips at the
// top let the admin slice by type (logins / registrations /
// admin actions / disputes / listings). Tap a row to open a
// bottom sheet with the full metadata payload.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';

class AdminActivityLogsScreen extends ConsumerWidget {
  const AdminActivityLogsScreen({super.key});

  static const _allTypes = 'all';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.logsTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.statusAll),
              Tab(text: l10n.loginEvents),
              Tab(text: l10n.registrationEvents),
              Tab(text: l10n.adminActions),
              Tab(text: l10n.disputeEvents),
              Tab(text: l10n.listingEvents),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LogList(typeFilter: _allTypes),
            _LogList(typeFilter: 'login'),
            _LogList(typeFilter: 'registration'),
            _LogList(typeFilter: 'adminAction'),
            _LogList(typeFilter: 'disputeResolution'),
            _LogList(typeFilter: 'listingModeration'),
          ],
        ),
      ),
    );
  }
}

class _LogList extends ConsumerWidget {
  final String typeFilter;
  const _LogList({required this.typeFilter});

  IconData _iconFor(String type) {
    switch (type) {
      case 'login':
        return Icons.login_rounded;
      case 'registration':
        return Icons.person_add_rounded;
      case 'adminAction':
        return Icons.build_rounded;
      case 'disputeResolution':
        return Icons.gavel_rounded;
      case 'listingModeration':
        return Icons.inventory_rounded;
      case 'categoryChange':
        return Icons.category_rounded;
      case 'orderStatus':
        return Icons.receipt_long_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _colorFor(String type, ColorScheme cs) {
    switch (type) {
      case 'login':
        return cs.primary;
      case 'registration':
        return cs.secondary;
      case 'adminAction':
        return cs.tertiary;
      case 'disputeResolution':
        return cs.error;
      case 'listingModeration':
        return cs.tertiary;
      case 'categoryChange':
        return cs.primary;
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stream =
        typeFilter == AdminActivityLogsScreen._allTypes
            ? ref.watch(adminRecentActivityProvider)
            : ref.watch(adminRecentActivityProvider); // All-types uses the same wide stream, client filter applied below.

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(l10n.loadingError(e.toString()))),
      data: (logs) {
        final filtered = typeFilter == AdminActivityLogsScreen._allTypes
            ? logs
            : logs.where((l) => l.type == typeFilter).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingXL),
              child: Text(l10n.noLogsYet),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.paddingSM),
          itemBuilder: (_, i) {
            final log = filtered[i];
            final color = _colorFor(log.type, Theme.of(context).colorScheme);
            return Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                border: Border.all(
                  color: color.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconFor(log.type), color: color, size: 20),
                  ),
                  const SizedBox(width: AppSizes.paddingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (log.subtitle != null)
                          Text(
                            log.subtitle!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.65),
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _relativeTime(log.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
