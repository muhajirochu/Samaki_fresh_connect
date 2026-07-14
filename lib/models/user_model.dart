import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';
import 'enums/user_role.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String userId,
    required String email,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    String? profilePictureUrl,
    Map<String, dynamic>? location,
    required bool isActive,
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
