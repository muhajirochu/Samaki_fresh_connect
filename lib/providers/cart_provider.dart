// Shopping-cart providers.
//
// ── Session isolation ────────────────────────────────────────────────────────
// Gated on `currentBuyerSessionProvider`, exactly like the wishlist
// providers in `notification_provider.dart`. When the auth user is null
// or is not a buyer, the cart stream is empty — so a seller signing in
// on the same device never sees a buyer's cart.

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/cart_model.dart';
import '../services/cart_service.dart';
import 'buyer_provider.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());

/// Live cart contents for the signed-in buyer, newest item first.
final cartProvider = StreamProvider<List<CartItem>>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return Stream.value(const []);
  final svc = ref.watch(cartServiceProvider);
  return svc.streamFor(session.buyerId);
});

/// Number of distinct listings in the cart — drives the nav-bar badge.
/// Distinct rows rather than summed kg, because a "3" badge over a
/// basket icon reads as "3 things", not "3 kilograms".
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).valueOrNull?.length ?? 0;
});

/// Sum of every line total, using each item's snapshotted price.
/// The checkout flow re-reads live listings before ordering, so this is
/// an estimate for display — not the figure the order is written with.
final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider).valueOrNull ?? const <CartItem>[];
  return items.fold<double>(0, (acc, i) => acc + i.lineTotal);
});

/// Mutations. Held as a plain object (not a Notifier) because the
/// source of truth is the Firestore stream — these methods write, and
/// `cartProvider` re-emits on its own.
class CartActions {
  final Ref _ref;
  const CartActions(this._ref);

  String? get _buyerId => _ref.read(currentBuyerSessionProvider)?.buyerId;

  Future<void> add(CartItem item) async {
    final id = _buyerId;
    if (id == null) return;
    await _ref.read(cartServiceProvider).add(id, item);
  }

  Future<void> updateQuantity(String listingId, double quantityKg) async {
    final id = _buyerId;
    if (id == null) return;
    await _ref
        .read(cartServiceProvider)
        .updateQuantity(id, listingId, quantityKg);
  }

  Future<void> remove(String listingId) async {
    final id = _buyerId;
    if (id == null) return;
    await _ref.read(cartServiceProvider).remove(id, listingId);
  }

  Future<void> removeMany(List<String> listingIds) async {
    final id = _buyerId;
    if (id == null) return;
    await _ref.read(cartServiceProvider).removeMany(id, listingIds);
  }

  Future<void> clear() async {
    final id = _buyerId;
    if (id == null) return;
    await _ref.read(cartServiceProvider).clear(id);
  }
}

final cartActionsProvider = Provider<CartActions>((ref) => CartActions(ref));
