// Street seller — Messages / Contacts.
//
// There is no in-app chat. This screen is the seller's contact list:
// every buyer who has ordered from them, with one tap to call and one
// to text. Contacts are derived from the seller's order stream rather
// than a separate collection, so the list is always exactly "people I
// have done business with" and needs no extra writes.
//
// Ordering is by most-recent order, because the buyer a seller needs
// to reach is almost always the one who just ordered.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/top_app_bar.dart';

/// A buyer the seller has transacted with, plus how often.
class SellerContact {
  final String userId;
  final String fullName;
  final String phoneNumber;
  final int orderCount;
  final DateTime lastOrderAt;

  const SellerContact({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.orderCount,
    required this.lastOrderAt,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

/// Distinct buyers from the signed-in seller's orders, resolved to user
/// profiles for the name + phone number.
///
/// `FutureProvider` rather than a stream: the order list is streamed,
/// but each buyer profile needs a one-shot fetch, and re-resolving
/// every profile on every order snapshot would hammer Firestore for
/// data that effectively never changes.
final sellerContactsProvider =
    FutureProvider.autoDispose<List<SellerContact>>((ref) async {
  final seller = ref.watch(currentUserStreamProvider).valueOrNull;
  if (seller == null) return const [];

  final orders =
      await ref.watch(streetSellerOrdersProvider(seller.userId).future);
  if (orders.isEmpty) return const [];

  // Collapse to one entry per buyer, counting orders and keeping the
  // most recent timestamp.
  final counts = <String, int>{};
  final latest = <String, DateTime>{};
  for (final o in orders) {
    if (o.buyerId.isEmpty) continue;
    counts[o.buyerId] = (counts[o.buyerId] ?? 0) + 1;
    final prev = latest[o.buyerId];
    if (prev == null || o.createdAt.isAfter(prev)) {
      latest[o.buyerId] = o.createdAt;
    }
  }

  final userService = ref.watch(userServiceProvider);
  final contacts = <SellerContact>[];
  for (final entry in counts.entries) {
    final user = await userService.fetchUserById(entry.key);
    // A deleted buyer account leaves orders behind. Skip rather than
    // render a nameless row the seller cannot act on.
    if (user == null) continue;
    contacts.add(SellerContact(
      userId: entry.key,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber,
      orderCount: entry.value,
      lastOrderAt: latest[entry.key] ?? DateTime.fromMillisecondsSinceEpoch(0),
    ));
  }

  contacts.sort((a, b) => b.lastOrderAt.compareTo(a.lastOrderAt));
  return contacts;
});

class SellerContactsScreen extends ConsumerWidget {
  const SellerContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final contactsAsync = ref.watch(sellerContactsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const TopAppBar(),
      body: SafeArea(
        top: false,
        child: contactsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => EmptyStateWidget(
            icon: Icons.error_rounded,
            title: l10n.loadingError(e.toString()),
          ),
          data: (contacts) {
            if (contacts.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.forum_outlined,
                title: l10n.contactsEmptyTitle,
                subtitle: l10n.contactsEmptySubtitle,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLG,
                AppSizes.paddingMD,
                AppSizes.paddingLG,
                AppSizes.paddingXXL,
              ),
              itemCount: contacts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSizes.paddingSM),
              itemBuilder: (context, i) => _ContactRow(contact: contacts[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final SellerContact contact;

  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasPhone = contact.phoneNumber.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingSM),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary.withValues(alpha: 0.14),
            child: Text(
              contact.initials,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPhone
                      ? l10n.contactsOrderCount(contact.orderCount)
                      : l10n.contactsNoPhone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (hasPhone) ...[
            _ActionIcon(
              icon: Icons.phone_rounded,
              color: cs.secondary,
              tooltip: l10n.contactsCall,
              onTap: () => _launch(
                context,
                scheme: 'tel',
                phone: contact.phoneNumber,
                failureMessage: l10n.contactsCallFailed,
              ),
            ),
            const SizedBox(width: AppSizes.paddingXS),
            _ActionIcon(
              icon: Icons.sms_rounded,
              color: cs.primary,
              tooltip: l10n.contactsSms,
              onTap: () => _launch(
                context,
                scheme: 'sms',
                phone: contact.phoneNumber,
                failureMessage: l10n.contactsSmsFailed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Opens the dialer / messaging app. If the platform refuses (no SIM,
  /// no handler, tablet), fall back to copying the number — the same
  /// graceful degradation `seller_profile_sheet.dart` uses, so the
  /// seller is never left with a dead button.
  Future<void> _launch(
    BuildContext context, {
    required String scheme,
    required String phone,
    required String failureMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    bool launched = false;
    try {
      launched = await launchUrl(Uri(scheme: scheme, path: phone));
    } catch (_) {
      launched = false;
    }
    if (launched || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: phone));
    messenger.showSnackBar(SnackBar(
      content: Text('$failureMessage — $phone'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
