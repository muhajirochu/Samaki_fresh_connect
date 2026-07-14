import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/email_sms_service.dart';

final emailSmsServiceProvider = Provider<EmailSmsService>((ref) {
  return EmailSmsService();
});
