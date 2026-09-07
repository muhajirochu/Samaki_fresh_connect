import 'package:freezed_annotation/freezed_annotation.dart';

enum OrderStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('preparing')
  preparing,
  @JsonValue('readyForPickup')
  readyForPickup,
  @JsonValue('outForDelivery')
  outForDelivery,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('disputed')
  disputed,
}

class OrderStatusConverter implements JsonConverter<OrderStatus, String> {
  const OrderStatusConverter();

  @override
  OrderStatus fromJson(String json) {
    switch (json) {
      case 'pending': return OrderStatus.pending;
      case 'accepted':
      case 'paid':
      case 'confirmed': return OrderStatus.confirmed;
      case 'preparing': return OrderStatus.preparing;
      case 'pickupGenerated':
      case 'readyForPickup': return OrderStatus.readyForPickup;
      case 'arriving':
      case 'outForDelivery': return OrderStatus.outForDelivery;
      case 'completed': return OrderStatus.completed;
      case 'cancelled': return OrderStatus.cancelled;
      case 'disputed': return OrderStatus.disputed;
      default: return OrderStatus.pending;
    }
  }

  @override
  String toJson(OrderStatus object) => object.name;
}
