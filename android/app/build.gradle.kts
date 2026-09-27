import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKeystore) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

// A release artifact must never be signed with the debug key: Play Store rejects
// debug-signed uploads, and anything that slipped through could not be updated by
// a properly signed build afterwards. So fail the build loudly instead of falling
// back to debug keys. Debug builds still work without key.properties.
val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.substringAfterLast(':').contains("release", ignoreCase = true)
}
if (releaseBuildRequested && !hasReleaseKeystore) {
    throw GradleException(
        """
        Refusing to build a release artifact: android/key.properties is missing.

        key.properties and the keystore are deliberately untracked (see android/.gitignore),
        so they must be provided on every machine that produces release builds, CI included.
        Create android/key.properties with:

            storePassword=<upload keystore password>
            keyPassword=<upload key password>
            keyAlias=upload
            storeFile=upload-keystore.jks

        storeFile is resolved relative to android/app/. See https://flutter.dev/to/reference-keystore
        """.trimIndent()
    )
}

android {
    namespace = "com.loyalty.rewardhub"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.loyalty.rewardhub"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only declared when the real keystore is available, so there is no
        // half-configured "release" config that could silently produce an
        // unsigned or debug-signed artifact.
        if (hasReleaseKeystore) {
            create("release") {
                fun required(key: String): String =
                    (keystoreProperties[key] as String?)?.takeIf { it.isNotBlank() }
                        ?: throw GradleException("android/key.properties is missing a value for '$key'.")

                keyAlias = required("keyAlias")
                keyPassword = required("keyPassword")
                storePassword = required("storePassword")
                storeFile = file(required("storeFile")).also {
                    if (!it.exists()) {
                        throw GradleException(
                            "Upload keystore not found at ${it.absolutePath} " +
                                "(storeFile in android/key.properties, resolved relative to android/app/)."
                        )
                    }
                }
            }
        }
    }

    buildTypes {
        release {
            // Null only when key.properties is absent, which the check above already
            // rejects for release builds — never a debug-key fallback.
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
