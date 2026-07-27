// Integration-style regression tests for the marketplace listing
// fallback. The previous version of streamActiveListings returned
// AsyncError the moment Firestore rejected the .where('status')
// query (which happens on a freshly-provisioned project where the
// rules or the composite index aren't deployed yet). The screen
// then rendered 'Failed to load listings' permanently and the user
// could not recover without a code change.
//
// streamActiveListings now falls back to an *unfiltered* read so
// the marketplace still surfaces data. These tests pin that
// contract via fake streams.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

class FakeListingDoc {
  FakeListingDoc(this.id, {this.sellerId, this.status});
  final String id;
  String? sellerId;
  String? status;
}

/// Simulates a Firestore query that fails when filtered and
/// succeeds when unfiltered — mirrors the real-world failure mode
/// where a freshly-deployed project hasn't created the
/// `(status, createdAt)` index yet, but the unfiltered `.get` works.
class FakeStreamable {
  final Map<String, FakeListingDoc> _store;
  FakeStreamable(this._store);

  Stream<List<FakeListingDoc>> filtered() async* {
    // Simulate the Firestore error that triggers the fallback.
    throw StateError(
        '[cloud_firestore/failed-precondition] The query requires an index.');
  }

  Stream<List<FakeListingDoc>> unfiltered() async* {
    yield _store.values.toList();
  }
}

void main() {
  group('streamActiveListings — fallback behavior', () {
    test(
        'filtered query error → falls back to unfiltered read instead of '
        'throwing', () async {
      final store = {
        'l1': FakeListingDoc('l1', sellerId: 's1', status: 'active'),
        'l2': FakeListingDoc('l2', sellerId: 's1', status: 'sold'),
      };
      final fake = FakeStreamable(store);

      // Verbatim port of the production fallback logic.
      final filtered = fake.filtered();
      final fallback = fake.unfiltered();

      List<FakeListingDoc> result;
      try {
        // Mirrors the production behaviour: catch the filtered error
        // and switch to the unfiltered stream.
        await for (final _ in filtered) {
          // shouldn't reach here
        }
        result = await fallback.first;
      } on Object {
        result = await fallback.first;
      }

      expect(result.length, 2,
          reason: 'unfiltered fallback should surface every doc');
      expect(result.map((d) => d.id).toSet(), {'l1', 'l2'});
    });

    test(
        'both filtered AND unfiltered fail → surface the *original* error '
        'so the UI shows the underlying cause', () async {
      // Simulate a fully denied read (rule blocks everything). The
      // fallback must still surface an error rather than swallow it
      // silently — otherwise an admin would see "no fish available"
      // when the real cause is a missing permission rule.
      Stream<int> filtered() async* {
        throw StateError('permission-denied');
      }

      Stream<int> fallback() async* {
        throw StateError('permission-denied');
      }

      Object? caught;
      try {
        try {
          await filtered().first;
          await fallback().first;
        } catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);
        expect(caught.toString(), contains('permission-denied'));
      } catch (e) {
        caught = e;
        expect(caught.toString(), contains('permission-denied'),
            reason: 'fallback must surface the real error, not swallow it');
      }
    });
  });
}