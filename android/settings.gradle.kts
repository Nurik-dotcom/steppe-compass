// android/settings.gradle.kts

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // Подхватываем путь к Flutter SDK из local.properties
    val props = java.util.Properties()
    val local = file("local.properties")
    if (local.exists()) local.inputStream().use { props.load(it) }
    val flutterSdk = props.getProperty("flutter.sdk")
        ?: throw GradleException("flutter.sdk not set in local.properties")

    // Подключаем flutter_tools, чтобы плагин Flutter был на classpath
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")

    // (опционально) если используешь приватные/командные репозитории, добавляй их здесь
}

plugins {
    // Flutter loader (корневой плагин; НЕ gradle-plugin)
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Версии AGP/Kotlin объявляем один раз на верхнем уровне
    id("com.android.application") version "8.2.0" apply false
    id("com.android.library") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false

    // Google Services (Firebase) — главное: объявляем версию здесь
    id("com.google.gms.google-services") version "4.4.2" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // Репозиторий с артефактами движка Flutter
        maven("https://storage.googleapis.com/download.flutter.io")
    }
}

include(":app")
