// lib/screens/liveness_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  CameraController? _controller;
  late FaceDetector _faceDetector;
  bool _processing = false;
  bool _initialized = false;
  double _progress = 0.0;

  // Active liveness steps: ask user to turn left then right (or vice versa).
  final List<_Action> _required = [_Action.turnLeft, _Action.turnRight];
  int _currentIndex = 0;

  String get _instruction {
    if (!_faceVisible) return 'Align your face in the circle';
    if (_currentIndex >= _required.length) return 'Done';
    switch (_required[_currentIndex]) {
      case _Action.turnLeft:
        return 'Turn your head a bit to the left';
      case _Action.turnRight:
        return 'Turn your head a bit to the right';
    }
  }

  bool _faceVisible = false;
  final List<double> _yawHistory = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }

    final cameras = await availableCameras();
    final front = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );

    setState(() => _initialized = true);

    await _controller!.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || !_initialized) return;
    _processing = true;

    try {
      final inputImage = _toInputImage(image, _controller!.description);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        setState(() {
          _faceVisible = false;
        });
        return;
      }

      final face = faces.first;
      setState(() => _faceVisible = true);

      final yaw = face.headEulerAngleY;
      if (yaw != null) {
        _yawHistory.add(yaw);
        if (_yawHistory.length > 24) _yawHistory.removeAt(0);
        _evaluateYaw();
      }
    } catch (_) {
    } finally {
      _processing = false;
    }
  }

  void _evaluateYaw() {
    if (_currentIndex >= _required.length) return;
    if (_yawHistory.isEmpty) return;
    final minYaw = _yawHistory.reduce(min);
    final maxYaw = _yawHistory.reduce(max);

    const leftThreshold = -12.0;
    const rightThreshold = 12.0;

    final target = _required[_currentIndex];
    bool satisfied = false;

    switch (target) {
      case _Action.turnLeft:
        satisfied = minYaw <= leftThreshold;
        break;
      case _Action.turnRight:
        satisfied = maxYaw >= rightThreshold;
        break;
    }

    if (satisfied) {
      HapticFeedback.selectionClick();
      _currentIndex++;
      _yawHistory.clear();
      final p = _currentIndex / _required.length;
      setState(() => _progress = p.clamp(0.0, 1.0));

      if (_currentIndex >= _required.length) {
        _onComplete();
      }
    } else {
      double proximity;
      if (target == _Action.turnLeft) {
        proximity = (0.0 - (minYaw / leftThreshold)).clamp(0.0, 1.0);
      } else {
        proximity = ((maxYaw / rightThreshold)).clamp(0.0, 1.0);
      }
      final base = _currentIndex / _required.length;
      final perStep = 1.0 / _required.length;
      setState(() => _progress = (base + proximity * perStep).clamp(0.0, 1.0));
    }
  }

  void _onComplete() async {
    try {
      await _controller?.stopImageStream();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Liveness check complete')),
    );
    Navigator.of(context).pop(true);
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription description) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

      return InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _rotationFromSensor(description.sensorOrientation, description),
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final p in planes) {
      allBytes.putUint8List(p.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation, CameraDescription d) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
      default:
        return InputImageRotation.rotation270deg;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: !_initialized
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _CircularLivenessViewport(
                  controller: _controller!,
                  ringProgress: _progress,
                  faceDetected: _faceVisible,
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close, color: Colors.black87),
                tooltip: 'Close',
              ),
            ),
            Align(
              alignment: Alignment(0, 0.45),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                    children: const [
                      TextSpan(text: 'Powered by '),
                      TextSpan(
                        text: 'Regula',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A46FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Action { turnLeft, turnRight }

class _CircularLivenessViewport extends StatelessWidget {
  final CameraController controller;
  final double ringProgress; // 0..1
  final bool faceDetected;

  const _CircularLivenessViewport({
    required this.controller,
    required this.ringProgress,
    required this.faceDetected,
  });

  @override
  Widget build(BuildContext context) {
    final double diameter = MediaQuery.of(context).size.width * 0.78;
    final double ringThickness = 10;

    return SizedBox(
      width: diameter,
      height: diameter + 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Positioned.fill(
          //   child: IgnorePointer(
          //     child: CustomPaint(
          //       painter: _AccentPainter(),
          //     ),
          //   ),
          // ),
          Center(
            child: ClipOval(
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: CameraPreview(controller),
              ),
            ),
          ),

          // Purple ring + progress + top tab
          Center(
            child: CustomPaint(
              size: Size(diameter, diameter),
              painter: _RingPainter(
                progress: ringProgress,
                thickness: ringThickness,
                activeColor1: const Color(0xFF9B5CFF),
                activeColor2: const Color(0xFF6A3BFF),
                idleColor: Colors.white,
              ),
            ),
          ),
          // Positioned(
          //   right: max(0.0, (MediaQuery.of(context).size.width - diameter) / 2 - 12),
          //   bottom: 12,
          //   child: _Badge(
          //     icon: faceDetected ? Icons.check_rounded : Icons.camera_alt_rounded,
          //     background: faceDetected ? const Color(0xFF2ECC71) : const Color(0xFF4C69FF),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double thickness;
  final Color activeColor1;
  final Color activeColor2;
  final Color idleColor;

  _RingPainter({
    required this.progress,
    required this.thickness,
    required this.activeColor1,
    required this.activeColor2,
    required this.idleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    final base = Paint()
      ..color = idleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawCircle(center, radius - thickness / 2, base);

    if (progress > 0) {
      final sweep = 2 * pi * progress;
      final gradient = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweep,
        colors: [activeColor1, activeColor2],
      );
      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = thickness;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - thickness / 2),
        -pi / 2,
        sweep,
        false,
        progressPaint,
      );
    }

    final tabWidth = size.width * 0.16;
    final tabHeight = thickness * 1.2;
    final tabRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius - tabHeight / 2 + thickness / 2),
      width: tabWidth,
      height: tabHeight,
    );
    final tabPath = Path()
      ..moveTo(tabRect.left, tabRect.bottom)
      ..lineTo(tabRect.left + 10, tabRect.top)
      ..lineTo(tabRect.right - 10, tabRect.top)
      ..lineTo(tabRect.right, tabRect.bottom)
      ..close();

    final tabPaint = Paint()..color = const Color(0xFF7D4BFF);
    canvas.drawPath(tabPath, tabPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.progress != progress;
  }
}

class _AccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1A7D4BFF);
    final w = size.width;
    final h = size.height;
    final path1 = Path()
      ..moveTo(w * 0.1, h * 0.65)
      ..lineTo(w * 0.23, h * 0.5)
      ..lineTo(w * 0.34, h * 0.72)
      ..close();

    final path2 = Path()
      ..moveTo(w * 0.75, h * 0.3)
      ..lineTo(w * 0.88, h * 0.2)
      ..lineTo(w * 0.9, h * 0.38)
      ..close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color background;
  const _Badge({required this.icon, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
