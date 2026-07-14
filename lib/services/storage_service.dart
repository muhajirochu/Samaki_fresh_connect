import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/logger.dart';

class StorageService {
  StorageService._();

  /// Global handle. Set by [main] immediately after [init] resolves
  /// so providers (e.g. [themeControllerProvider]) can read/write
  /// before the rest of the widget tree builds.
  static StorageService? _instance;
  static StorageService get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
          'StorageService.instance accessed before init. Call init() first.');
    }
    return inst;
  }

  static Future<void> bootstrap() async {
    final s = StorageService._();
    await s.init();
    _instance = s;
  }

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('StorageService initialized');
  }

  // String methods
  Future<void> setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      AppLogger.debug('Stored string: $key');
    } catch (e) {
      AppLogger.error('Error storing string: $e');
      rethrow;
    }
  }

  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      AppLogger.error('Error reading string: $e');
      return null;
    }
  }

  // Int methods
  Future<void> setInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
      AppLogger.debug('Stored int: $key');
    } catch (e) {
      AppLogger.error('Error storing int: $e');
      rethrow;
    }
  }

  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      AppLogger.error('Error reading int: $e');
      return null;
    }
  }

  // Bool methods
  Future<void> setBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
      AppLogger.debug('Stored bool: $key');
    } catch (e) {
      AppLogger.error('Error storing bool: $e');
      rethrow;
    }
  }

  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      AppLogger.error('Error reading bool: $e');
      return null;
    }
  }

  // JSON methods
  Future<void> setJson(String key, Map<String, dynamic> json) async {
    try {
      await _prefs.setString(key, jsonEncode(json));
      AppLogger.debug('Stored JSON: $key');
    } catch (e) {
      AppLogger.error('Error storing JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? getJson(String key) {
    try {
      final json = _prefs.getString(key);
      if (json == null) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error reading JSON: $e');
      return null;
    }
  }

  // Remove
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
      AppLogger.debug('Removed: $key');
    } catch (e) {
      AppLogger.error('Error removing: $e');
      rethrow;
    }
  }

  // Clear all
  Future<void> clear() async {
    try {
      await _prefs.clear();
      AppLogger.info('Storage cleared');
    } catch (e) {
      AppLogger.error('Error clearing storage: $e');
      rethrow;
    }
  }
}
