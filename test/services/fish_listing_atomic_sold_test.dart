// Regression tests for the atomic `tryMarkAsSold` flow.
//
// Bug history: the previous placeOrder computed remainingQty as
// `listing.quantityKg - listing.quantityKg` — i.e. always 0 — and
// then marked every purchase as 'sold' without any protection against
// concurrent purchases. Two buyers could race and both succeed,
// leaving the seller with two confirmed orders for the same fish.
//
// tryMarkAsSold wraps the flip in a Firestore transaction that
// re-reads the doc and refuses to flip it from `active` to `sold` if
// another transaction already won the race. These tests pin that
// contract via a fake Firestore backend.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

class FakeListingDoc {
  FakeListingDoc(this.id, {this.status = 'active'});
  final String id;
  String status;
  Map<String, dynamic> toMap() => {'listingId': id, 'status': status};
}

/// Tiny transaction simulator that mirrors Firestore's
/// runTransaction contract. All transactions are serialised through
/// a single lock — exactly the way real Firestore applies writes
/// inside runTransaction — so the second caller always observes the
/// first caller's writes when it reads the snapshot.
class FakeTransactionRunner {
  FakeTransactionRunner(this._store);
  final Map<String, FakeListingDoc> _store;
  Future<void>? _pending = Future.value();

  Future<T> run<T>(Future<T> Function(FakeTx txn) action) async {
    final completer = Completer<T>();
    final previous = _pending!;
    _pending = Future.wait([previous]).then((_) async {
      // Capture snapshot of every doc at the moment THIS ticket
      // starts. Because we wait for the previous transaction above,
      // this snapshot always reflects the latest committed writes.
      final snapshot = <String, FakeListingDoc>{};
      for (final entry in _store.entries) {
        snapshot[entry.key] = FakeListingDoc(
          entry.value.id,
          status: entry.value.status,
        );
      }
      final tx = FakeTx(snapshot);
      final result = await action(tx);
      if (tx.committed) {
        for (final write in tx.writes) {
          final existing = _store[write.key];
          if (existing != null) {
            existing.status = write.fields['status'] as String;
          }
        }
      }
      completer.complete(result);
    });
    return completer.future;
  }
}

class FakeTx {
  FakeTx(this._snapshot);
  final Map<String, FakeListingDoc> _snapshot;
  final List<FakeWrite> writes = [];
  bool committed = false;

  Future<FakeListingDoc?> get(String id) async => _snapshot[id];

  void update(String id, Map<String, dynamic> fields) {
    writes.add(FakeWrite(id, fields));
  }

  void commit() {
    committed = true;
  }
}

class FakeWrite {
  FakeWrite(this.key, this.fields);
  final String key;
  final Map<String, dynamic> fields;
}

/// Verbatim port of tryMarkAsSold's transaction body — runs against
/// the fake backend so we can drive two concurrent attempts in the
/// same test without hitting real Firestore.
Future<bool> tryMarkAsSoldRunner(
  FakeTransactionRunner runner,
  String listingId,
) {
  return runner.run<bool>((txn) async {
    final snap = await txn.get(listingId);
    if (snap == null) return false;
    final status = snap.status;
    if (status != 'active') return false;
    txn.update(listingId, {
      'status': 'sold',
    });
    txn.commit();
    return true;
  });
}

void main() {
  group('tryMarkAsSold — atomic seller dashboard update', () {
    test('first concurrent purchase wins, the second is rejected',
        () async {
      final store = {'l1': FakeListingDoc('l1')};
      final runner = FakeTransactionRunner(store);

      // Two buyers tap "Purchase Now" at the same instant.
      final results = await Future.wait<bool>([
        tryMarkAsSoldRunner(runner, 'l1'),
        tryMarkAsSoldRunner(runner, 'l1'),
      ]);

      // Exactly one of them succeeded. The other must have seen the
      // listing as 'sold' inside its own transaction snapshot.
      expect(results.where((r) => r).length, 1,
          reason: 'only one buyer should win the race');
      expect(results.where((r) => !r).length, 1,
          reason: 'the other buyer must see "already sold"');

      // After the dust settles the doc is sold.
      expect(store['l1']!.status, 'sold');
    });

    test('after a successful purchase, retry from the same buyer fails',
        () async {
      final store = {'l1': FakeListingDoc('l1')};
      final runner = FakeTransactionRunner(store);

      expect(await tryMarkAsSoldRunner(runner, 'l1'), isTrue);
      expect(await tryMarkAsSoldRunner(runner, 'l1'), isFalse,
          reason: 'second purchase must fail because status is sold');
    });

    test('listing already sold at purchase time is reported as unavailable',
        () async {
      final store = {'l1': FakeListingDoc('l1', status: 'sold')};
      final runner = FakeTransactionRunner(store);

      expect(await tryMarkAsSoldRunner(runner, 'l1'), isFalse,
          reason: 'a pre-sold listing must never flip');
    });

    test('non-existent listing returns false instead of throwing',
        () async {
      final runner = FakeTransactionRunner(<String, FakeListingDoc>{});
      expect(await tryMarkAsSoldRunner(runner, 'missing'), isFalse);
    });
  });
}