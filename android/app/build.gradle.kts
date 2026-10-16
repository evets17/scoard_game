import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.scoardgame.scoard_game"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.scoardgame.scoard_game"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storePath = keyProperties.getProperty("storeFile")
                ?: throw GradleException(
                    "Missing Android signing config. Add android/key.properties with storeFile.",
                )
            val storePasswordValue = keyProperties.getProperty("storePassword")
                ?: throw GradleException(
                    "Missing Android signing config. Add storePassword in android/key.properties.",
                )
            val keyAliasValue = keyProperties.getProperty("keyAlias")
                ?: throw GradleException(
                    "Missing Android signing config. Add keyAlias in android/key.properties.",
                )
            val keyPasswordValue = keyProperties.getProperty("keyPassword")
                ?: throw GradleException(
                    "Missing Android signing config. Add keyPassword in android/key.properties.",
                )

            storeFile = rootProject.file(storePath)
            storePassword = storePasswordValue
            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
