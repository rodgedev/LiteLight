import java.util.Properties
import java.io.FileInputStream

// 1. Loading properties in Kotlin DSL
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.rodge.litelight"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.rodge.litelight"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2. Signing Configs in Kotlin DSL
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            val stFile = keystoreProperties["storeFile"] as String?
        storeFile = stFile?.let { rootProject.file(it) }
        
        storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            // 3. IMPORTANT: Link the release signing config here
            signingConfig = signingConfigs.getByName("release")
            
            // These are usually recommended for production:
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}