import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/pages/scanned_user_profile.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _isProcessing = false;
  String? _errorMessage;
  String? _lastScannedCode;
  DateTime? _lastScanAt;

  static const _rescanCooldown = Duration(milliseconds: 1200);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetScannerSession() {
    _lastScannedCode = null;
    _lastScanAt = null;
    _isProcessing = false;
    _errorMessage = null;
  }

  Future<void> _resumeScanning() async {
    if (!mounted) return;
    _resetScannerSession();
    setState(() {});
    try {
      await _controller.start();
    } catch (_) {
      // Controller may already be running; safe to ignore.
    }
  }

  Future<void> _handleCode(String code) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    if (_lastScannedCode == code &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < _rescanCooldown) {
      return;
    }

    if (!code.startsWith('PA-')) {
      setState(() => _errorMessage = 'Invalid QR code');
      return;
    }

    _lastScannedCode = code;
    _lastScanAt = now;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _controller.stop();

      final profiles = await sl<CoachRepository>().getUserByQrCode(code);
      if (!mounted) return;

      if (profiles.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid QR code';
          _isProcessing = false;
        });
        await _controller.start();
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScannedUserProfilePage(qrCode: code),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isProcessing = false;
      });
      await _controller.start();
    }
  }

  void _retry() {
    _resumeScanning();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final code = barcodes.first.rawValue;
              if (code == null || code.isEmpty) return;
              _handleCode(code);
            },
          ),
          _ScannerOverlay(errorMessage: _errorMessage),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Scan Member QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                if (_errorMessage != null)
                  _ErrorBanner(
                    message: _errorMessage!,
                    onRetry: _retry,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Text(
                      'Align QR code within the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ViewfinderPainter(
          hasError: errorMessage != null,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter({required this.hasError});

  final bool hasError;

  @override
  void paint(Canvas canvas, Size size) {
    const viewfinderSize = 250.0;
    final left = (size.width - viewfinderSize) / 2;
    final top = (size.height - viewfinderSize) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, viewfinderSize, viewfinderSize),
      const Radius.circular(16),
    );

    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final holePath = Path()
      ..addRect(fullRect)
      ..addRRect(rect);
    holePath.fillType = PathFillType.evenOdd;
    canvas.drawPath(holePath, overlayPaint);

    final borderPaint = Paint()
      ..color = hasError ? const Color(0xFFD32F2F) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.hasError != hasError;
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD32F2F)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColorConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
