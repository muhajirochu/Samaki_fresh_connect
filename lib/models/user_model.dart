import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';
import '../utils/user_role_converter.dart';
import 'enums/user_role.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Converts the Firestore `location` field to `Map<String, dynamic>?`.
///
/// The field may arrive as:
///   - `null`  → return null
///   - `GeoPoint` → convert to `{'latitude': ..., 'longitude': ...}`
///   - `Map<String, dynamic>` → return as-is
///   - anything else → return null (safe fallback)
Map<String, dynamic>? _locationFromJson(dynamic value) {
  if (value == null) return null;
  if (value is GeoPoint) {
    return {'latitude': value.latitude, 'longitude': value.longitude};
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    @Default('') String userId,
    @Default('') String email,
    @Default('') String fullName,
    @Default('') String phoneNumber,
    @UserRoleConverter() @Default(UserRole.buyer) UserRole role,
    String? profilePictureUrl,
    Map<String, dynamic>? location,
    @Default(true) bool isActive,
    String? registeredBy,

    // Dalali Specific Fields
    @Default(false) bool isApproved,
    String? approvedBy,
    @OptionalTimestampConverter() DateTime? approvedAt,
    String? fishMarketName,
    String? zanzibarIdNumber,
    String? businessPermitNumber,
    @Default(0) int totalListings,
    @Default(0) int totalOrders,
    @Default(0.0) double totalSales,
    @Default(0.0) double averageRating,
    @Default(0.0) double totalEarnings,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
