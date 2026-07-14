import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/barcode_service.dart';
import '../l10n/app_localizations.dart';

class ScanResult {
  final String barcode;
  final BarcodeResult? lookup;

  ScanResult({required this.barcode, this.lookup});
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scanned = false;
  bool _torchOn = false;
  bool _lookingUp = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _lookingUp) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null || barcode!.rawValue!.isEmpty) return;

    _scanned = true;
    HapticFeedback.heavyImpact();

    setState(() => _lookingUp = true);

    final result = await BarcodeService.lookup(barcode.rawValue!);

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.pop(context, ScanResult(barcode: barcode.rawValue!, lookup: result));
    } else {
      // 查不到 → 让用户手动输入
      final manual = await _showManualDialog(barcode.rawValue!);
      if (manual == true && mounted) {
        Navigator.pop(context, ScanResult(barcode: barcode.rawValue!, lookup: result));
      } else if (mounted) {
        // 用户取消手动输入，返回扫码页
        setState(() {
          _scanned = false;
          _lookingUp = false;
        });
      }
    }
  }

  Future<bool?> _showManualDialog(String barcode) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('scan_not_found_title')),
        content: Text(ctx.tr('scan_not_found_body', {'barcode': barcode}),
            style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('skip'), style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(context.tr('scan_title')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: _lookingUp
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(context.tr('scan_looking_up'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  )
                : Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomPaint(painter: _ScanCornerPainter(color: Theme.of(context).colorScheme.primary)),
                  ),
          ),
          if (!_lookingUp)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 120,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 28),
                  const SizedBox(height: 8),
                  Text(context.tr('scan_guide'),
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanCornerPainter extends CustomPainter {
  final Color color;
  _ScanCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLen = 24.0;

    canvas.drawLine(Offset(0, cornerLen), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerLen, 0), paint);
    canvas.drawLine(Offset(size.width - cornerLen, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), paint);
    canvas.drawLine(Offset(0, size.height - cornerLen), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawLine(Offset(size.width - cornerLen, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLen), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
