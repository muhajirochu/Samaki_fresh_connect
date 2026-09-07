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
  @OrderStatusConverter()
  OrderStatus get status => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get estimatedArrival => throw _privateConstructorUsedError;
  @GeoPointConverter()
  GeoPoint? get buyerLocation => throw _privateConstructorUsedError;
  @GeoPointConverter()
  GeoPoint? get streetSellerLocation => throw _privateConstructorUsedError;
  bool get isPaid => throw _privateConstructorUsedError;
  @PaymentStatusConverter()
  PaymentStatus get paymentStatus => throw _privateConstructorUsedError;
  @PayoutStatusConverter()
  PayoutStatus get payoutStatus => throw _privateConstructorUsedError;
  double get commissionRate => throw _privateConstructorUsedError;
  double get commissionAmount => throw _privateConstructorUsedError;
  double get sellerEarnings => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get paidAt => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get releasedAt => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get completedAt => throw _privateConstructorUsedError;
  String get paymentReference => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  bool get buyerConfirmed => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get buyerConfirmedAt => throw _privateConstructorUsedError;
  String get buyerComment => throw _privateConstructorUsedError;
  String get buyerFeedbackImageUrl => throw _privateConstructorUsedError;
  bool get isDisputed => throw _privateConstructorUsedError;
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
      @OrderStatusConverter() OrderStatus status,
      @OptionalTimestampConverter() DateTime? estimatedArrival,
      @GeoPointConverter() GeoPoint? buyerLocation,
      @GeoPointConverter() GeoPoint? streetSellerLocation,
      bool isPaid,
      @PaymentStatusConverter() PaymentStatus paymentStatus,
      @PayoutStatusConverter() PayoutStatus payoutStatus,
      double commissionRate,
      double commissionAmount,
      double sellerEarnings,
      @OptionalTimestampConverter() DateTime? paidAt,
      @OptionalTimestampConverter() DateTime? releasedAt,
      @OptionalTimestampConverter() DateTime? completedAt,
      String paymentReference,
      String paymentMethod,
      bool buyerConfirmed,
      @OptionalTimestampConverter() DateTime? buyerConfirmedAt,
      String buyerComment,
      String buyerFeedbackImageUrl,
      bool isDisputed,
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
    Object? paymentStatus = null,
    Object? payoutStatus = null,
    Object? commissionRate = null,
    Object? commissionAmount = null,
    Object? sellerEarnings = null,
    Object? paidAt = freezed,
    Object? releasedAt = freezed,
    Object? completedAt = freezed,
    Object? paymentReference = null,
    Object? paymentMethod = null,
    Object? buyerConfirmed = null,
    Object? buyerConfirmedAt = freezed,
    Object? buyerComment = null,
    Object? buyerFeedbackImageUrl = null,
    Object? isDisputed = null,
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
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as PaymentStatus,
      payoutStatus: null == payoutStatus
          ? _value.payoutStatus
          : payoutStatus // ignore: cast_nullable_to_non_nullable
              as PayoutStatus,
      commissionRate: null == commissionRate
          ? _value.commissionRate
          : commissionRate // ignore: cast_nullable_to_non_nullable
              as double,
      commissionAmount: null == commissionAmount
          ? _value.commissionAmount
          : commissionAmount // ignore: cast_nullable_to_non_nullable
              as double,
      sellerEarnings: null == sellerEarnings
          ? _value.sellerEarnings
          : sellerEarnings // ignore: cast_nullable_to_non_nullable
              as double,
      paidAt: freezed == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      releasedAt: freezed == releasedAt
          ? _value.releasedAt
          : releasedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      paymentReference: null == paymentReference
          ? _value.paymentReference
          : paymentReference // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      buyerConfirmed: null == buyerConfirmed
          ? _value.buyerConfirmed
          : buyerConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      buyerConfirmedAt: freezed == buyerConfirmedAt
          ? _value.buyerConfirmedAt
          : buyerConfirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      buyerComment: null == buyerComment
          ? _value.buyerComment
          : buyerComment // ignore: cast_nullable_to_non_nullable
              as String,
      buyerFeedbackImageUrl: null == buyerFeedbackImageUrl
          ? _value.buyerFeedbackImageUrl
          : buyerFeedbackImageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      isDisputed: null == isDisputed
          ? _value.isDisputed
          : isDisputed // ignore: cast_nullable_to_non_nullable
              as bool,
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
      @OrderStatusConverter() OrderStatus status,
      @OptionalTimestampConverter() DateTime? estimatedArrival,
      @GeoPointConverter() GeoPoint? buyerLocation,
      @GeoPointConverter() GeoPoint? streetSellerLocation,
      bool isPaid,
      @PaymentStatusConverter() PaymentStatus paymentStatus,
      @PayoutStatusConverter() PayoutStatus payoutStatus,
      double commissionRate,
      double commissionAmount,
      double sellerEarnings,
      @OptionalTimestampConverter() DateTime? paidAt,
      @OptionalTimestampConverter() DateTime? releasedAt,
      @OptionalTimestampConverter() DateTime? completedAt,
      String paymentReference,
      String paymentMethod,
      bool buyerConfirmed,
      @OptionalTimestampConverter() DateTime? buyerConfirmedAt,
      String buyerComment,
      String buyerFeedbackImageUrl,
      bool isDisputed,
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
    Object? paymentStatus = null,
    Object? payoutStatus = null,
    Object? commissionRate = null,
    Object? commissionAmount = null,
    Object? sellerEarnings = null,
    Object? paidAt = freezed,
    Object? releasedAt = freezed,
    Object? completedAt = freezed,
    Object? paymentReference = null,
    Object? paymentMethod = null,
    Object? buyerConfirmed = null,
    Object? buyerConfirmedAt = freezed,
    Object? buyerComment = null,
    Object? buyerFeedbackImageUrl = null,
    Object? isDisputed = null,
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
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as PaymentStatus,
      payoutStatus: null == payoutStatus
          ? _value.payoutStatus
          : payoutStatus // ignore: cast_nullable_to_non_nullable
              as PayoutStatus,
      commissionRate: null == commissionRate
          ? _value.commissionRate
          : commissionRate // ignore: cast_nullable_to_non_nullable
              as double,
      commissionAmount: null == commissionAmount
          ? _value.commissionAmount
          : commissionAmount // ignore: cast_nullable_to_non_nullable
              as double,
      sellerEarnings: null == sellerEarnings
          ? _value.sellerEarnings
          : sellerEarnings // ignore: cast_nullable_to_non_nullable
              as double,
      paidAt: freezed == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      releasedAt: freezed == releasedAt
          ? _value.releasedAt
          : releasedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      paymentReference: null == paymentReference
          ? _value.paymentReference
          : paymentReference // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      buyerConfirmed: null == buyerConfirmed
          ? _value.buyerConfirmed
          : buyerConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      buyerConfirmedAt: freezed == buyerConfirmedAt
          ? _value.buyerConfirmedAt
          : buyerConfirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      buyerComment: null == buyerComment
          ? _value.buyerComment
          : buyerComment // ignore: cast_nullable_to_non_nullable
              as String,
      buyerFeedbackImageUrl: null == buyerFeedbackImageUrl
          ? _value.buyerFeedbackImageUrl
          : buyerFeedbackImageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      isDisputed: null == isDisputed
          ? _value.isDisputed
          : isDisputed // ignore: cast_nullable_to_non_nullable
              as bool,
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
      @OrderStatusConverter() this.status = OrderStatus.pending,
      @OptionalTimestampConverter() this.estimatedArrival,
      @GeoPointConverter() this.buyerLocation,
      @GeoPointConverter() this.streetSellerLocation,
      this.isPaid = false,
      @PaymentStatusConverter() this.paymentStatus = PaymentStatus.pending,
      @PayoutStatusConverter() this.payoutStatus = PayoutStatus.pending,
      this.commissionRate = 0.0,
      this.commissionAmount = 0.0,
      this.sellerEarnings = 0.0,
      @OptionalTimestampConverter() this.paidAt,
      @OptionalTimestampConverter() this.releasedAt,
      @OptionalTimestampConverter() this.completedAt,
      this.paymentReference = '',
      this.paymentMethod = '',
      this.buyerConfirmed = false,
      @OptionalTimestampConverter() this.buyerConfirmedAt,
      this.buyerComment = '',
      this.buyerFeedbackImageUrl = '',
      this.isDisputed = false,
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
  @OrderStatusConverter()
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
  @PaymentStatusConverter()
  final PaymentStatus paymentStatus;
  @override
  @JsonKey()
  @PayoutStatusConverter()
  final PayoutStatus payoutStatus;
  @override
  @JsonKey()
  final double commissionRate;
  @override
  @JsonKey()
  final double commissionAmount;
  @override
  @JsonKey()
  final double sellerEarnings;
  @override
  @OptionalTimestampConverter()
  final DateTime? paidAt;
  @override
  @OptionalTimestampConverter()
  final DateTime? releasedAt;
  @override
  @OptionalTimestampConverter()
  final DateTime? completedAt;
  @override
  @JsonKey()
  final String paymentReference;
  @override
  @JsonKey()
  final String paymentMethod;
  @override
  @JsonKey()
  final bool buyerConfirmed;
  @override
  @OptionalTimestampConverter()
  final DateTime? buyerConfirmedAt;
  @override
  @JsonKey()
  final String buyerComment;
  @override
  @JsonKey()
  final String buyerFeedbackImageUrl;
  @override
  @JsonKey()
  final bool isDisputed;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'OrderModel(orderId: $orderId, buyerId: $buyerId, streetSellerId: $streetSellerId, fishId: $fishId, quantity: $quantity, totalPrice: $totalPrice, pickupCode: $pickupCode, status: $status, estimatedArrival: $estimatedArrival, buyerLocation: $buyerLocation, streetSellerLocation: $streetSellerLocation, isPaid: $isPaid, paymentStatus: $paymentStatus, payoutStatus: $payoutStatus, commissionRate: $commissionRate, commissionAmount: $commissionAmount, sellerEarnings: $sellerEarnings, paidAt: $paidAt, releasedAt: $releasedAt, completedAt: $completedAt, paymentReference: $paymentReference, paymentMethod: $paymentMethod, buyerConfirmed: $buyerConfirmed, buyerConfirmedAt: $buyerConfirmedAt, buyerComment: $buyerComment, buyerFeedbackImageUrl: $buyerFeedbackImageUrl, isDisputed: $isDisputed, createdAt: $createdAt, updatedAt: $updatedAt)';
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
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.payoutStatus, payoutStatus) ||
                other.payoutStatus == payoutStatus) &&
            (identical(other.commissionRate, commissionRate) ||
                other.commissionRate == commissionRate) &&
            (identical(other.commissionAmount, commissionAmount) ||
                other.commissionAmount == commissionAmount) &&
            (identical(other.sellerEarnings, sellerEarnings) ||
                other.sellerEarnings == sellerEarnings) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.releasedAt, releasedAt) ||
                other.releasedAt == releasedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.paymentReference, paymentReference) ||
                other.paymentReference == paymentReference) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.buyerConfirmed, buyerConfirmed) ||
                other.buyerConfirmed == buyerConfirmed) &&
            (identical(other.buyerConfirmedAt, buyerConfirmedAt) ||
                other.buyerConfirmedAt == buyerConfirmedAt) &&
            (identical(other.buyerComment, buyerComment) ||
                other.buyerComment == buyerComment) &&
            (identical(other.buyerFeedbackImageUrl, buyerFeedbackImageUrl) ||
                other.buyerFeedbackImageUrl == buyerFeedbackImageUrl) &&
            (identical(other.isDisputed, isDisputed) ||
                other.isDisputed == isDisputed) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
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
        paymentStatus,
        payoutStatus,
        commissionRate,
        commissionAmount,
        sellerEarnings,
        paidAt,
        releasedAt,
        completedAt,
        paymentReference,
        paymentMethod,
        buyerConfirmed,
        buyerConfirmedAt,
        buyerComment,
        buyerFeedbackImageUrl,
        isDisputed,
        createdAt,
        updatedAt
      ]);

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
          @OrderStatusConverter() final OrderStatus status,
          @OptionalTimestampConverter() final DateTime? estimatedArrival,
          @GeoPointConverter() final GeoPoint? buyerLocation,
          @GeoPointConverter() final GeoPoint? streetSellerLocation,
          final bool isPaid,
          @PaymentStatusConverter() final PaymentStatus paymentStatus,
          @PayoutStatusConverter() final PayoutStatus payoutStatus,
          final double commissionRate,
          final double commissionAmount,
          final double sellerEarnings,
          @OptionalTimestampConverter() final DateTime? paidAt,
          @OptionalTimestampConverter() final DateTime? releasedAt,
          @OptionalTimestampConverter() final DateTime? completedAt,
          final String paymentReference,
          final String paymentMethod,
          final bool buyerConfirmed,
          @OptionalTimestampConverter() final DateTime? buyerConfirmedAt,
          final String buyerComment,
          final String buyerFeedbackImageUrl,
          final bool isDisputed,
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
  @OrderStatusConverter()
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
  @PaymentStatusConverter()
  PaymentStatus get paymentStatus;
  @override
  @PayoutStatusConverter()
  PayoutStatus get payoutStatus;
  @override
  double get commissionRate;
  @override
  double get commissionAmount;
  @override
  double get sellerEarnings;
  @override
  @OptionalTimestampConverter()
  DateTime? get paidAt;
  @override
  @OptionalTimestampConverter()
  DateTime? get releasedAt;
  @override
  @OptionalTimestampConverter()
  DateTime? get completedAt;
  @override
  String get paymentReference;
  @override
  String get paymentMethod;
  @override
  bool get buyerConfirmed;
  @override
  @OptionalTimestampConverter()
  DateTime? get buyerConfirmedAt;
  @override
  String get buyerComment;
  @override
  String get buyerFeedbackImageUrl;
  @override
  bool get isDisputed;
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
