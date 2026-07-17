// FishCategoryModel — admin-managed fish taxonomy.
//
// Stored in `fishCategories/{id}` collection. The document id is
// the slug (matches `FishType.name`) so the model is idempotent on
// re-seed and listings can join by `slug == fishType`.
//
// Only Admins write to this collection (enforced by Firestore
// rules). Buyers and sellers only READ the active categories for
// their listings UI.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/timestamp_converter.dart';

part 'fish_category_model.freezed.dart';
part 'fish_category_model.g.dart';

@freezed
class FishCategoryModel with _$FishCategoryModel {
  const factory FishCategoryModel({
    /// Stable, lowercase slug. Matches `FishType.name`. Used as the
    /// document id and as the join key against listings.
    required String slug,

    /// Human-readable display name shown in the listing picker and
    /// admin screens (e.g. "Tuna", "Mackerel").
    required String displayName,

    /// Short description shown on the admin category list.
    String? description,

    /// Optional icon key — maps to an `IconData` picker. Defaults
    /// to `Icons.set_meal_rounded` when null.
    String? iconKey,

    /// When false, the category is hidden from buyer / seller
    /// listing pickers but kept in the database so historical
    /// listings still render correctly. Admin can re-enable.
    @Default(true) bool isActive,

    /// Auditor fields — never required, always optional so legacy
    /// docs without them still deserialize cleanly.
    String? createdBy,
    String? updatedBy,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _FishCategoryModel;

  factory FishCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$FishCategoryModelFromJson(json);
}
