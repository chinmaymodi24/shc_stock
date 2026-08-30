import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.shc_stock"
    compileSdk = flutter.compileSdkVersion
    // Several plugins (file_picker, desktop_drop, flutter_secure_storage, …) ask
    // for 27.x, which is backward compatible with the Flutter default.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.shc_stock"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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
}

flutter {
    source = "../.."
}

// ── Local backend tunnel ────────────────────────────────────────────────────
// Every debug build runs `adb reverse tcp:4000 tcp:4000`, so the app's
// http://localhost:4000 (see lib/app/core/api/api_config.dart) reaches the dev
// machine's backend — on the emulator AND on a USB-connected physical phone,
// and it re-runs on every launch so a replug/reboot never breaks it.
//
// The reverse is set for EVERY attached device, one `adb -s <serial>` call each.
// A bare `adb reverse` fails with "more than one device/emulator" the moment a
// phone and an emulator are both plugged in, and the failure is swallowed — so
// the phone silently got no tunnel and every API call from it, login included,
// died on a refused connection.
val adbReverseBackendPort by tasks.registering {
    val sdkDir: String? = Properties().run {
        val f = rootProject.file("local.properties")
        if (f.exists()) f.inputStream().use { load(it) }
        getProperty("sdk.dir")
    } ?: System.getenv("ANDROID_HOME") ?: System.getenv("ANDROID_SDK_ROOT")
    val adbName = if (System.getProperty("os.name").lowercase().contains("win")) "adb.exe" else "adb"
    val adb = if (sdkDir != null) File(sdkDir, "platform-tools/$adbName").absolutePath else adbName

    onlyIf { File(adb).exists() }          // no SDK on this machine → skip, don't fail
    outputs.upToDateWhen { false }         // always re-run

    doLast {
        // Serials of everything currently in the `device` state — offline and
        // unauthorized entries are skipped, since adb can't reach those anyway.
        val serials = try {
            ProcessBuilder(adb, "devices")
                .redirectErrorStream(true)
                .start()
                .inputStream.bufferedReader().readLines()
                .drop(1)
                .mapNotNull { line ->
                    val parts = line.trim().split(Regex("\\s+"))
                    if (parts.size >= 2 && parts[1] == "device") parts[0] else null
                }
        } catch (e: Exception) {
            emptyList()
        }

        for (serial in serials) {
            // A device unplugged mid-build must not fail the build.
            try {
                ProcessBuilder(adb, "-s", serial, "reverse", "tcp:4000", "tcp:4000")
                    .redirectErrorStream(true)
                    .start()
                    .waitFor()
            } catch (e: Exception) {
                logger.lifecycle("adb reverse failed for $serial: ${e.message}")
            }
        }
    }
}

tasks.matching { it.name == "preDebugBuild" }.configureEach {
    dependsOn(adbReverseBackendPort)
}
