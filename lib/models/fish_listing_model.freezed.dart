// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fish_listing_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FishListingModel _$FishListingModelFromJson(Map<String, dynamic> json) {
  return _FishListingModel.fromJson(json);
}

/// @nodoc
mixin _$FishListingModel {
  String get listingId => throw _privateConstructorUsedError;
  String get sellerId => throw _privateConstructorUsedError;
  String get fishType => throw _privateConstructorUsedError;
  double get quantityKg => throw _privateConstructorUsedError;
  double get pricePerKg => throw _privateConstructorUsedError;
  double get totalPrice => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;
  Map<String, dynamic>? get location => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get expiresAt => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get soldAt => throw _privateConstructorUsedError;

  /// Serializes this FishListingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FishListingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FishListingModelCopyWith<FishListingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FishListingModelCopyWith<$Res> {
  factory $FishListingModelCopyWith(
          FishListingModel value, $Res Function(FishListingModel) then) =
      _$FishListingModelCopyWithImpl<$Res, FishListingModel>;
  @useResult
  $Res call(
      {String listingId,
      String sellerId,
      String fishType,
      double quantityKg,
      double pricePerKg,
      double totalPrice,
      List<String> imageUrls,
      Map<String, dynamic>? location,
      String status,
      String? description,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime expiresAt,
      @OptionalTimestampConverter() DateTime? soldAt});
}

/// @nodoc
class _$FishListingModelCopyWithImpl<$Res, $Val extends FishListingModel>
    implements $FishListingModelCopyWith<$Res> {
  _$FishListingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FishListingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? listingId = null,
    Object? sellerId = null,
    Object? fishType = null,
    Object? quantityKg = null,
    Object? pricePerKg = null,
    Object? totalPrice = null,
    Object? imageUrls = null,
    Object? location = freezed,
    Object? status = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? soldAt = freezed,
  }) {
    return _then(_value.copyWith(
      listingId: null == listingId
          ? _value.listingId
          : listingId // ignore: cast_nullable_to_non_nullable
              as String,
      sellerId: null == sellerId
          ? _value.sellerId
          : sellerId // ignore: cast_nullable_to_non_nullable
              as String,
      fishType: null == fishType
          ? _value.fishType
          : fishType // ignore: cast_nullable_to_non_nullable
              as String,
      quantityKg: null == quantityKg
          ? _value.quantityKg
          : quantityKg // ignore: cast_nullable_to_non_nullable
              as double,
      pricePerKg: null == pricePerKg
          ? _value.pricePerKg
          : pricePerKg // ignore: cast_nullable_to_non_nullable
              as double,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      imageUrls: null == imageUrls
          ? _value.imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      soldAt: freezed == soldAt
          ? _value.soldAt
          : soldAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FishListingModelImplCopyWith<$Res>
    implements $FishListingModelCopyWith<$Res> {
  factory _$$FishListingModelImplCopyWith(_$FishListingModelImpl value,
          $Res Function(_$FishListingModelImpl) then) =
      __$$FishListingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String listingId,
      String sellerId,
      String fishType,
      double quantityKg,
      double pricePerKg,
      double totalPrice,
      List<String> imageUrls,
      Map<String, dynamic>? location,
      String status,
      String? description,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime expiresAt,
      @OptionalTimestampConverter() DateTime? soldAt});
}

/// @nodoc
class __$$FishListingModelImplCopyWithImpl<$Res>
    extends _$FishListingModelCopyWithImpl<$Res, _$FishListingModelImpl>
    implements _$$FishListingModelImplCopyWith<$Res> {
  __$$FishListingModelImplCopyWithImpl(_$FishListingModelImpl _value,
      $Res Function(_$FishListingModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FishListingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? listingId = null,
    Object? sellerId = null,
    Object? fishType = null,
    Object? quantityKg = null,
    Object? pricePerKg = null,
    Object? totalPrice = null,
    Object? imageUrls = null,
    Object? location = freezed,
    Object? status = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? soldAt = freezed,
  }) {
    return _then(_$FishListingModelImpl(
      listingId: null == listingId
          ? _value.listingId
          : listingId // ignore: cast_nullable_to_non_nullable
              as String,
      sellerId: null == sellerId
          ? _value.sellerId
          : sellerId // ignore: cast_nullable_to_non_nullable
              as String,
      fishType: null == fishType
          ? _value.fishType
          : fishType // ignore: cast_nullable_to_non_nullable
              as String,
      quantityKg: null == quantityKg
          ? _value.quantityKg
          : quantityKg // ignore: cast_nullable_to_non_nullable
              as double,
      pricePerKg: null == pricePerKg
          ? _value.pricePerKg
          : pricePerKg // ignore: cast_nullable_to_non_nullable
              as double,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      imageUrls: null == imageUrls
          ? _value._imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      location: freezed == location
          ? _value._location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      soldAt: freezed == soldAt
          ? _value.soldAt
          : soldAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FishListingModelImpl implements _FishListingModel {
  const _$FishListingModelImpl(
      {required this.listingId,
      required this.sellerId,
      required this.fishType,
      required this.quantityKg,
      required this.pricePerKg,
      required this.totalPrice,
      required final List<String> imageUrls,
      final Map<String, dynamic>? location,
      required this.status,
      this.description,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.expiresAt,
      @OptionalTimestampConverter() this.soldAt})
      : _imageUrls = imageUrls,
        _location = location;

  factory _$FishListingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FishListingModelImplFromJson(json);

  @override
  final String listingId;
  @override
  final String sellerId;
  @override
  final String fishType;
  @override
  final double quantityKg;
  @override
  final double pricePerKg;
  @override
  final double totalPrice;
  final List<String> _imageUrls;
  @override
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  final Map<String, dynamic>? _location;
  @override
  Map<String, dynamic>? get location {
    final value = _location;
    if (value == null) return null;
    if (_location is EqualUnmodifiableMapView) return _location;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String status;
  @override
  final String? description;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime expiresAt;
  @override
  @OptionalTimestampConverter()
  final DateTime? soldAt;

  @override
  String toString() {
    return 'FishListingModel(listingId: $listingId, sellerId: $sellerId, fishType: $fishType, quantityKg: $quantityKg, pricePerKg: $pricePerKg, totalPrice: $totalPrice, imageUrls: $imageUrls, location: $location, status: $status, description: $description, createdAt: $createdAt, expiresAt: $expiresAt, soldAt: $soldAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FishListingModelImpl &&
            (identical(other.listingId, listingId) ||
                other.listingId == listingId) &&
            (identical(other.sellerId, sellerId) ||
                other.sellerId == sellerId) &&
            (identical(other.fishType, fishType) ||
                other.fishType == fishType) &&
            (identical(other.quantityKg, quantityKg) ||
                other.quantityKg == quantityKg) &&
            (identical(other.pricePerKg, pricePerKg) ||
                other.pricePerKg == pricePerKg) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            const DeepCollectionEquality()
                .equals(other._imageUrls, _imageUrls) &&
            const DeepCollectionEquality().equals(other._location, _location) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.soldAt, soldAt) || other.soldAt == soldAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      listingId,
      sellerId,
      fishType,
      quantityKg,
      pricePerKg,
      totalPrice,
      const DeepCollectionEquality().hash(_imageUrls),
      const DeepCollectionEquality().hash(_location),
      status,
      description,
      createdAt,
      expiresAt,
      soldAt);

  /// Create a copy of FishListingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FishListingModelImplCopyWith<_$FishListingModelImpl> get copyWith =>
      __$$FishListingModelImplCopyWithImpl<_$FishListingModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FishListingModelImplToJson(
      this,
    );
  }
}

abstract class _FishListingModel implements FishListingModel {
  const factory _FishListingModel(
          {required final String listingId,
          required final String sellerId,
          required final String fishType,
          required final double quantityKg,
          required final double pricePerKg,
          required final double totalPrice,
          required final List<String> imageUrls,
          final Map<String, dynamic>? location,
          required final String status,
          final String? description,
          @TimestampConverter() required final DateTime createdAt,
          @TimestampConverter() required final DateTime expiresAt,
          @OptionalTimestampConverter() final DateTime? soldAt}) =
      _$FishListingModelImpl;

  factory _FishListingModel.fromJson(Map<String, dynamic> json) =
      _$FishListingModelImpl.fromJson;

  @override
  String get listingId;
  @override
  String get sellerId;
  @override
  String get fishType;
  @override
  double get quantityKg;
  @override
  double get pricePerKg;
  @override
  double get totalPrice;
  @override
  List<String> get imageUrls;
  @override
  Map<String, dynamic>? get location;
  @override
  String get status;
  @override
  String? get description;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get expiresAt;
  @override
  @OptionalTimestampConverter()
  DateTime? get soldAt;

  /// Create a copy of FishListingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FishListingModelImplCopyWith<_$FishListingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
