import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _supported = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck && !isDeviceSupported) {
        setState(() {
          _supported = false;
          _error = '此设备不支持指纹或面容识别';
        });
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: '请验证身份以解锁应用',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) {
        if (authenticated) {
          Navigator.pop(context, true);
        } else {
          setState(() => _error = '验证失败，请重试');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _supported = false;
          _error = '验证出错：$e';
        });
      }
    }
  }

  void _skip() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.brandSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.lock_outline, size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 32),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.statusError, fontSize: 14),
                ),
              )
            else
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 48),
            if (!_supported)
              FilledButton(
                onPressed: _skip,
                child: Text(context.tr('lock_enter')),
              ),
          ],
        ),
      ),
    );
  }
}
