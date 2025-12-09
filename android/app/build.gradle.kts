// File: android/app/build.gradle.kts (Sintaks Kotlin)

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.eventku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8 
        targetCompatibility = JavaVersion.VERSION_1_8 
        
        // 🔑 Mengaktifkan Core Library Desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    // 🔑 PERBAIKAN: Sinkronkan JVM Target Kotlin menjadi 1.8
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString() 
    }

    defaultConfig {
        applicationId = "com.example.eventku"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 💡 Implementasi desugaring library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}