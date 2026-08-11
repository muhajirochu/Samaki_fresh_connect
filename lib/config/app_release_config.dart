/// App Release Configuration for SamakiFresh Connect.
///
/// Contains release metadata, download URLs, and installation steps
/// for Android APK distribution and presentation demonstrations.
///
/// Updating the properties in this file updates the download URL,
/// QR code, version label, and release details throughout the app.
class AppReleaseConfig {
  const AppReleaseConfig._();

  static const String appName = 'SamakiFresh Connect';
  static const String appTagline = 'Fair Price. Fresh Fish. Quick Delivery.';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String fullVersion = 'v$version+$buildNumber';
  static const String releaseDate = 'August 2026';
  static const String apkSize = '64.5 MB';
  static const String minAndroidVersion = 'Android 7.0 (API 24)+';
  static const String minIosVersion = 'iOS 13.0+';
  static const String status = 'Official Public Release';

  /// Permanent public download page URL.
  ///
  /// The in-app QR code and the PDF QR code both encode *this* URL,
  /// not the direct APK URL. Decoupling them means a new APK release
  /// does not require regenerating the QR — only the `downloadUrl`
  /// (or `iosDownloadUrl`) below changes. Update this single string
  /// to point at the deployed landing page (Firebase Hosting,
  /// GitHub Pages, custom domain, …).
  static const String publicDownloadPageUrl =
      'https://samakifresh.example/download';

  /// Direct-download HTTPS link for the Release Android APK.
  ///
  /// Scanners and browsers receive HTTP 200 OK directly with the `.apk`
  /// file binary stream and immediately start downloading the APK
  /// directly onto the phone without opening GitHub or any intermediate
  /// web page. Mirrored by the Android install button on the Download
  /// page and the Android card in the PDF.
  static const String downloadUrl = 'https://files.catbox.moe/yfmqat.apk';

  /// iOS distribution URL — TestFlight invite link or App Store URL.
  ///
  /// `null` until the iOS TestFlight invite is provisioned. While null,
  /// the iOS install button on the Download page is shown in a disabled
  /// "Coming soon" state and the PDF's iOS card shows the same
  /// placeholder. Set this to e.g.
  ///   `https://testflight.apple.com/join/SAMAKI`
  /// or
  ///   `https://apps.apple.com/app/id<appleAppId>`
  /// when ready.
  static const String? iosDownloadUrl = null;

  /// Short summary of key features in this release. Surfaced in the PDF
  /// specification table; reserved for a future in-app "what's new"
  /// sheet.
  static const List<String> releaseNotes = [
    'Direct Android APK distribution with zero USB debugging required',
    'Real-time fish marketplace with live OSM geolocation',
    'Role-based dashboards for Buyers, Street Sellers, and Admins',
    'Instant order updates and delivery tracking',
    'Modern Material 3 Ocean Teal design system',
  ];

  /// Easy step-by-step installation instructions for end users.
  static const List<InstallationStep> installationSteps = [
    InstallationStep(
      stepNumber: 1,
      title: 'Scan QR or Tap Download',
      description:
          'Scan the QR code with any phone camera or tap the "Download APK" button below to start the direct download.',
    ),
    InstallationStep(
      stepNumber: 2,
      title: 'Open Downloaded File',
      description:
          'Once downloaded, open the file from your browser\'s downloads bar or your device\'s Files manager.',
    ),
    InstallationStep(
      stepNumber: 3,
      title: 'Allow Installation',
      description:
          'If Android prompts "Install unknown apps", tap Settings and toggle "Allow from this source".',
    ),
    InstallationStep(
      stepNumber: 4,
      title: 'Install & Launch',
      description:
          'Tap "Install" to complete setup. Launch SamakiFresh Connect and start connecting to the fish marketplace!',
    ),
  ];
}

class InstallationStep {
  final int stepNumber;
  final String title;
  final String description;

  const InstallationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
  });
}
