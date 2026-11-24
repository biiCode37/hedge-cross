plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
android {
    namespace = "id.mikrotrans.hedge.hedge_flutter"
    compileSdk = 36
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = "id.mikrotrans.hedge.hedge_flutter"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("hedgeRelease") {
            storeFile = file("hedge_debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
    buildTypes {
        release {
            // Mengunci keystore resmi ber-SHA-1 terdaftar di Google Cloud Console
            signingConfig = signingConfigs.getByName("hedgeRelease")
        }
        debug {
            signingConfig = signingConfigs.getByName("hedgeRelease")
        }
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    testImplementation("junit:junit:4.13.2")
}
flutter { source = "../.." }
