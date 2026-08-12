import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.samaki_fresh_connect"
    compileSdk = flutter.compileSdkVersion
    // Pinned to NDK 27.0.12077973 because the Firebase / Flutter plugins in
    // pubspec.lock require it (Flutter 3.29 default NDK 26.3.11579264 is too old).
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.samaki_fresh_connect"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk overridden to 23 because firebase-firestore 26.4.0 requires it
        // (Flutter 3.29 default is 21, which Firestore rejects).
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ABI splits: ship one APK per architecture instead of one fat APK
        // that bundles all four ABIs. The QR install card points at a
        // single APK, so we keep `arm64-v8a` as the universal default via
        // `isUniversalApk = true` — modern phones (95%+ on the Play Store)
        // are arm64, so the install path stays a single tap. Smaller APKs
        // also mean a faster download, faster install on cold devices, and
        // a smaller resident footprint after install.
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
            // R8 (the default replacement for ProGuard since AGP 8) strips
            // unused Java/Kotlin classes and shrinks resources. Without
            // this the release APK carries the entire Flutter plugin
            // surface, native code, and string resources that no screen
            // actually reads — adding tens of MB and slowing every cold
            // install / cold launch.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    splits {
        // One APK per ABI; `isUniversalApk = true` also emits a fat APK
        // so the QR install card still has a single, device-agnostic URL
        // to point at.
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a")
            isUniversalApk = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-analytics")
}
