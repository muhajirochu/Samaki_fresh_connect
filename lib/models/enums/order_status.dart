import 'package:freezed_annotation/freezed_annotation.dart';

enum OrderStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('preparing')
  preparing,
  @JsonValue('pickupGenerated')
  pickupGenerated,
  @JsonValue('arriving')
  arriving,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}
