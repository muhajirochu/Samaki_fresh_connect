// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DeliveryModel _$DeliveryModelFromJson(Map<String, dynamic> json) {
  return _DeliveryModel.fromJson(json);
}

/// @nodoc
mixin _$DeliveryModel {
  String get deliveryId => throw _privateConstructorUsedError;
  String get orderId => throw _privateConstructorUsedError;
  String get sellerId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get pickupLocation =>
      throw _privateConstructorUsedError;
  Map<String, dynamic>? get dropoffLocation =>
      throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get pickedUpAt => throw _privateConstructorUsedError;
  DateTime? get deliveredAt => throw _privateConstructorUsedError;
  double get deliveryFee => throw _privateConstructorUsedError;

  /// Serializes this DeliveryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeliveryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeliveryModelCopyWith<DeliveryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryModelCopyWith<$Res> {
  factory $DeliveryModelCopyWith(
          DeliveryModel value, $Res Function(DeliveryModel) then) =
      _$DeliveryModelCopyWithImpl<$Res, DeliveryModel>;
  @useResult
  $Res call(
      {String deliveryId,
      String orderId,
      String sellerId,
      Map<String, dynamic>? pickupLocation,
      Map<String, dynamic>? dropoffLocation,
      String status,
      DateTime? pickedUpAt,
      DateTime? deliveredAt,
      double deliveryFee});
}

/// @nodoc
class _$DeliveryModelCopyWithImpl<$Res, $Val extends DeliveryModel>
    implements $DeliveryModelCopyWith<$Res> {
  _$DeliveryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeliveryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deliveryId = null,
    Object? orderId = null,
    Object? sellerId = null,
    Object? pickupLocation = freezed,
    Object? dropoffLocation = freezed,
    Object? status = null,
    Object? pickedUpAt = freezed,
    Object? deliveredAt = freezed,
    Object? deliveryFee = null,
  }) {
    return _then(_value.copyWith(
      deliveryId: null == deliveryId
          ? _value.deliveryId
          : deliveryId // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      sellerId: null == sellerId
          ? _value.sellerId
          : sellerId // ignore: cast_nullable_to_non_nullable
              as String,
      pickupLocation: freezed == pickupLocation
          ? _value.pickupLocation
          : pickupLocation // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      dropoffLocation: freezed == dropoffLocation
          ? _value.dropoffLocation
          : dropoffLocation // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      pickedUpAt: freezed == pickedUpAt
          ? _value.pickedUpAt
          : pickedUpAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deliveredAt: freezed == deliveredAt
          ? _value.deliveredAt
          : deliveredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deliveryFee: null == deliveryFee
          ? _value.deliveryFee
          : deliveryFee // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeliveryModelImplCopyWith<$Res>
    implements $DeliveryModelCopyWith<$Res> {
  factory _$$DeliveryModelImplCopyWith(
          _$DeliveryModelImpl value, $Res Function(_$DeliveryModelImpl) then) =
      __$$DeliveryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String deliveryId,
      String orderId,
      String sellerId,
      Map<String, dynamic>? pickupLocation,
      Map<String, dynamic>? dropoffLocation,
      String status,
      DateTime? pickedUpAt,
      DateTime? deliveredAt,
      double deliveryFee});
}

/// @nodoc
class __$$DeliveryModelImplCopyWithImpl<$Res>
    extends _$DeliveryModelCopyWithImpl<$Res, _$DeliveryModelImpl>
    implements _$$DeliveryModelImplCopyWith<$Res> {
  __$$DeliveryModelImplCopyWithImpl(
      _$DeliveryModelImpl _value, $Res Function(_$DeliveryModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeliveryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deliveryId = null,
    Object? orderId = null,
    Object? sellerId = null,
    Object? pickupLocation = freezed,
    Object? dropoffLocation = freezed,
    Object? status = null,
    Object? pickedUpAt = freezed,
    Object? deliveredAt = freezed,
    Object? deliveryFee = null,
  }) {
    return _then(_$DeliveryModelImpl(
      deliveryId: null == deliveryId
          ? _value.deliveryId
          : deliveryId // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      sellerId: null == sellerId
          ? _value.sellerId
          : sellerId // ignore: cast_nullable_to_non_nullable
              as String,
      pickupLocation: freezed == pickupLocation
          ? _value._pickupLocation
          : pickupLocation // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      dropoffLocation: freezed == dropoffLocation
          ? _value._dropoffLocation
          : dropoffLocation // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      pickedUpAt: freezed == pickedUpAt
          ? _value.pickedUpAt
          : pickedUpAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deliveredAt: freezed == deliveredAt
          ? _value.deliveredAt
          : deliveredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deliveryFee: null == deliveryFee
          ? _value.deliveryFee
          : deliveryFee // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeliveryModelImpl implements _DeliveryModel {
  const _$DeliveryModelImpl(
      {required this.deliveryId,
      required this.orderId,
      required this.sellerId,
      final Map<String, dynamic>? pickupLocation,
      final Map<String, dynamic>? dropoffLocation,
      required this.status,
      this.pickedUpAt,
      this.deliveredAt,
      required this.deliveryFee})
      : _pickupLocation = pickupLocation,
        _dropoffLocation = dropoffLocation;

  factory _$DeliveryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeliveryModelImplFromJson(json);

  @override
  final String deliveryId;
  @override
  final String orderId;
  @override
  final String sellerId;
  final Map<String, dynamic>? _pickupLocation;
  @override
  Map<String, dynamic>? get pickupLocation {
    final value = _pickupLocation;
    if (value == null) return null;
    if (_pickupLocation is EqualUnmodifiableMapView) return _pickupLocation;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _dropoffLocation;
  @override
  Map<String, dynamic>? get dropoffLocation {
    final value = _dropoffLocation;
    if (value == null) return null;
    if (_dropoffLocation is EqualUnmodifiableMapView) return _dropoffLocation;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String status;
  @override
  final DateTime? pickedUpAt;
  @override
  final DateTime? deliveredAt;
  @override
  final double deliveryFee;

  @override
  String toString() {
    return 'DeliveryModel(deliveryId: $deliveryId, orderId: $orderId, sellerId: $sellerId, pickupLocation: $pickupLocation, dropoffLocation: $dropoffLocation, status: $status, pickedUpAt: $pickedUpAt, deliveredAt: $deliveredAt, deliveryFee: $deliveryFee)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryModelImpl &&
            (identical(other.deliveryId, deliveryId) ||
                other.deliveryId == deliveryId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.sellerId, sellerId) ||
                other.sellerId == sellerId) &&
            const DeepCollectionEquality()
                .equals(other._pickupLocation, _pickupLocation) &&
            const DeepCollectionEquality()
                .equals(other._dropoffLocation, _dropoffLocation) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.pickedUpAt, pickedUpAt) ||
                other.pickedUpAt == pickedUpAt) &&
            (identical(other.deliveredAt, deliveredAt) ||
                other.deliveredAt == deliveredAt) &&
            (identical(other.deliveryFee, deliveryFee) ||
                other.deliveryFee == deliveryFee));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      deliveryId,
      orderId,
      sellerId,
      const DeepCollectionEquality().hash(_pickupLocation),
      const DeepCollectionEquality().hash(_dropoffLocation),
      status,
      pickedUpAt,
      deliveredAt,
      deliveryFee);

  /// Create a copy of DeliveryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryModelImplCopyWith<_$DeliveryModelImpl> get copyWith =>
      __$$DeliveryModelImplCopyWithImpl<_$DeliveryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeliveryModelImplToJson(
      this,
    );
  }
}

abstract class _DeliveryModel implements DeliveryModel {
  const factory _DeliveryModel(
      {required final String deliveryId,
      required final String orderId,
      required final String sellerId,
      final Map<String, dynamic>? pickupLocation,
      final Map<String, dynamic>? dropoffLocation,
      required final String status,
      final DateTime? pickedUpAt,
      final DateTime? deliveredAt,
      required final double deliveryFee}) = _$DeliveryModelImpl;

  factory _DeliveryModel.fromJson(Map<String, dynamic> json) =
      _$DeliveryModelImpl.fromJson;

  @override
  String get deliveryId;
  @override
  String get orderId;
  @override
  String get sellerId;
  @override
  Map<String, dynamic>? get pickupLocation;
  @override
  Map<String, dynamic>? get dropoffLocation;
  @override
  String get status;
  @override
  DateTime? get pickedUpAt;
  @override
  DateTime? get deliveredAt;
  @override
  double get deliveryFee;

  /// Create a copy of DeliveryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryModelImplCopyWith<_$DeliveryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
