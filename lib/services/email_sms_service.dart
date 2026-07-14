import '../utils/logger.dart';

class EmailSmsService {
  /// Sends an email to the newly registered Dalali
  Future<void> sendRegistrationEmail({
    required String email,
    required String fullName,
    required String password,
  }) async {
    // In a real application, this would call a Cloud Function or backend endpoint
    // that uses SendGrid, AWS SES, or similar to dispatch an email.
    AppLogger.info('--- SIMULATING EMAIL DISPATCH ---');
    AppLogger.info('To: $email');
    AppLogger.info(
        'Subject: Welcome to SamakiFresh Connect - Your Dalali Account');
    AppLogger.info('''
Body:
Karibu $fullName,

Your Dalali account has been created successfully!

Login Credentials:
Email: $email
Password: $password

Please login to start posting fish listings.

Important:
- Please change your password after first login
- Keep your credentials secure

SamakiFresh Connect Team
www.samakifresh.com
''');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Sends an SMS to the newly registered Dalali
  Future<void> sendRegistrationSms({
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    // In a real application, this would call a backend endpoint using Twilio, Africa's Talking, etc.
    AppLogger.info('--- SIMULATING SMS DISPATCH ---');
    AppLogger.info('To: $phoneNumber');
    AppLogger.info('''
Message:
Karibu SamakiFresh! Dalali account created.
Email: $email
Password: $password
Login: samakifresh.com/login
''');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
