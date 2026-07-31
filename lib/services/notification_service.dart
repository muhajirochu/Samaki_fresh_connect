// Notifications service.
//
// Two surfaces:
//   1. Local push — wraps `flutter_local_notifications` (existing).
//   2. Cloud-backed notifications collection — written to Firestore at
//      `notifications/{auto-id}`, scoped to the buyer via `userId`. The
//      buyer-side `notificationsProvider` streams this collection.
//
// Writers (sellers, dalalis, the system) call `writeNotification` with
// the buyer's userId. Readers (the buyer dashboard / bell icon) call
// `streamForUser` and `unreadCount`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/enums/notification_type.dart';
import '../utils/logger.dart';

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static int _localId = 0;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  static const String _collection = 'notifications';

  // ── Local push init / show (existing) ─────────────────────────────────────

  Future<void> init() async {
    try {
      // Per-platform settings. The plugin refuses to initialize if the
      // target platform has no settings — on Linux that means
      // `defaultActionName` is required, on macOS it reuses the Darwin
      // settings, on Windows the package adds a dedicated
      // `WindowsInitializationSettings`. Every platform we ship for
      // gets an entry so `flutter run -d <anything>` works without the
      // "Linux settings must be set" error.
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const macosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open Samaki Fresh',
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macosSettings,
        linux: linuxSettings,
      );
      await _notificationsPlugin.initialize(initSettings);
      AppLogger.info('NotificationService initialized');
    } catch (e) {
      AppLogger.error('Error initializing NotificationService: $e');
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    NotificationType type = NotificationType.generic,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'samaki_fresh_connect',
        'SamakiFresh Notifications',
        channelDescription: 'Notifications for SamakiFresh Connect',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(presentSound: true);
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _notificationsPlugin.show(
        _localId++,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      AppLogger.error('Local notification failed: $e');
    }
  }

  // ── Cloud notifications ──────────────────────────────────────────────────

  /// Persist a notification targeted at [userId]. Idempotent only at the
  /// collection level (each call creates a new doc); callers that need
  /// idempotency should check existence first.
  Future<String?> writeNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    if (!_isAvailable) return null;
    try {
      final data = <String, dynamic>{
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      final ref = await _firestore.collection(_collection).add(data);
      AppLogger.info(
          'Notification written: ${ref.id} type=${type.value} → $userId');
      return ref.id;
    } catch (e) {
      AppLogger.error('writeNotification failed: $e');
      return null;
    }
  }

  /// Stream of all notifications for [userId], newest first.
  Stream<List<NotificationItem>> streamForUser(String userId) {
    if (!_isAvailable) return Stream.value(const []);
    // No `.orderBy(...)` — sorting in memory keeps the stream alive
    // until the deployed `(userId, createdAt DESC)` composite index
    // is available.
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snap) {
      final list = <NotificationItem>[];
      for (final d in snap.docs) {
        try {
          list.add(_fromDoc(d));
        } catch (e) {
          AppLogger.debug(
              'streamForUser: dropping malformed doc ${d.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Live count of unread items. Cheap stream — Firestore filters server-side.
  Stream<int> unreadCount(String userId) {
    if (!_isAvailable) return Stream.value(0);
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    if (!_isAvailable) return;
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      AppLogger.error('markAsRead failed: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    if (!_isAvailable) return;
    try {
      final batch = _firestore.batch();
      final snap = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error('markAllAsRead failed: $e');
    }
  }

  NotificationItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final ts = data['createdAt'];
    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is String) {
      created = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }
    return NotificationItem(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      type: NotificationTypeExtension.fromString(data['type'] as String?),
      relatedId: data['relatedId'] as String?,
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: created,
    );
  }
}
