// ActivityLogService — admin-side audit trail writes and reads.
//
// Every meaningful platform event writes a doc here so the admin
// can answer "who did what when?" without trawling through
// Firestore by hand.
//
// CRITICAL — writes are BEST EFFORT.
//
// Callers MUST wrap every `write(...)` call in try/catch and
// downgrade to `AppLogger.warning` on failure. A failed audit
// write must never block a login, order placement, or admin
// mutation. The activity log is observability, not a hard
// dependency.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/activity_log_model.dart';
import '../utils/logger.dart';

class ActivityLogService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  static const String _collection = 'activityLogs';

  /// Append a single log entry. Returns the generated document id,
  /// or `null` if Firebase is unavailable / the write failed.
  /// Callers should `await` this from a `try/catch` and treat any
  /// exception as a soft warning.
  Future<String?> write({
    required String type,
    String? actorUid,
    String? actorRole,
    String? targetType,
    String? targetId,
    required String title,
    String? subtitle,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isAvailable) return null;
    try {
      final docRef = _firestore.collection(_collection).doc();
      final entry = ActivityLogModel(
        logId: docRef.id,
        type: type,
        actorUid: actorUid,
        actorRole: actorRole,
        targetType: targetType,
        targetId: targetId,
        title: title,
        subtitle: subtitle,
        metadata: metadata,
        createdAt: DateTime.now(),
      );
      final payload = {
        ...entry.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      // Diagnostic: surface the exact payload we are about to write
      // so we can verify the rule precondition (actorUid ==
      // auth.uid) is actually being satisfied. The rule at
      // firestore.rules `match /activityLogs/{logId}` denies the
      // write if these don't match — silent failure otherwise.
      AppLogger.debug(
        'ActivityLog write attempt: '
        'authUid=${FirebaseAuth.instance.currentUser?.uid} '
        'actorUid=$actorUid '
        'type=$type '
        'title=${title.substring(0, title.length.clamp(0, 40))}',
      );
      // Server-timestamp the createdAt so reads sort correctly even
      // when the client clock is off.
      await docRef.set(payload);
      return docRef.id;
    } catch (e) {
      AppLogger.warning('ActivityLog write failed: $e');
      return null;
    }
  }

  /// Most-recent N log entries, newest first. Drives the dashboard
  /// "Recent Activity" strip and the Logs screen.
  Stream<List<ActivityLogModel>> streamRecent({int limit = 25}) {
    if (!_isAvailable) return Stream.value(<ActivityLogModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed single-field `createdAt DESC` index is
      // available.
      return _firestore
          .collection(_collection)
          .limit(limit)
          .snapshots()
          .map((snap) {
        final list = <ActivityLogModel>[];
        for (final d in snap.docs) {
          try {
            final data = Map<String, dynamic>.from(d.data());
            // Coerce server-timestamp back to DateTime on read.
            final ts = data['createdAt'];
            if (ts is Timestamp) {
              data['createdAt'] = ts.toDate().toIso8601String();
            }
            list.add(ActivityLogModel.fromJson(data));
          } catch (e) {
            AppLogger.debug(
                'streamRecent: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming recent activity: $e');
      return Stream.value(<ActivityLogModel>[]);
    }
  }

  /// Stream entries filtered by [type]. The dashboard's filter
  /// chips use this.
  Stream<List<ActivityLogModel>> streamByType(String type) {
    if (!_isAvailable) return Stream.value(<ActivityLogModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(type, createdAt DESC)` composite index
      // is available.
      return _firestore
          .collection(_collection)
          .where('type', isEqualTo: type)
          .snapshots()
          .map((snap) {
        final list = <ActivityLogModel>[];
        for (final d in snap.docs) {
          try {
            final data = Map<String, dynamic>.from(d.data());
            final ts = data['createdAt'];
            if (ts is Timestamp) {
              data['createdAt'] = ts.toDate().toIso8601String();
            }
            list.add(ActivityLogModel.fromJson(data));
          } catch (e) {
            AppLogger.debug(
                'streamByType: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming activity by type $type: $e');
      return Stream.value(<ActivityLogModel>[]);
    }
  }

  /// Stream entries produced by a single actor (uid).
  Stream<List<ActivityLogModel>> streamByActor(String actorUid) {
    if (!_isAvailable) return Stream.value(<ActivityLogModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(actorUid, createdAt DESC)` composite
      // index is available.
      return _firestore
          .collection(_collection)
          .where('actorUid', isEqualTo: actorUid)
          .snapshots()
          .map((snap) {
        final list = <ActivityLogModel>[];
        for (final d in snap.docs) {
          try {
            final data = Map<String, dynamic>.from(d.data());
            final ts = data['createdAt'];
            if (ts is Timestamp) {
              data['createdAt'] = ts.toDate().toIso8601String();
            }
            list.add(ActivityLogModel.fromJson(data));
          } catch (e) {
            AppLogger.debug(
                'streamByActor: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming activity by actor: $e');
      return Stream.value(<ActivityLogModel>[]);
    }
  }
}
