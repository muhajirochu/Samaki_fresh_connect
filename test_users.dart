import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'lib/models/user_model.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // HARD FIX: bind Firestore to the local emulator. Without this,
  // the script talks to the production Firebase project, which
  // returns 0 users (the demo data lives in the emulator).
  final isAndroid = defaultTargetPlatform == TargetPlatform.android;
  final host = isAndroid ? '10.0.2.2' : '127.0.0.1';
  try {
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    developer.log('Firestore bound to emulator at $host:8080');
  } catch (e) {
    developer.log('Could not bind Firestore emulator: $e');
  }

  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  developer.log('Total users in DB: ${snapshot.docs.length}');

  int success = 0;
  int failed = 0;

  for (final doc in snapshot.docs) {
    try {
      final data = Map<String, dynamic>.from(doc.data());
      data['userId'] = data['userId'] ?? doc.id;
      final user = UserModel.fromJson(data);
      // Log the parsed user so the script doubles as a doc-shape
      // diagnostic (the previous version silently swallowed the
      // parsed model).
      developer.log('  - ${user.email} (${user.role.name})');
      success++;
    } catch (e) {
      developer.log('Failed on doc ${doc.id}: $e');
      failed++;
    }
  }
  developer.log('Success: $success, Failed: $failed');
}
