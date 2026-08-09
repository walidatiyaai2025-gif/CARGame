import java.util.Properties
import org.gradle.api.GradleException
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

val googleTestAdMobApplicationId = "ca-app-pub-3940256099942544~3347511713"
val allowTestAdsInRelease =
    providers.environmentVariable("ALLOW_TEST_ADS_IN_RELEASE").orNull?.trim()
        ?.equals("true", ignoreCase = true) == true
val releaseAdMobApplicationId =
    providers.environmentVariable("ADMOB_ANDROID_APP_ID").orNull?.trim().orEmpty()

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use(signingProperties::load)
}

fun signingValue(propertyName: String, environmentName: String): String =
    providers.environmentVariable(environmentName).orNull?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: signingProperties.getProperty(propertyName)?.trim().orEmpty()

val releaseStorePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val hasCompleteReleaseSigning = listOf(
    releaseStorePath,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { it.isNotBlank() }

android {
    namespace = "com.walka.cargosort"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.walka.cargosort"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobApplicationId"] = googleTestAdMobApplicationId
    }

    if (hasCompleteReleaseSigning) {
        signingConfigs.create("release") {
            storeFile = file(releaseStorePath)
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        release {
            manifestPlaceholders["admobApplicationId"] = releaseAdMobApplicationId
            if (hasCompleteReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val validateReleaseConfiguration = tasks.register("validateReleaseConfiguration") {
    doLast {
        if (releaseAdMobApplicationId.isBlank()) {
            throw GradleException(
                "ADMOB_ANDROID_APP_ID is required for Android release builds.",
            )
        }
        val usesGoogleTestAdMobApplicationId =
            releaseAdMobApplicationId == googleTestAdMobApplicationId ||
                releaseAdMobApplicationId.startsWith("ca-app-pub-3940256099942544~")
        if (usesGoogleTestAdMobApplicationId && !allowTestAdsInRelease) {
            throw GradleException(
                "Google test AdMob application IDs are forbidden in Android release builds. " +
                    "Set ALLOW_TEST_ADS_IN_RELEASE=true only for explicit test release builds.",
            )
        }
        if (!hasCompleteReleaseSigning) {
            throw GradleException(
                "Android release signing is incomplete. Provide android/key.properties " +
                    "or ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, " +
                    "ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD.",
            )
        }
        val store = file(releaseStorePath)
        if (!store.isFile) {
            throw GradleException("Android release keystore was not found: ${store.absolutePath}")
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateReleaseConfiguration)
}

flutter {
    source = "../.."
}
