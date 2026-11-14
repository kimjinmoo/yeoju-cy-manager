plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.grepiu.yeoju_cy_manager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.grepiu.yeoju_cy_manager"
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
            // R8 코드 난독화·최적화 및 미사용 리소스 축소를 명시적으로 활성화한다.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    lint {
        // Windows에서 Flutter CLI가 자동 생성하는 local.properties 경로의 콜론(:) 이스케이프 Lint 오탐을 무시한다.
        disable += "PropertyEscape"
        checkReleaseBuilds = false
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

// Release 빌드 시 --obfuscate / --split-debug-info 플래그가 생략되어도
// Dart AOT 코드 난독화와 디버그 심볼 분리가 항상 적용되도록 기본값을 강제한다.
// (FlutterPlugin이 afterEvaluate에서 task 속성을 초기화한 이후에 적용되도록 projectsEvaluated 사용)
gradle.projectsEvaluated {
    tasks.withType(com.flutter.gradle.tasks.FlutterTask::class.java).configureEach {
        if (buildMode == "release") {
            dartObfuscation = true
            if (splitDebugInfo.isNullOrBlank()) {
                splitDebugInfo = rootProject.layout.buildDirectory
                    .dir("app/outputs/symbols/android")
                    .get()
                    .asFile
                    .absolutePath
            }
        }
    }
}

// google-services.json이 추가되면 Firebase Google Services 플러그인을 자동 활성화한다.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
