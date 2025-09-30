plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

// Fungsi untuk membaca file local.properties
fun readProperties(file: java.io.File): Properties {
    val properties = Properties()
    if (file.exists()) {
        file.reader().use { reader ->
            properties.load(reader)
        }
    }
    return properties
}

// Baca properti dari file
val localProperties = readProperties(rootProject.file("local.properties"))

// Ambil nilai dengan memberikan nilai default jika tidak ditemukan
val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

// ----------------------------------------------------------------

android {
    namespace = "com.example.flutter_application_2"
    compileSdk = flutter.compileSdkVersion
    
    // --- PERBAIKAN: Gunakan versi NDK yang spesifik ---
    ndkVersion = "27.0.12077973"
    // ---------------------------------------------

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.flutter_application_2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
