import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json == null) {
      return DateTime.now(); // Fallback
    }
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.tryParse(json) ?? DateTime.now();
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    return DateTime.now();
  }

  @override
  dynamic toJson(DateTime object) {
    // We can just return Timestamp here, but if the rest of the codebase expects Strings,
    // we can return the ISO string, or rely on service overwrites with FieldValue.serverTimestamp().
    // Returning a Timestamp here ensures anything not overwritten is correctly formatted for Firestore.
    return Timestamp.fromDate(object);
  }
}

class OptionalTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const OptionalTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.tryParse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    return null;
  }

  @override
  dynamic toJson(DateTime? object) {
    if (object == null) return null;
    return Timestamp.fromDate(object);
  }
}
