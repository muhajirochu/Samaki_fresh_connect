# R8 / ProGuard rules for Samaki Fresh Connect release builds.
#
# The Flutter Gradle plugin already supplies keep rules for the Flutter
# embedding (io.flutter.**). The rules below are the extras we need so
# R8's whole-program optimisation doesn't break Firebase, Riverpod,
# flutter_local_notifications, qr_flutter, or reflection-based plugins
# during the install / first-launch path.
#
# Rule philosophy: keep only the entry points reflection / JNI look up.
# Everything else is fair game for R8 to rename, inline, or drop. That
# is what makes the release APK meaningfully smaller and the cold
# install measurably faster than a debug build.

# ── Flutter ────────────────────────────────────────────────────────────────
# The embedding is already covered by the Flutter Gradle plugin's
# bundled rules, but be explicit so a future plugin upgrade that drops
# those rules doesn't silently break the app.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Firebase ───────────────────────────────────────────────────────────────
# Firebase initialises via reflection and uses some classes that R8
# can't see referenced from the manifest. Without these, the first
# Firebase call post-install throws ClassNotFoundException and the app
# falls back to offline mode.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod
-keepattributes SourceFile, LineNumberTable

# ── Firestore POJO deserialisation ─────────────────────────────────────────
# Firestore serialises freezed / json_serializable generated classes by
# walking the field graph reflectively. Keep generated names so the
# field-name lookups still match the wire format after R8 renames them.
-keepclassmembers class **$$serializer { *; }
-keepclassmembers class * extends com.google.cloud.firestore.PropertyName { *; }
-keep class com.google.cloud.firestore.** { *; }
-dontwarn com.google.cloud.firestore.**

# ── flutter_local_notifications ───────────────────────────────────────────
# Receivers are declared in the manifest but instantiated by the
# notification system via reflection on launch.
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# ── qr_flutter ────────────────────────────────────────────────────────────
# Pure Dart; the keep rule is here only to guard against future native
# additions.
-keep class net.touchcapture.qr.** { *; }
-dontwarn net.touchcapture.qr.**

# ── share_plus / printing / pdf ────────────────────────────────────────────
# Share and printing both use platform channels + reflection to find
# Android system activities.
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# ── General ───────────────────────────────────────────────────────────────
# Native methods must keep their declared names so JNI can find them.
-keepclasseswithmembernames class * {
    native <methods>;
}

# Parcelable creators are looked up via reflection by the platform.
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Enums are sometimes valueOf'd by name (Firebase custom claims, locale
# resolution, etc.).
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
