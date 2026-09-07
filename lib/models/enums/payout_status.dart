import 'package:freezed_annotation/freezed_annotation.dart';

enum PayoutStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('paid')
  paid,
  @JsonValue('held')
  held,
  @JsonValue('disputed')
  disputed,
  @JsonValue('refunded')
  refunded,
  @JsonValue('failed')
  failed,
}

class PayoutStatusConverter implements JsonConverter<PayoutStatus, String> {
  const PayoutStatusConverter();

  @override
  PayoutStatus fromJson(String json) {
    switch (json) {
      case 'pending': return PayoutStatus.pending;
      case 'processing': return PayoutStatus.processing;
      case 'paid': return PayoutStatus.paid;
      case 'held': return PayoutStatus.held;
      case 'disputed': return PayoutStatus.disputed;
      case 'refunded': return PayoutStatus.refunded;
      case 'failed': return PayoutStatus.failed;
      case 'awaiting_admin_approval':
      case 'awaiting_approval':
      case 'awaiting_admin_verification':
        return PayoutStatus.pending;
      default: return PayoutStatus.pending;
    }
  }

  @override
  String toJson(PayoutStatus object) => object.name;
}
