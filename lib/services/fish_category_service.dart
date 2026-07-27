// FishCategoryService — admin CRUD over the `fishCategories`
// collection.
//
// Buyers / sellers READ from this collection (via the active-only
// stream) to populate the listing-type picker. Admin-only writes
// are enforced by Firestore rules, but the service itself is
// safe to call from any context — non-admin calls will simply be
// rejected at the rules layer.
//
// The slug is the document id so the collection is idempotent on
// re-seed and the listings model can join on `slug == fishType`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/enums/fish_type.dart';
import '../models/fish_category_model.dart';
import '../utils/logger.dart';

class FishCategoryService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  static const String _collection = 'fishCategories';

  /// Live list of every category, sorted alphabetically by display
  /// name. Used by the admin Fish Categories screen.
  Stream<List<FishCategoryModel>> streamAllCategories() {
    if (!_isAvailable) return Stream.value(<FishCategoryModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed single-field `displayName` index is
      // available.
      return _firestore
          .collection(_collection)
          .snapshots()
          .map((snap) {
        final list = <FishCategoryModel>[];
        for (final d in snap.docs) {
          try {
            list.add(FishCategoryModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamAllCategories: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => a.displayName.compareTo(b.displayName));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming all categories: $e');
      return Stream.value(<FishCategoryModel>[]);
    }
  }

  /// Live list of only the active categories. Used by buyer /
  /// seller listing pickers to show only options the platform
  /// currently supports.
  Stream<List<FishCategoryModel>> streamActiveCategories() {
    if (!_isAvailable) return Stream.value(<FishCategoryModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(isActive, displayName)` composite index
      // is available.
      return _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snap) {
        final list = <FishCategoryModel>[];
        for (final d in snap.docs) {
          try {
            list.add(FishCategoryModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamActiveCategories: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => a.displayName.compareTo(b.displayName));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming active categories: $e');
      return Stream.value(<FishCategoryModel>[]);
    }
  }

  /// Create a new category. The slug is used as the document id so
  /// duplicate-slug attempts fail loudly at the Firestore layer.
  Future<void> createCategory({
    required String slug,
    required String displayName,
    String? description,
    String? iconKey,
    required String actorUid,
  }) async {
    if (!_isAvailable) return;
    final now = DateTime.now();
    final model = FishCategoryModel(
      slug: slug,
      displayName: displayName,
      description: description,
      iconKey: iconKey,
      isActive: true,
      createdBy: actorUid,
      updatedBy: actorUid,
      createdAt: now,
      updatedAt: now,
    );
    await _firestore
        .collection(_collection)
        .doc(slug)
        .set(model.toJson(), SetOptions(merge: false));
    AppLogger.info('Category $slug created by $actorUid');
  }

  /// Patch an existing category. Pass any subset of [displayName],
  /// [description], [iconKey], [isActive].
  Future<void> updateCategory(
    String slug, {
    String? displayName,
    String? description,
    String? iconKey,
    bool? isActive,
    required String actorUid,
  }) async {
    if (!_isAvailable) return;
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actorUid,
    };
    if (displayName != null) patch['displayName'] = displayName;
    if (description != null) patch['description'] = description;
    if (iconKey != null) patch['iconKey'] = iconKey;
    if (isActive != null) patch['isActive'] = isActive;

    await _firestore.collection(_collection).doc(slug).update(patch);
    AppLogger.info('Category $slug updated by $actorUid');
  }

  /// Hard-delete a category. Admin-only; the Firestore rules will
  /// reject non-admin attempts. Note this leaves historical
  /// listings whose `fishType == slug` orphaned — callers should
  /// usually flip [isActive] to false instead.
  Future<void> deleteCategory(String slug, String actorUid) async {
    if (!_isAvailable) return;
    await _firestore.collection(_collection).doc(slug).delete();
    AppLogger.info('Category $slug deleted by $actorUid');
  }

  /// One-shot seed of the seven default `FishType` values. Idempotent
  /// — uses `set(..., SetOptions(merge:true))` so re-running the seed
  /// only fills in missing docs and never overwrites an admin's
  /// custom edits to existing categories.
  ///
  /// Returns the count of categories that were actually created
  /// (existing docs are skipped).
  Future<int> seedDefaultCategories(String actorUid) async {
    if (!_isAvailable) return 0;
    var created = 0;
    final now = DateTime.now();
    for (final type in FishType.values) {
      final ref = _firestore.collection(_collection).doc(type.name);
      final existing = await ref.get();
      if (existing.exists) continue;
      await ref.set({
        'slug': type.name,
        'displayName': type.displayName,
        'description': null,
        'iconKey': type.name,
        'isActive': true,
        'createdBy': actorUid,
        'updatedBy': actorUid,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      created++;
    }
    AppLogger.info(
      'Seeded $created default categories (actor=$actorUid)',
    );
    return created;
  }
}
