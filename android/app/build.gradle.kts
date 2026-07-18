import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties
val keystoreProps = Properties()
val keystorePropsFile = rootProject.file("key.properties")
if (keystorePropsFile.exists()) {
    keystoreProps.load(FileInputStream(keystorePropsFile))
}

android {
    namespace = "com.lovesmile.expiry"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.lovesmile.expiry"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val storePath = keystoreProps["storeFile"] as? String
    signingConfigs {
        create("release") {
            keyAlias = keystoreProps["keyAlias"] as? String ?: ""
            keyPassword = keystoreProps["keyPassword"] as? String ?: ""
            storeFile = if (storePath != null) rootProject.file(storePath) else null
            storePassword = keystoreProps["storePassword"] as? String ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // 复用 flutter_local_notifications 模型类默认的 keep 规则；
            // 不加的话 release 包 R8 会擦掉 Gson 需要的泛型签名，
            // rescheduleFromDb() 走 cancelAll() 时抛 "Missing type parameter"，
            // 进而让备份导入主流程误判为导入失败。
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // Android 12+ SplashScreen API 依赖；不加的话 values-v31/values-night-v31 引用
    // style/Theme.SplashScreen 和 attr/postSplashScreenTheme 会 link 失败
    implementation("androidx.core:core-splashscreen:1.0.1")
}

flutter {
    source = "../.."
}

// Release 构建可使用默认 `flutter build appbundle --release`，不再需要
// `--no-tree-shake-icons`：Item.icon / add_edit_item_screen 里 14 个
// 用户可选图标都已收进 const List<IconData>，AOT 编译期能完整静态分析，
// MaterialIcons 字体被 tree-shake 99% 以上（1.6MB → 13KB）。
//
// 注：NDK 28 + AGP 组合下，bundleRelease 末尾 AGP 调 llvm-strip 会以
// non-zero exit 退出并打印 "failed to strip debug symbols"，但 AAB 产物
// 实际已完整生成（包含全部 .so）；只是 .so 内 debug 符号未剥离，
// AAB 体积比优化后大约多几 MB。功能不受影响，可直接上传 Play Console。
