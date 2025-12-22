plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.elearning.elearning_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Required by Jitsi Meet and other plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.elearning.elearning_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // Required by Jitsi Meet SDK 11.6.0
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    packaging {
        resources {
            // Pick first occurrence of duplicate classes to resolve conflicts
            // between video_player and jitsi_meet_flutter_sdk
            pickFirsts += "**/libc++_shared.so"
            pickFirsts += "**/libfbjni.so"
        }
    }
    
    // Exclude duplicate media3-exoplayer-rtsp from react-native-video (via jitsi)
    configurations.all {
        exclude(group = "androidx.media3", module = "media3-exoplayer-rtsp")
    }
}

flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
        // Force a specific version to resolve duplicate class conflicts
        // between video_player and jitsi_meet_flutter_sdk
        force("androidx.media3:media3-exoplayer-rtsp:1.5.1")
    }
}
