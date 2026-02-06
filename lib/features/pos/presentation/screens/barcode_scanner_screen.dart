import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';

/// 바코드 스캔 전용 화면 (전체 화면 카메라)
/// 스캔 완료 시 Navigator.pop(context, barcodeValue) 로 결과 반환
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isDetected = false;

  // ─── 스캔 라인 스크롤 아니메이션 ──────────
  late final AnimationController _scanAnimController;
  late final Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scanAnimation = _scanAnimController;
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 바코드 감지 핸들러
  void _handleDetect(BarcodeCapture capture) {
    if (_isDetected) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.displayValue != null) {
      setState(() => _isDetected = true);
      _scanAnimController.stop();

      // 감지 시각 피드백 후 결과를 Navigator.pop으로 반환
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.pop(context, barcode!.displayValue!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double scanW = 240;
    const double scanH = 160;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 카메라 뷰 ──────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),

          // ── 어두운 오버레이 (스캔 영역 제외) ────
          ClipPath(
            clipper: _ScanOverlayClipper(),
            child: const ColoredBox(color: Color(0x99000000)),
          ),

          // ── 스캔 프레임 (중앙 — 네 모서리 + 스캔 라인) ──
          Center(
            child: SizedBox(
              width: scanW,
              height: scanH,
              child: Stack(
                children: [
                  // 네 모서리 프레임
                  CustomPaint(
                    painter: _ScanFramePainter(detected: _isDetected),
                    child: const SizedBox.expand(),
                  ),
                  // 스캔 라인 (감지 완료 전에만 표시)
                  if (!_isDetected)
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) => Positioned(
                        top: _scanAnimation.value * (scanH - 3),
                        left: 0,
                        right: 0,
                        height: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.success.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── 상단 앱바 (닫기) ───────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              title: const Text(
                '바코드 스캔',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),

          // ── 하단 안내 텍스트 ──────────────────
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isDetected ? '바코드 감지됨!' : '바코드를 프레임 안에 놓아주세요',
                style: TextStyle(
                  color: _isDetected ? AppTheme.success : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// 그래픽 헬퍼 클래스들
// ────────────────────────────────────────────────────────

/// 전체 화면 오버레이에서 중앙 스캔 영역을 구멍으로 만드는 클리퍼
/// PathFillType.evenOdd 규칙으로 내부 사각형을 투명으로 처리
class _ScanOverlayClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..fillType = PathFillType.evenOdd;

    // 외부: 전체 화면
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 내부: 중앙 스캔 영역 (구멍)
    const double scanW = 240;
    const double scanH = 160;
    final double left = (size.width - scanW) / 2;
    final double top = (size.height - scanH) / 2;
    path.addRRect(
      RRect.fromLTRBR(
        left, top, left + scanW, top + scanH,
        const Radius.circular(8),
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 스캔 프레임의 네 모서리 그리기 (L 자형 꼭짓점)
class _ScanFramePainter extends CustomPainter {
  final bool detected;
  _ScanFramePainter({this.detected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = detected ? AppTheme.success : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double len = 24;

    // 왼쪽 상단 ╔
    canvas.drawPath(
      Path()..moveTo(len, 0)..lineTo(0, 0)..lineTo(0, len),
      paint,
    );
    // 오른쪽 상단 ╗
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );
    // 왼쪽 하단 ╚
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height)
        ..lineTo(len, size.height),
      paint,
    );
    // 오른쪽 하단 ╝
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - len)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - len, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) {
    return oldDelegate.detected != detected;
  }
}
