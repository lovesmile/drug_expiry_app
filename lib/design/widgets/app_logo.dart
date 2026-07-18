import 'package:flutter/material.dart';

/// 整 app 统一的品牌标识。
///
/// 同时复用在：launcher icon、Android adaptive foreground、原生 splash、
/// 隐私协议页 / Flutter _SplashScreen。所有显示位置都用同一个前景 PNG，
/// 容器用品牌蓝 (#2196F3) — 与桌面 / 启动器渲染保持一致。
class AppLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 72,
    this.backgroundColor = const Color(0xFF2196F3),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      // 前景 PNG 是 1024x1024，圆约占中间 50% 区域。pad ~16% 让圆到边缘
      // 留出和 launcher adaptive icon 类似的留白比例。
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(
        'assets/icon/app_icon_foreground.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
