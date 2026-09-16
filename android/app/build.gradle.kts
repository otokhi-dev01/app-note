import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (!keystorePropertiesFile.exists()) {
    throw GradleException(
        "key.properties not found: ${keystorePropertiesFile.absolutePath}"
    )
}

keystoreProperties.load(FileInputStream(keystorePropertiesFile))

android {
    namespace = "com.kimchheang.pii_note"

    // permission_handler_android requires Android SDK 37+
    compileSdk = 37

    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.kimchheang.pii_note"

        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = 2
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file(
                keystoreProperties["storeFile"].toString()
            )
            storePassword = keystoreProperties["storePassword"].toString()
            keyAlias = keystoreProperties["keyAlias"].toString()
            keyPassword = keystoreProperties["keyPassword"].toString()
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Bundled Latin-script OCR model
    implementation("com.google.mlkit:text-recognition:16.0.1")
}