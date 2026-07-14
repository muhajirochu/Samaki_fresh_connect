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
  String get orderPath => throw _privateConstructorUsedError;
  String get buyerId => throw _privateConstructorUsedError;
  String? get streetSellerId => throw _privateConstructorUsedError;
  String get listingId => throw _privateConstructorUsedError;
  double get originalPrice => throw _privateConstructorUsedError;
  double? get negotiatedPrice => throw _privateConstructorUsedError;
  double get finalPrice => throw _privateConstructorUsedError;
  double get quantityKg => throw _privateConstructorUsedError;
  String get orderStatus => throw _privateConstructorUsedError;
  String? get negotiationStatus => throw _privateConstructorUsedError;
  bool get pickupConfirmed => throw _privateConstructorUsedError;
  bool get deliveryConfirmed => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get completedAt => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get cancelledAt => throw _privateConstructorUsedError;

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
      String orderPath,
      String buyerId,
      String? streetSellerId,
      String listingId,
      double originalPrice,
      double? negotiatedPrice,
      double finalPrice,
      double quantityKg,
      String orderStatus,
      String? negotiationStatus,
      bool pickupConfirmed,
      bool deliveryConfirmed,
      @TimestampConverter() DateTime createdAt,
      @OptionalTimestampConverter() DateTime? completedAt,
      @OptionalTimestampConverter() DateTime? cancelledAt});
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
    Object? orderPath = null,
    Object? buyerId = null,
    Object? streetSellerId = freezed,
    Object? listingId = null,
    Object? originalPrice = null,
    Object? negotiatedPrice = freezed,
    Object? finalPrice = null,
    Object? quantityKg = null,
    Object? orderStatus = null,
    Object? negotiationStatus = freezed,
    Object? pickupConfirmed = null,
    Object? deliveryConfirmed = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? cancelledAt = freezed,
  }) {
    return _then(_value.copyWith(
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderPath: null == orderPath
          ? _value.orderPath
          : orderPath // ignore: cast_nullable_to_non_nullable
              as String,
      buyerId: null == buyerId
          ? _value.buyerId
          : buyerId // ignore: cast_nullable_to_non_nullable
              as String,
      streetSellerId: freezed == streetSellerId
          ? _value.streetSellerId
          : streetSellerId // ignore: cast_nullable_to_non_nullable
              as String?,
      listingId: null == listingId
          ? _value.listingId
          : listingId // ignore: cast_nullable_to_non_nullable
              as String,
      originalPrice: null == originalPrice
          ? _value.originalPrice
          : originalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      negotiatedPrice: freezed == negotiatedPrice
          ? _value.negotiatedPrice
          : negotiatedPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      finalPrice: null == finalPrice
          ? _value.finalPrice
          : finalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      quantityKg: null == quantityKg
          ? _value.quantityKg
          : quantityKg // ignore: cast_nullable_to_non_nullable
              as double,
      orderStatus: null == orderStatus
          ? _value.orderStatus
          : orderStatus // ignore: cast_nullable_to_non_nullable
              as String,
      negotiationStatus: freezed == negotiationStatus
          ? _value.negotiationStatus
          : negotiationStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      pickupConfirmed: null == pickupConfirmed
          ? _value.pickupConfirmed
          : pickupConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryConfirmed: null == deliveryConfirmed
          ? _value.deliveryConfirmed
          : deliveryConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
      String orderPath,
      String buyerId,
      String? streetSellerId,
      String listingId,
      double originalPrice,
      double? negotiatedPrice,
      double finalPrice,
      double quantityKg,
      String orderStatus,
      String? negotiationStatus,
      bool pickupConfirmed,
      bool deliveryConfirmed,
      @TimestampConverter() DateTime createdAt,
      @OptionalTimestampConverter() DateTime? completedAt,
      @OptionalTimestampConverter() DateTime? cancelledAt});
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
    Object? orderPath = null,
    Object? buyerId = null,
    Object? streetSellerId = freezed,
    Object? listingId = null,
    Object? originalPrice = null,
    Object? negotiatedPrice = freezed,
    Object? finalPrice = null,
    Object? quantityKg = null,
    Object? orderStatus = null,
    Object? negotiationStatus = freezed,
    Object? pickupConfirmed = null,
    Object? deliveryConfirmed = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? cancelledAt = freezed,
  }) {
    return _then(_$OrderModelImpl(
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderPath: null == orderPath
          ? _value.orderPath
          : orderPath // ignore: cast_nullable_to_non_nullable
              as String,
      buyerId: null == buyerId
          ? _value.buyerId
          : buyerId // ignore: cast_nullable_to_non_nullable
              as String,
      streetSellerId: freezed == streetSellerId
          ? _value.streetSellerId
          : streetSellerId // ignore: cast_nullable_to_non_nullable
              as String?,
      listingId: null == listingId
          ? _value.listingId
          : listingId // ignore: cast_nullable_to_non_nullable
              as String,
      originalPrice: null == originalPrice
          ? _value.originalPrice
          : originalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      negotiatedPrice: freezed == negotiatedPrice
          ? _value.negotiatedPrice
          : negotiatedPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      finalPrice: null == finalPrice
          ? _value.finalPrice
          : finalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      quantityKg: null == quantityKg
          ? _value.quantityKg
          : quantityKg // ignore: cast_nullable_to_non_nullable
              as double,
      orderStatus: null == orderStatus
          ? _value.orderStatus
          : orderStatus // ignore: cast_nullable_to_non_nullable
              as String,
      negotiationStatus: freezed == negotiationStatus
          ? _value.negotiationStatus
          : negotiationStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      pickupConfirmed: null == pickupConfirmed
          ? _value.pickupConfirmed
          : pickupConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryConfirmed: null == deliveryConfirmed
          ? _value.deliveryConfirmed
          : deliveryConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderModelImpl implements _OrderModel {
  const _$OrderModelImpl(
      {required this.orderId,
      required this.orderPath,
      required this.buyerId,
      this.streetSellerId,
      required this.listingId,
      required this.originalPrice,
      this.negotiatedPrice,
      required this.finalPrice,
      required this.quantityKg,
      required this.orderStatus,
      this.negotiationStatus,
      required this.pickupConfirmed,
      required this.deliveryConfirmed,
      @TimestampConverter() required this.createdAt,
      @OptionalTimestampConverter() this.completedAt,
      @OptionalTimestampConverter() this.cancelledAt});

  factory _$OrderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderModelImplFromJson(json);

  @override
  final String orderId;
  @override
  final String orderPath;
  @override
  final String buyerId;
  @override
  final String? streetSellerId;
  @override
  final String listingId;
  @override
  final double originalPrice;
  @override
  final double? negotiatedPrice;
  @override
  final double finalPrice;
  @override
  final double quantityKg;
  @override
  final String orderStatus;
  @override
  final String? negotiationStatus;
  @override
  final bool pickupConfirmed;
  @override
  final bool deliveryConfirmed;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @OptionalTimestampConverter()
  final DateTime? completedAt;
  @override
  @OptionalTimestampConverter()
  final DateTime? cancelledAt;

  @override
  String toString() {
    return 'OrderModel(orderId: $orderId, orderPath: $orderPath, buyerId: $buyerId, streetSellerId: $streetSellerId, listingId: $listingId, originalPrice: $originalPrice, negotiatedPrice: $negotiatedPrice, finalPrice: $finalPrice, quantityKg: $quantityKg, orderStatus: $orderStatus, negotiationStatus: $negotiationStatus, pickupConfirmed: $pickupConfirmed, deliveryConfirmed: $deliveryConfirmed, createdAt: $createdAt, completedAt: $completedAt, cancelledAt: $cancelledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderModelImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.orderPath, orderPath) ||
                other.orderPath == orderPath) &&
            (identical(other.buyerId, buyerId) || other.buyerId == buyerId) &&
            (identical(other.streetSellerId, streetSellerId) ||
                other.streetSellerId == streetSellerId) &&
            (identical(other.listingId, listingId) ||
                other.listingId == listingId) &&
            (identical(other.originalPrice, originalPrice) ||
                other.originalPrice == originalPrice) &&
            (identical(other.negotiatedPrice, negotiatedPrice) ||
                other.negotiatedPrice == negotiatedPrice) &&
            (identical(other.finalPrice, finalPrice) ||
                other.finalPrice == finalPrice) &&
            (identical(other.quantityKg, quantityKg) ||
                other.quantityKg == quantityKg) &&
            (identical(other.orderStatus, orderStatus) ||
                other.orderStatus == orderStatus) &&
            (identical(other.negotiationStatus, negotiationStatus) ||
                other.negotiationStatus == negotiationStatus) &&
            (identical(other.pickupConfirmed, pickupConfirmed) ||
                other.pickupConfirmed == pickupConfirmed) &&
            (identical(other.deliveryConfirmed, deliveryConfirmed) ||
                other.deliveryConfirmed == deliveryConfirmed) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      orderId,
      orderPath,
      buyerId,
      streetSellerId,
      listingId,
      originalPrice,
      negotiatedPrice,
      finalPrice,
      quantityKg,
      orderStatus,
      negotiationStatus,
      pickupConfirmed,
      deliveryConfirmed,
      createdAt,
      completedAt,
      cancelledAt);

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
          {required final String orderId,
          required final String orderPath,
          required final String buyerId,
          final String? streetSellerId,
          required final String listingId,
          required final double originalPrice,
          final double? negotiatedPrice,
          required final double finalPrice,
          required final double quantityKg,
          required final String orderStatus,
          final String? negotiationStatus,
          required final bool pickupConfirmed,
          required final bool deliveryConfirmed,
          @TimestampConverter() required final DateTime createdAt,
          @OptionalTimestampConverter() final DateTime? completedAt,
          @OptionalTimestampConverter() final DateTime? cancelledAt}) =
      _$OrderModelImpl;

  factory _OrderModel.fromJson(Map<String, dynamic> json) =
      _$OrderModelImpl.fromJson;

  @override
  String get orderId;
  @override
  String get orderPath;
  @override
  String get buyerId;
  @override
  String? get streetSellerId;
  @override
  String get listingId;
  @override
  double get originalPrice;
  @override
  double? get negotiatedPrice;
  @override
  double get finalPrice;
  @override
  double get quantityKg;
  @override
  String get orderStatus;
  @override
  String? get negotiationStatus;
  @override
  bool get pickupConfirmed;
  @override
  bool get deliveryConfirmed;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @OptionalTimestampConverter()
  DateTime? get completedAt;
  @override
  @OptionalTimestampConverter()
  DateTime? get cancelledAt;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderModelImplCopyWith<_$OrderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
