import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
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

enum _LivenessState {
  faceAlignment,
  holdStill,
  livenessChallenge,
  done,
}

class _LivenessScreenState extends State<LivenessScreen> {
  CameraController? _controller;
  late FaceDetector _faceDetector;
  bool _processing = false;
  bool _initialized = false;
  double _progress = 0.0;

  // Expanded list of actions
  final List<_Action> _required = [];
  int _currentIndex = 0;
  _LivenessState _livenessState = _LivenessState.faceAlignment;
  String _instruction = 'Align your face in the circle';

  String? _capturedImagePath;
  Timer? _holdStillTimer;

  @override
  void initState() {
    super.initState();
    // Now selects 4 random challenges
    final allActions = [
      _Action.turnLeft,
      _Action.turnRight,
      _Action.turnUp,
      _Action.turnDown,
      _Action.smile,
      _Action.blink,
    ];
    allActions.shuffle();
    _required.addAll(allActions.take(4));
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
      orElse: () => throw Exception("No front camera found"),
    );

    _controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.2,
        enableClassification: true, // Required for smile and blink detection
      ),
    );

    setState(() => _initialized = true);
    await _controller!.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing) return;
    _processing = true;

    try {
      final inputImage = _toInputImage(image, _controller!.description);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      if (faces.isEmpty) {
        _resetToFaceAlignment('Align your face in the circle');
        return;
      }

      final face = faces.first;
      
      switch (_livenessState) {
        case _LivenessState.faceAlignment:
        case _LivenessState.holdStill:
          _handleFaceAlignment(face, image);
          break;
        case _LivenessState.livenessChallenge:
          _evaluateLivenessAction(face);
          break;
        case _LivenessState.done:
          break;
      }
    } catch (e, s) {
      dev.log('Error during face processing', error: e, stackTrace: s);
    } finally {
      _processing = false;
    }
  }

  void _handleFaceAlignment(Face face, CameraImage image) {
    if (_isFaceWellPositioned(face, image)) {
      if (_livenessState == _LivenessState.faceAlignment) {
        setState(() {
          _livenessState = _LivenessState.holdStill;
          _instruction = 'Hold still...';
        });
        _holdStillTimer?.cancel();
        _holdStillTimer = Timer(const Duration(milliseconds: 1500), _captureAndProceed);
      }
    } 
  }

  bool _isFaceWellPositioned(Face face, CameraImage image, {bool updateInstruction = true}) {
      final imageWidth = image.width;
      final faceWidth = face.boundingBox.width;

      final faceCenterX = face.boundingBox.center.dx;
      final isCentered = (faceCenterX > imageWidth * 0.25) && (faceCenterX < imageWidth * 0.75);

      if (faceWidth < imageWidth * 0.35) {
        if (updateInstruction) _setInstruction('Move closer');
        return false;
      } else if (faceWidth > imageWidth * 0.6) {
        if (updateInstruction) _setInstruction('Move further away');
        return false;
      } else if (!isCentered) {
        if (updateInstruction) _setInstruction('Center your face');
        return false;
      }
      return true;
  }
  
  void _setInstruction(String text) {
    if (mounted && _instruction != text) {
      setState(() => _instruction = text);
    }
  }

  void _resetToFaceAlignment(String instruction) {
    _holdStillTimer?.cancel();
    if (mounted && (_instruction != instruction || _livenessState != _LivenessState.faceAlignment)) {
      setState(() {
        _instruction = instruction;
        _livenessState = _LivenessState.faceAlignment;
        _progress = 0;
        _currentIndex = 0;
        _capturedImagePath = null;
      });
    }
  }

  Future<void> _captureAndProceed() async {
     if (_controller == null || _controller!.value.isTakingPicture) return;
     try {
        final XFile imageFile = await _controller!.takePicture();
        setState(() {
          _capturedImagePath = imageFile.path;
          _livenessState = _LivenessState.livenessChallenge;
        });
        HapticFeedback.lightImpact();
      } catch(e) {
        _resetToFaceAlignment('Could not capture image, please try again');
      }
  }

  void _evaluateLivenessAction(Face face) {
    final yaw = face.headEulerAngleY;
    final pitch = face.headEulerAngleX;
    final smileProb = face.smilingProbability;
    final leftEyeOpen = face.leftEyeOpenProbability;
    final rightEyeOpen = face.rightEyeOpenProbability;

    if (yaw == null || pitch == null || smileProb == null || leftEyeOpen == null || rightEyeOpen == null) return;
    
    const leftThreshold = -18.0;
    const rightThreshold = 18.0;
    const upThreshold = 12.0;
    const downThreshold = -12.0;
    const smileThreshold = 0.8;
    const blinkThreshold = 0.2;
    
    final target = _required[_currentIndex];
    bool satisfied = false;

    switch (target) {
      case _Action.turnLeft:
        _setInstruction('Turn your head a bit to the left');
        satisfied = yaw <= leftThreshold;
        break;
      case _Action.turnRight:
        _setInstruction('Turn your head a bit to the right');
        satisfied = yaw >= rightThreshold;
        break;
      case _Action.turnUp:
        _setInstruction('Tilt your head up');
        satisfied = pitch >= upThreshold;
        break;
      case _Action.turnDown:
        _setInstruction('Tilt your head down');
        satisfied = pitch <= downThreshold;
        break;
      case _Action.smile:
        _setInstruction('Please smile');
        satisfied = smileProb >= smileThreshold;
        break;
      case _Action.blink:
        _setInstruction('Please blink');
        satisfied = leftEyeOpen < blinkThreshold && rightEyeOpen < blinkThreshold;
        break;
    }

    if (satisfied) {
      HapticFeedback.lightImpact();
      _currentIndex++;
      if (_currentIndex >= _required.length) {
        setState(() {
          _instruction = 'Done';
          _progress = 1.0;
          _livenessState = _LivenessState.done;
        });
        _onComplete();
      } else {
        setState(() => _progress = _currentIndex / _required.length);
      }
    } 
  }

  Future<void> _onComplete() async {
    await _controller?.stopImageStream();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Liveness check complete')),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pop(_capturedImagePath);
    });
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription description) {
    final camera = description;
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return null;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return null;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow, 
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  @override
  void dispose() {
    _holdStillTimer?.cancel();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI code remains the same
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
                        faceDetected: _livenessState != _LivenessState.faceAlignment,
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
                    alignment: const Alignment(0, 0.45),
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
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                          children: [
                            TextSpan(text: 'Powered by '),
                            TextSpan(
                              text: 'YourCompany',
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

enum _Action { turnLeft, turnRight, turnUp, turnDown, smile, blink }

// Viewport and Painter classes remain the same
class _CircularLivenessViewport extends StatelessWidget {
  final CameraController controller;
  final double ringProgress;
  final bool faceDetected;

  const _CircularLivenessViewport({
    required this.controller,
    required this.ringProgress,
    required this.faceDetected,
  });

  @override
  Widget build(BuildContext context) {
    final double diameter = MediaQuery.of(context).size.width * 0.78;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _AccentPainter()),
            ),
          ),
          Center(
            child: ClipOval(
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: CameraPreview(controller),
              ),
            ),
          ),
          Center(
            child: CustomPaint(
              size: Size(diameter, diameter),
              painter: _RingPainter(
                progress: ringProgress,
                thickness: 10,
                activeColor1: const Color(0xFF9B5CFF),
                activeColor2: const Color(0xFF6A3BFF),
                idleColor: const Color(0x4DFFFFFF),
              ),
            ),
          ),
          if (faceDetected)
            Positioned(
              right: max(
                  0.0, (MediaQuery.of(context).size.width - diameter) / 2 - 20),
              bottom: 20,
              child: const _Badge(
                icon: Icons.check_rounded,
                background: Color(0xFF2ECC71),
              ),
            ),
        ],
      ),
    );
  }
}


class _RingPainter extends CustomPainter {
  final double progress; // 0..1
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
        stops: const [0.2, 1.0],
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
  }

  @override
  bool shouldRepaint(_RingPainter old) => progress != old.progress;
}

class _AccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x269B5CFF);
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
