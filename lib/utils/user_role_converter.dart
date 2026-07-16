// Safe JSON converter for [UserRole].
//
// Firestore contains legacy user documents with role strings that are
// no longer in the canonical enum (e.g. `'fisherman'` from the
// pre-rebrand era). The default Freezed / json_serializable decoder
// `$enumDecode` throws `ArgumentError` on those values, which
// crashes the admin "Manage Street Sellers" stream the moment the
// first legacy document is encountered.
//
// This converter accepts every legacy role string and silently
// maps it to a sensible fallback so the admin screen never breaks:
//   'fisherman'        → streetSeller  (closest semantic match)
//   'dalali'           → streetSeller  (alias used in older builds)
//   any other unknown  → streetSeller  (safest admin default)
//
// New writes always go through [UserRole.name], so this is a
// one-way forgiving read path — never a write path.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/enums/user_role.dart';

class UserRoleConverter implements JsonConverter<UserRole, dynamic> {
  const UserRoleConverter();

  // Legacy role strings → canonical enum. Read-only.
  static const Map<String, UserRole> _legacyAliases = {
    'fisherman': UserRole.streetSeller,
    'dalali': UserRole.streetSeller,
    'seller': UserRole.streetSeller,
    'fisherman_seller': UserRole.streetSeller,
  };

  @override
  UserRole fromJson(dynamic json) {
    if (json is UserRole) return json;
    final raw = json?.toString();
    if (raw == null || raw.isEmpty) {
      return UserRole.buyer; // app default
    }
    // 1. Try canonical enum first.
    for (final r in UserRole.values) {
      if (r.name == raw) return r;
    }
    // 2. Try the legacy alias map.
    final aliased = _legacyAliases[raw];
    if (aliased != null) return aliased;
    // 3. Fallback to a safe default so the stream never crashes.
    return UserRole.buyer;
  }

  @override
  String toJson(UserRole object) => object.name;
}
