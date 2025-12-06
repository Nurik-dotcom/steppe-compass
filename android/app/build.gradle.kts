// Импортируем классы, необходимые для чтения паролей
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// <-- ШАГ 1: КОД ДЛЯ ЧТЕНИЯ key.properties (версия Kotlin)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.steppecompass.kazakhstan_travel"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.steppecompass.kazakhstan_travel"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    // <-- ШАГ 2: ДОБАВЬТЕ ЭТОТ БЛОК (версия Kotlin)
    signingConfigs {
        // Мы создаем новую конфигурацию подписи с именем "release"
        create("release") {
            if (keystoreProperties.containsKey("storeFile")) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            // <-- ШАГ 3: ИЗМЕНИТЕ ЭТУ СТРОКУ (версия Kotlin)
            // Мы говорим, что "release" сборка должна использовать
            // "release" подпись (а не "debug")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter { source = "../.." }
