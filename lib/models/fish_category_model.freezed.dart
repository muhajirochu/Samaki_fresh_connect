// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fish_category_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FishCategoryModel _$FishCategoryModelFromJson(Map<String, dynamic> json) {
  return _FishCategoryModel.fromJson(json);
}

/// @nodoc
mixin _$FishCategoryModel {
  /// Stable, lowercase slug. Matches `FishType.name`. Used as the
  /// document id and as the join key against listings.
  String get slug => throw _privateConstructorUsedError;

  /// Human-readable display name shown in the listing picker and
  /// admin screens (e.g. "Tuna", "Mackerel").
  String get displayName => throw _privateConstructorUsedError;

  /// Short description shown on the admin category list.
  String? get description => throw _privateConstructorUsedError;

  /// Optional icon key — maps to an `IconData` picker. Defaults
  /// to `Icons.set_meal_rounded` when null.
  String? get iconKey => throw _privateConstructorUsedError;

  /// When false, the category is hidden from buyer / seller
  /// listing pickers but kept in the database so historical
  /// listings still render correctly. Admin can re-enable.
  bool get isActive => throw _privateConstructorUsedError;

  /// Auditor fields — never required, always optional so legacy
  /// docs without them still deserialize cleanly.
  String? get createdBy => throw _privateConstructorUsedError;
  String? get updatedBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FishCategoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FishCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FishCategoryModelCopyWith<FishCategoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FishCategoryModelCopyWith<$Res> {
  factory $FishCategoryModelCopyWith(
          FishCategoryModel value, $Res Function(FishCategoryModel) then) =
      _$FishCategoryModelCopyWithImpl<$Res, FishCategoryModel>;
  @useResult
  $Res call(
      {String slug,
      String displayName,
      String? description,
      String? iconKey,
      bool isActive,
      String? createdBy,
      String? updatedBy,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt});
}

/// @nodoc
class _$FishCategoryModelCopyWithImpl<$Res, $Val extends FishCategoryModel>
    implements $FishCategoryModelCopyWith<$Res> {
  _$FishCategoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FishCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? displayName = null,
    Object? description = freezed,
    Object? iconKey = freezed,
    Object? isActive = null,
    Object? createdBy = freezed,
    Object? updatedBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      iconKey: freezed == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedBy: freezed == updatedBy
          ? _value.updatedBy
          : updatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FishCategoryModelImplCopyWith<$Res>
    implements $FishCategoryModelCopyWith<$Res> {
  factory _$$FishCategoryModelImplCopyWith(_$FishCategoryModelImpl value,
          $Res Function(_$FishCategoryModelImpl) then) =
      __$$FishCategoryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String slug,
      String displayName,
      String? description,
      String? iconKey,
      bool isActive,
      String? createdBy,
      String? updatedBy,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt});
}

/// @nodoc
class __$$FishCategoryModelImplCopyWithImpl<$Res>
    extends _$FishCategoryModelCopyWithImpl<$Res, _$FishCategoryModelImpl>
    implements _$$FishCategoryModelImplCopyWith<$Res> {
  __$$FishCategoryModelImplCopyWithImpl(_$FishCategoryModelImpl _value,
      $Res Function(_$FishCategoryModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FishCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? displayName = null,
    Object? description = freezed,
    Object? iconKey = freezed,
    Object? isActive = null,
    Object? createdBy = freezed,
    Object? updatedBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$FishCategoryModelImpl(
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      iconKey: freezed == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedBy: freezed == updatedBy
          ? _value.updatedBy
          : updatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FishCategoryModelImpl implements _FishCategoryModel {
  const _$FishCategoryModelImpl(
      {required this.slug,
      required this.displayName,
      this.description,
      this.iconKey,
      this.isActive = true,
      this.createdBy,
      this.updatedBy,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.updatedAt});

  factory _$FishCategoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FishCategoryModelImplFromJson(json);

  /// Stable, lowercase slug. Matches `FishType.name`. Used as the
  /// document id and as the join key against listings.
  @override
  final String slug;

  /// Human-readable display name shown in the listing picker and
  /// admin screens (e.g. "Tuna", "Mackerel").
  @override
  final String displayName;

  /// Short description shown on the admin category list.
  @override
  final String? description;

  /// Optional icon key — maps to an `IconData` picker. Defaults
  /// to `Icons.set_meal_rounded` when null.
  @override
  final String? iconKey;

  /// When false, the category is hidden from buyer / seller
  /// listing pickers but kept in the database so historical
  /// listings still render correctly. Admin can re-enable.
  @override
  @JsonKey()
  final bool isActive;

  /// Auditor fields — never required, always optional so legacy
  /// docs without them still deserialize cleanly.
  @override
  final String? createdBy;
  @override
  final String? updatedBy;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'FishCategoryModel(slug: $slug, displayName: $displayName, description: $description, iconKey: $iconKey, isActive: $isActive, createdBy: $createdBy, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FishCategoryModelImpl &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, slug, displayName, description,
      iconKey, isActive, createdBy, updatedBy, createdAt, updatedAt);

  /// Create a copy of FishCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FishCategoryModelImplCopyWith<_$FishCategoryModelImpl> get copyWith =>
      __$$FishCategoryModelImplCopyWithImpl<_$FishCategoryModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FishCategoryModelImplToJson(
      this,
    );
  }
}

abstract class _FishCategoryModel implements FishCategoryModel {
  const factory _FishCategoryModel(
          {required final String slug,
          required final String displayName,
          final String? description,
          final String? iconKey,
          final bool isActive,
          final String? createdBy,
          final String? updatedBy,
          @TimestampConverter() required final DateTime createdAt,
          @TimestampConverter() required final DateTime updatedAt}) =
      _$FishCategoryModelImpl;

  factory _FishCategoryModel.fromJson(Map<String, dynamic> json) =
      _$FishCategoryModelImpl.fromJson;

  /// Stable, lowercase slug. Matches `FishType.name`. Used as the
  /// document id and as the join key against listings.
  @override
  String get slug;

  /// Human-readable display name shown in the listing picker and
  /// admin screens (e.g. "Tuna", "Mackerel").
  @override
  String get displayName;

  /// Short description shown on the admin category list.
  @override
  String? get description;

  /// Optional icon key — maps to an `IconData` picker. Defaults
  /// to `Icons.set_meal_rounded` when null.
  @override
  String? get iconKey;

  /// When false, the category is hidden from buyer / seller
  /// listing pickers but kept in the database so historical
  /// listings still render correctly. Admin can re-enable.
  @override
  bool get isActive;

  /// Auditor fields — never required, always optional so legacy
  /// docs without them still deserialize cleanly.
  @override
  String? get createdBy;
  @override
  String? get updatedBy;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;

  /// Create a copy of FishCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FishCategoryModelImplCopyWith<_$FishCategoryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
