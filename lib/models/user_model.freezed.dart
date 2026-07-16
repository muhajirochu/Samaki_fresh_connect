// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  String get userId => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  String get phoneNumber => throw _privateConstructorUsedError;
  @UserRoleConverter()
  UserRole get role => throw _privateConstructorUsedError;
  String? get profilePictureUrl => throw _privateConstructorUsedError;
  Map<String, dynamic>? get location => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get registeredBy =>
      throw _privateConstructorUsedError; // Dalali Specific Fields
  bool get isApproved => throw _privateConstructorUsedError;
  String? get approvedBy => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get approvedAt => throw _privateConstructorUsedError;
  String? get fishMarketName => throw _privateConstructorUsedError;
  String? get zanzibarIdNumber => throw _privateConstructorUsedError;
  String? get businessPermitNumber => throw _privateConstructorUsedError;
  int get totalListings => throw _privateConstructorUsedError;
  int get totalOrders => throw _privateConstructorUsedError;
  double get totalSales => throw _privateConstructorUsedError;
  double get averageRating => throw _privateConstructorUsedError;
  double get totalEarnings => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String userId,
      String email,
      String fullName,
      String phoneNumber,
      @UserRoleConverter() UserRole role,
      String? profilePictureUrl,
      Map<String, dynamic>? location,
      bool isActive,
      String? registeredBy,
      bool isApproved,
      String? approvedBy,
      @OptionalTimestampConverter() DateTime? approvedAt,
      String? fishMarketName,
      String? zanzibarIdNumber,
      String? businessPermitNumber,
      int totalListings,
      int totalOrders,
      double totalSales,
      double averageRating,
      double totalEarnings,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? email = null,
    Object? fullName = null,
    Object? phoneNumber = null,
    Object? role = null,
    Object? profilePictureUrl = freezed,
    Object? location = freezed,
    Object? isActive = null,
    Object? registeredBy = freezed,
    Object? isApproved = null,
    Object? approvedBy = freezed,
    Object? approvedAt = freezed,
    Object? fishMarketName = freezed,
    Object? zanzibarIdNumber = freezed,
    Object? businessPermitNumber = freezed,
    Object? totalListings = null,
    Object? totalOrders = null,
    Object? totalSales = null,
    Object? averageRating = null,
    Object? totalEarnings = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      profilePictureUrl: freezed == profilePictureUrl
          ? _value.profilePictureUrl
          : profilePictureUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      registeredBy: freezed == registeredBy
          ? _value.registeredBy
          : registeredBy // ignore: cast_nullable_to_non_nullable
              as String?,
      isApproved: null == isApproved
          ? _value.isApproved
          : isApproved // ignore: cast_nullable_to_non_nullable
              as bool,
      approvedBy: freezed == approvedBy
          ? _value.approvedBy
          : approvedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fishMarketName: freezed == fishMarketName
          ? _value.fishMarketName
          : fishMarketName // ignore: cast_nullable_to_non_nullable
              as String?,
      zanzibarIdNumber: freezed == zanzibarIdNumber
          ? _value.zanzibarIdNumber
          : zanzibarIdNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      businessPermitNumber: freezed == businessPermitNumber
          ? _value.businessPermitNumber
          : businessPermitNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      totalListings: null == totalListings
          ? _value.totalListings
          : totalListings // ignore: cast_nullable_to_non_nullable
              as int,
      totalOrders: null == totalOrders
          ? _value.totalOrders
          : totalOrders // ignore: cast_nullable_to_non_nullable
              as int,
      totalSales: null == totalSales
          ? _value.totalSales
          : totalSales // ignore: cast_nullable_to_non_nullable
              as double,
      averageRating: null == averageRating
          ? _value.averageRating
          : averageRating // ignore: cast_nullable_to_non_nullable
              as double,
      totalEarnings: null == totalEarnings
          ? _value.totalEarnings
          : totalEarnings // ignore: cast_nullable_to_non_nullable
              as double,
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
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String email,
      String fullName,
      String phoneNumber,
      @UserRoleConverter() UserRole role,
      String? profilePictureUrl,
      Map<String, dynamic>? location,
      bool isActive,
      String? registeredBy,
      bool isApproved,
      String? approvedBy,
      @OptionalTimestampConverter() DateTime? approvedAt,
      String? fishMarketName,
      String? zanzibarIdNumber,
      String? businessPermitNumber,
      int totalListings,
      int totalOrders,
      double totalSales,
      double averageRating,
      double totalEarnings,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? email = null,
    Object? fullName = null,
    Object? phoneNumber = null,
    Object? role = null,
    Object? profilePictureUrl = freezed,
    Object? location = freezed,
    Object? isActive = null,
    Object? registeredBy = freezed,
    Object? isApproved = null,
    Object? approvedBy = freezed,
    Object? approvedAt = freezed,
    Object? fishMarketName = freezed,
    Object? zanzibarIdNumber = freezed,
    Object? businessPermitNumber = freezed,
    Object? totalListings = null,
    Object? totalOrders = null,
    Object? totalSales = null,
    Object? averageRating = null,
    Object? totalEarnings = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$UserModelImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      profilePictureUrl: freezed == profilePictureUrl
          ? _value.profilePictureUrl
          : profilePictureUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value._location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      registeredBy: freezed == registeredBy
          ? _value.registeredBy
          : registeredBy // ignore: cast_nullable_to_non_nullable
              as String?,
      isApproved: null == isApproved
          ? _value.isApproved
          : isApproved // ignore: cast_nullable_to_non_nullable
              as bool,
      approvedBy: freezed == approvedBy
          ? _value.approvedBy
          : approvedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fishMarketName: freezed == fishMarketName
          ? _value.fishMarketName
          : fishMarketName // ignore: cast_nullable_to_non_nullable
              as String?,
      zanzibarIdNumber: freezed == zanzibarIdNumber
          ? _value.zanzibarIdNumber
          : zanzibarIdNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      businessPermitNumber: freezed == businessPermitNumber
          ? _value.businessPermitNumber
          : businessPermitNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      totalListings: null == totalListings
          ? _value.totalListings
          : totalListings // ignore: cast_nullable_to_non_nullable
              as int,
      totalOrders: null == totalOrders
          ? _value.totalOrders
          : totalOrders // ignore: cast_nullable_to_non_nullable
              as int,
      totalSales: null == totalSales
          ? _value.totalSales
          : totalSales // ignore: cast_nullable_to_non_nullable
              as double,
      averageRating: null == averageRating
          ? _value.averageRating
          : averageRating // ignore: cast_nullable_to_non_nullable
              as double,
      totalEarnings: null == totalEarnings
          ? _value.totalEarnings
          : totalEarnings // ignore: cast_nullable_to_non_nullable
              as double,
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
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {required this.userId,
      required this.email,
      required this.fullName,
      required this.phoneNumber,
      @UserRoleConverter() required this.role,
      this.profilePictureUrl,
      final Map<String, dynamic>? location,
      required this.isActive,
      this.registeredBy,
      this.isApproved = false,
      this.approvedBy,
      @OptionalTimestampConverter() this.approvedAt,
      this.fishMarketName,
      this.zanzibarIdNumber,
      this.businessPermitNumber,
      this.totalListings = 0,
      this.totalOrders = 0,
      this.totalSales = 0.0,
      this.averageRating = 0.0,
      this.totalEarnings = 0.0,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.updatedAt})
      : _location = location;

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final String userId;
  @override
  final String email;
  @override
  final String fullName;
  @override
  final String phoneNumber;
  @override
  @UserRoleConverter()
  final UserRole role;
  @override
  final String? profilePictureUrl;
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
  final bool isActive;
  @override
  final String? registeredBy;
// Dalali Specific Fields
  @override
  @JsonKey()
  final bool isApproved;
  @override
  final String? approvedBy;
  @override
  @OptionalTimestampConverter()
  final DateTime? approvedAt;
  @override
  final String? fishMarketName;
  @override
  final String? zanzibarIdNumber;
  @override
  final String? businessPermitNumber;
  @override
  @JsonKey()
  final int totalListings;
  @override
  @JsonKey()
  final int totalOrders;
  @override
  @JsonKey()
  final double totalSales;
  @override
  @JsonKey()
  final double averageRating;
  @override
  @JsonKey()
  final double totalEarnings;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'UserModel(userId: $userId, email: $email, fullName: $fullName, phoneNumber: $phoneNumber, role: $role, profilePictureUrl: $profilePictureUrl, location: $location, isActive: $isActive, registeredBy: $registeredBy, isApproved: $isApproved, approvedBy: $approvedBy, approvedAt: $approvedAt, fishMarketName: $fishMarketName, zanzibarIdNumber: $zanzibarIdNumber, businessPermitNumber: $businessPermitNumber, totalListings: $totalListings, totalOrders: $totalOrders, totalSales: $totalSales, averageRating: $averageRating, totalEarnings: $totalEarnings, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.profilePictureUrl, profilePictureUrl) ||
                other.profilePictureUrl == profilePictureUrl) &&
            const DeepCollectionEquality().equals(other._location, _location) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.registeredBy, registeredBy) ||
                other.registeredBy == registeredBy) &&
            (identical(other.isApproved, isApproved) ||
                other.isApproved == isApproved) &&
            (identical(other.approvedBy, approvedBy) ||
                other.approvedBy == approvedBy) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.fishMarketName, fishMarketName) ||
                other.fishMarketName == fishMarketName) &&
            (identical(other.zanzibarIdNumber, zanzibarIdNumber) ||
                other.zanzibarIdNumber == zanzibarIdNumber) &&
            (identical(other.businessPermitNumber, businessPermitNumber) ||
                other.businessPermitNumber == businessPermitNumber) &&
            (identical(other.totalListings, totalListings) ||
                other.totalListings == totalListings) &&
            (identical(other.totalOrders, totalOrders) ||
                other.totalOrders == totalOrders) &&
            (identical(other.totalSales, totalSales) ||
                other.totalSales == totalSales) &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            (identical(other.totalEarnings, totalEarnings) ||
                other.totalEarnings == totalEarnings) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        userId,
        email,
        fullName,
        phoneNumber,
        role,
        profilePictureUrl,
        const DeepCollectionEquality().hash(_location),
        isActive,
        registeredBy,
        isApproved,
        approvedBy,
        approvedAt,
        fishMarketName,
        zanzibarIdNumber,
        businessPermitNumber,
        totalListings,
        totalOrders,
        totalSales,
        averageRating,
        totalEarnings,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
          {required final String userId,
          required final String email,
          required final String fullName,
          required final String phoneNumber,
          @UserRoleConverter() required final UserRole role,
          final String? profilePictureUrl,
          final Map<String, dynamic>? location,
          required final bool isActive,
          final String? registeredBy,
          final bool isApproved,
          final String? approvedBy,
          @OptionalTimestampConverter() final DateTime? approvedAt,
          final String? fishMarketName,
          final String? zanzibarIdNumber,
          final String? businessPermitNumber,
          final int totalListings,
          final int totalOrders,
          final double totalSales,
          final double averageRating,
          final double totalEarnings,
          @TimestampConverter() required final DateTime createdAt,
          @TimestampConverter() required final DateTime updatedAt}) =
      _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  String get userId;
  @override
  String get email;
  @override
  String get fullName;
  @override
  String get phoneNumber;
  @override
  @UserRoleConverter()
  UserRole get role;
  @override
  String? get profilePictureUrl;
  @override
  Map<String, dynamic>? get location;
  @override
  bool get isActive;
  @override
  String? get registeredBy; // Dalali Specific Fields
  @override
  bool get isApproved;
  @override
  String? get approvedBy;
  @override
  @OptionalTimestampConverter()
  DateTime? get approvedAt;
  @override
  String? get fishMarketName;
  @override
  String? get zanzibarIdNumber;
  @override
  String? get businessPermitNumber;
  @override
  int get totalListings;
  @override
  int get totalOrders;
  @override
  double get totalSales;
  @override
  double get averageRating;
  @override
  double get totalEarnings;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
