import 'package:freezed_annotation/freezed_annotation.dart';

enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('successful')
  successful,
  @JsonValue('held')
  held,
  @JsonValue('released')
  released,
  @JsonValue('refunded')
  refunded,
  @JsonValue('failed')
  failed,
}

class PaymentStatusConverter implements JsonConverter<PaymentStatus, String> {
  const PaymentStatusConverter();

  @override
  PaymentStatus fromJson(String json) {
    switch (json) {
      case 'pending': return PaymentStatus.pending;
      case 'successful': return PaymentStatus.successful;
      case 'held': return PaymentStatus.held;
      case 'released': return PaymentStatus.released;
      case 'refunded': return PaymentStatus.refunded;
      case 'failed': return PaymentStatus.failed;
      case 'awaiting_admin_approval':
      case 'awaiting_approval':
      case 'awaiting_admin_verification':
        return PaymentStatus.held;
      default: return PaymentStatus.pending;
    }
  }

  @override
  String toJson(PaymentStatus object) => object.name;
}
