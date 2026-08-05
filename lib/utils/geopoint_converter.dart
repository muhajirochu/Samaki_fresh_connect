import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class GeoPointConverter implements JsonConverter<GeoPoint?, dynamic> {
  const GeoPointConverter();

  @override
  GeoPoint? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is GeoPoint) return json;
    if (json is Map<String, dynamic>) {
      if (json['latitude'] != null && json['longitude'] != null) {
        return GeoPoint(json['latitude'] as double, json['longitude'] as double);
      }
    }
    return null;
  }

  @override
  dynamic toJson(GeoPoint? object) {
    if (object == null) return null;
    return object; // Firestore handles GeoPoint directly
  }
}
