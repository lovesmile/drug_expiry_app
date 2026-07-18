package com.lovesmile.expiry

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // 必须在 super.onCreate 之前调用。
        val splashScreen = installSplashScreen()
        // 关掉系统默认的退出动画（icon 缩到角落 + 暗色 scrim），
        // 让 native splash 在 Flutter 第一帧 ready 时直接 remove。
        splashScreen.setOnExitAnimationListener { it.remove() }
        super.onCreate(savedInstanceState)
    }
}