plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ru.maxspeed.maxspeed_vpn"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "ru.maxspeed.maxspeed_vpn"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 18
        versionName = "1.4.6+18"
        ndk {
            abiFilters.add("arm64-v8a")
        }
    }

    splits {
        abi {
            isEnable = false
        }
        density {
            isEnable = false
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
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
