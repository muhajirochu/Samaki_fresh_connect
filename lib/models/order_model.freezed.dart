// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) {
  return _OrderModel.fromJson(json);
}

/// @nodoc
mixin _$OrderModel {
  String get orderId => throw _privateConstructorUsedError;
  String get buyerId => throw _privateConstructorUsedError;
  String get streetSellerId => throw _privateConstructorUsedError;
  String get fishId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  double get totalPrice => throw _privateConstructorUsedError;
  String get pickupCode => throw _privateConstructorUsedError;
  OrderStatus get status => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get estimatedArrival => throw _privateConstructorUsedError;
  @GeoPointConverter()
  GeoPoint? get buyerLocation => throw _privateConstructorUsedError;
  @GeoPointConverter()
  GeoPoint? get streetSellerLocation => throw _privateConstructorUsedError;
  bool get isPaid => throw _privateConstructorUsedError;
  String get paymentReference => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this OrderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderModelCopyWith<OrderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderModelCopyWith<$Res> {
  factory $OrderModelCopyWith(
          OrderModel value, $Res Function(OrderModel) then) =
      _$OrderModelCopyWithImpl<$Res, OrderModel>;
  @useResult
  $Res call(
      {String orderId,
      String buyerId,
      String streetSellerId,
      String fishId,
      int quantity,
      double totalPrice,
      String pickupCode,
      OrderStatus status,
      @OptionalTimestampConverter() DateTime? estimatedArrival,
      @GeoPointConverter() GeoPoint? buyerLocation,
      @GeoPointConverter() GeoPoint? streetSellerLocation,
      bool isPaid,
      String paymentReference,
      String paymentMethod,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt});
}

/// @nodoc
class _$OrderModelCopyWithImpl<$Res, $Val extends OrderModel>
    implements $OrderModelCopyWith<$Res> {
  _$OrderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? buyerId = null,
    Object? streetSellerId = null,
    Object? fishId = null,
    Object? quantity = null,
    Object? totalPrice = null,
    Object? pickupCode = null,
    Object? status = null,
    Object? estimatedArrival = freezed,
    Object? buyerLocation = freezed,
    Object? streetSellerLocation = freezed,
    Object? isPaid = null,
    Object? paymentReference = null,
    Object? paymentMethod = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      buyerId: null == buyerId
          ? _value.buyerId
          : buyerId // ignore: cast_nullable_to_non_nullable
              as String,
      streetSellerId: null == streetSellerId
          ? _value.streetSellerId
          : streetSellerId // ignore: cast_nullable_to_non_nullable
              as String,
      fishId: null == fishId
          ? _value.fishId
          : fishId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      pickupCode: null == pickupCode
          ? _value.pickupCode
          : pickupCode // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      estimatedArrival: freezed == estimatedArrival
          ? _value.estimatedArrival
          : estimatedArrival // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      buyerLocation: freezed == buyerLocation
          ? _value.buyerLocation
          : buyerLocation // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      streetSellerLocation: freezed == streetSellerLocation
          ? _value.streetSellerLocation
          : streetSellerLocation // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      isPaid: null == isPaid
          ? _value.isPaid
          : isPaid // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentReference: null == paymentReference
          ? _value.paymentReference
          : paymentReference // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$OrderModelImplCopyWith<$Res>
    implements $OrderModelCopyWith<$Res> {
  factory _$$OrderModelImplCopyWith(
          _$OrderModelImpl value, $Res Function(_$OrderModelImpl) then) =
      __$$OrderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String orderId,
      String buyerId,
      String streetSellerId,
      String fishId,
      int quantity,
      double totalPrice,
      String pickupCode,
      OrderStatus status,
      @OptionalTimestampConverter() DateTime? estimatedArrival,
      @GeoPointConverter() GeoPoint? buyerLocation,
      @GeoPointConverter() GeoPoint? streetSellerLocation,
      bool isPaid,
      String paymentReference,
      String paymentMethod,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt});
}

/// @nodoc
class __$$OrderModelImplCopyWithImpl<$Res>
    extends _$OrderModelCopyWithImpl<$Res, _$OrderModelImpl>
    implements _$$OrderModelImplCopyWith<$Res> {
  __$$OrderModelImplCopyWithImpl(
      _$OrderModelImpl _value, $Res Function(_$OrderModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? buyerId = null,
    Object? streetSellerId = null,
    Object? fishId = null,
    Object? quantity = null,
    Object? totalPrice = null,
    Object? pickupCode = null,
    Object? status = null,
    Object? estimatedArrival = freezed,
    Object? buyerLocation = freezed,
    Object? streetSellerLocation = freezed,
    Object? isPaid = null,
    Object? paymentReference = null,
    Object? paymentMethod = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$OrderModelImpl(
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      buyerId: null == buyerId
          ? _value.buyerId
          : buyerId // ignore: cast_nullable_to_non_nullable
              as String,
      streetSellerId: null == streetSellerId
          ? _value.streetSellerId
          : streetSellerId // ignore: cast_nullable_to_non_nullable
              as String,
      fishId: null == fishId
          ? _value.fishId
          : fishId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      pickupCode: null == pickupCode
          ? _value.pickupCode
          : pickupCode // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      estimatedArrival: freezed == estimatedArrival
          ? _value.estimatedArrival
          : estimatedArrival // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      buyerLocation: freezed == buyerLocation
          ? _value.buyerLocation
          : buyerLocation // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      streetSellerLocation: freezed == streetSellerLocation
          ? _value.streetSellerLocation
          : streetSellerLocation // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      isPaid: null == isPaid
          ? _value.isPaid
          : isPaid // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentReference: null == paymentReference
          ? _value.paymentReference
          : paymentReference // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$OrderModelImpl implements _OrderModel {
  const _$OrderModelImpl(
      {this.orderId = '',
      this.buyerId = '',
      this.streetSellerId = '',
      this.fishId = '',
      this.quantity = 1,
      this.totalPrice = 0.0,
      this.pickupCode = '',
      this.status = OrderStatus.pending,
      @OptionalTimestampConverter() this.estimatedArrival,
      @GeoPointConverter() this.buyerLocation,
      @GeoPointConverter() this.streetSellerLocation,
      this.isPaid = false,
      this.paymentReference = '',
      this.paymentMethod = '',
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.updatedAt});

  factory _$OrderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderModelImplFromJson(json);

  @override
  @JsonKey()
  final String orderId;
  @override
  @JsonKey()
  final String buyerId;
  @override
  @JsonKey()
  final String streetSellerId;
  @override
  @JsonKey()
  final String fishId;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey()
  final double totalPrice;
  @override
  @JsonKey()
  final String pickupCode;
  @override
  @JsonKey()
  final OrderStatus status;
  @override
  @OptionalTimestampConverter()
  final DateTime? estimatedArrival;
  @override
  @GeoPointConverter()
  final GeoPoint? buyerLocation;
  @override
  @GeoPointConverter()
  final GeoPoint? streetSellerLocation;
  @override
  @JsonKey()
  final bool isPaid;
  @override
  @JsonKey()
  final String paymentReference;
  @override
  @JsonKey()
  final String paymentMethod;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'OrderModel(orderId: $orderId, buyerId: $buyerId, streetSellerId: $streetSellerId, fishId: $fishId, quantity: $quantity, totalPrice: $totalPrice, pickupCode: $pickupCode, status: $status, estimatedArrival: $estimatedArrival, buyerLocation: $buyerLocation, streetSellerLocation: $streetSellerLocation, isPaid: $isPaid, paymentReference: $paymentReference, paymentMethod: $paymentMethod, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderModelImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.buyerId, buyerId) || other.buyerId == buyerId) &&
            (identical(other.streetSellerId, streetSellerId) ||
                other.streetSellerId == streetSellerId) &&
            (identical(other.fishId, fishId) || other.fishId == fishId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.pickupCode, pickupCode) ||
                other.pickupCode == pickupCode) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.estimatedArrival, estimatedArrival) ||
                other.estimatedArrival == estimatedArrival) &&
            (identical(other.buyerLocation, buyerLocation) ||
                other.buyerLocation == buyerLocation) &&
            (identical(other.streetSellerLocation, streetSellerLocation) ||
                other.streetSellerLocation == streetSellerLocation) &&
            (identical(other.isPaid, isPaid) || other.isPaid == isPaid) &&
            (identical(other.paymentReference, paymentReference) ||
                other.paymentReference == paymentReference) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      orderId,
      buyerId,
      streetSellerId,
      fishId,
      quantity,
      totalPrice,
      pickupCode,
      status,
      estimatedArrival,
      buyerLocation,
      streetSellerLocation,
      isPaid,
      paymentReference,
      paymentMethod,
      createdAt,
      updatedAt);

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderModelImplCopyWith<_$OrderModelImpl> get copyWith =>
      __$$OrderModelImplCopyWithImpl<_$OrderModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderModelImplToJson(
      this,
    );
  }
}

abstract class _OrderModel implements OrderModel {
  const factory _OrderModel(
          {final String orderId,
          final String buyerId,
          final String streetSellerId,
          final String fishId,
          final int quantity,
          final double totalPrice,
          final String pickupCode,
          final OrderStatus status,
          @OptionalTimestampConverter() final DateTime? estimatedArrival,
          @GeoPointConverter() final GeoPoint? buyerLocation,
          @GeoPointConverter() final GeoPoint? streetSellerLocation,
          final bool isPaid,
          final String paymentReference,
          final String paymentMethod,
          @TimestampConverter() required final DateTime createdAt,
          @TimestampConverter() required final DateTime updatedAt}) =
      _$OrderModelImpl;

  factory _OrderModel.fromJson(Map<String, dynamic> json) =
      _$OrderModelImpl.fromJson;

  @override
  String get orderId;
  @override
  String get buyerId;
  @override
  String get streetSellerId;
  @override
  String get fishId;
  @override
  int get quantity;
  @override
  double get totalPrice;
  @override
  String get pickupCode;
  @override
  OrderStatus get status;
  @override
  @OptionalTimestampConverter()
  DateTime? get estimatedArrival;
  @override
  @GeoPointConverter()
  GeoPoint? get buyerLocation;
  @override
  @GeoPointConverter()
  GeoPoint? get streetSellerLocation;
  @override
  bool get isPaid;
  @override
  String get paymentReference;
  @override
  String get paymentMethod;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderModelImplCopyWith<_$OrderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
