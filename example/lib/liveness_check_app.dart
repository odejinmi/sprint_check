import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final cameras = await availableCameras();
//   runApp(LivenessCheckScreen(cameras: cameras));
// }

class LivenessCheckScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const LivenessCheckScreen({super.key, required this.cameras});

  @override
  LivenessCheckScreenState createState() => LivenessCheckScreenState();
}

class LivenessCheckScreenState extends State<LivenessCheckScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _isFlashlightOn = false;
  bool _hasFlash = false;

  // Camera selection
  int _selectedCameraIndex = 0;

  // Captured image
  XFile? _capturedImage;

  // Liveness detection variables
  int _livenessScore = 0;
  bool _blinkDetected = false;
  bool _smileDetected = false;
  bool _faceMovementDetected = false;
  bool _faceSizeAdequate = false;
  bool _faceWellPositioned = false;
  bool _faceWellLit = false;

  // Last face position for movement detection
  Point<int>? _lastFacePosition;

  // Face quality thresholds
  final double _minFaceSizePercentage = 0.15;
  final double _movementThreshold = 15.0;

  // Liveness threshold
  final int _livenessThreshold = 100;

  // Timer for processing frames
  Timer? _frameProcessingTimer;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status == PermissionStatus.granted) {
      _initializeCamera();
    }
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.1,
    );

    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      return;
    }

    // Start with front camera if available
    _selectedCameraIndex = widget.cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    if (_selectedCameraIndex == -1) {
      _selectedCameraIndex = 0; // Default to first camera if front not found
    }

    await _setupCamera();

    _initializeFaceDetector();

    // Start frame processing timer
    _frameProcessingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) {
      _processLatestFrame();
    });
  }

  Future<void> _setupCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.yuv420
              : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();

      // Check if flash is available
      _hasFlash = _cameraController!.value.flashMode != null;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _toggleFlashlight() async {
    if (_cameraController == null || !_hasFlash) return;

    try {
      final FlashMode newFlashMode =
          _isFlashlightOn ? FlashMode.off : FlashMode.torch;

      await _cameraController!.setFlashMode(newFlashMode);

      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
    } catch (e) {
      print('Error toggling flashlight: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length <= 1) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;

    // Reset liveness state
    _resetLivenessState();

    // Reset flashlight
    _isFlashlightOn = false;

    // Setup new camera
    await _setupCamera();
  }

  Future<void> _processLatestFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing ||
        !mounted) {
      return;
    }

    _isProcessing = true;

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Process image with face detector
      final faces = await _faceDetector!.processImage(inputImage);

      // Delete the temporary file
      File(
        image.path,
      ).delete().catchError((e) => print('Error deleting temp file: $e'));

      if (faces.isEmpty) {
        setState(() {
          _updateUI('No face detected', 0);
          _resetLivenessState();
        });
      } else if (faces.length > 1) {
        setState(() {
          _updateUI('Multiple faces detected', 0);
          _resetLivenessState();
        });
      } else {
        // Single face detected - process for liveness and quality
        await _processFaceForLivenessAndQuality(faces[0], inputImage);
      }
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processFaceForLivenessAndQuality(
    Face face,
    InputImage inputImage,
  ) async {
    // Check face size
    final imageWidth = inputImage.metadata?.size.width ?? screenSize.width;
    final imageHeight = inputImage.metadata?.size.height ?? screenSize.height;
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;

    final faceSizePercentage =
        (faceWidth * faceHeight) / (imageWidth * imageHeight);
    _faceSizeAdequate = faceSizePercentage >= _minFaceSizePercentage;

    // Check face position
    final faceCenterX = face.boundingBox.left + (face.boundingBox.width / 2);
    final faceCenterY = face.boundingBox.top + (face.boundingBox.height / 2);
    final imageCenterX = imageWidth / 2;
    final imageCenterY = imageHeight / 2;
    _faceWellPositioned =
        (faceCenterX - imageCenterX).abs() < imageWidth * 0.15 &&
        (faceCenterY - imageCenterY).abs() < imageHeight * 0.15;

    // Check face movement
    final currentPosition = Point(faceCenterX.toInt(), faceCenterY.toInt());
    if (_lastFacePosition != null) {
      final movement = _calculateDistance(_lastFacePosition!, currentPosition);
      if (movement > _movementThreshold) {
        _faceMovementDetected = true;
      }
    }
    _lastFacePosition = currentPosition;

    // Check for blinking
    final leftEyeOpenProb = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpenProb = face.rightEyeOpenProbability ?? 0;

    if (leftEyeOpenProb < 0.1 && rightEyeOpenProb < 0.1) {
      _blinkDetected = true;
    }

    // Check for smiling
    final smileProbability = face.smilingProbability ?? 0;
    if (smileProbability > 0.7) {
      _smileDetected = true;
    }

    // Estimate lighting conditions based on face landmarks visibility
    final allLandmarksVisible = face.landmarks.length >= 4;
    _faceWellLit = allLandmarksVisible;

    // Calculate liveness score
    _calculateLivenessScore();

    // Update UI
    setState(() {
      _updateLivenessUI();
    });
  }

  void _calculateLivenessScore() {
    // Reset score
    _livenessScore = 0;

    // Add points for each liveness indicator
    if (_blinkDetected) _livenessScore += 25;
    if (_smileDetected) _livenessScore += 25;
    if (_faceMovementDetected) _livenessScore += 25;

    // Add points for quality indicators
    if (_faceSizeAdequate) _livenessScore += 10;
    if (_faceWellPositioned) _livenessScore += 10;
    if (_faceWellLit) _livenessScore += 5;

    // Cap at 100
    _livenessScore = min(_livenessScore, 100);
  }

  void _updateLivenessUI() {
    final statusBuilder = StringBuffer();

    // Build status message
    if (!_faceSizeAdequate) {
      statusBuilder.write('Move closer to the camera\n');
    }

    if (!_faceWellPositioned) {
      statusBuilder.write('Center your face in the frame\n');
    }

    if (!_faceWellLit) {
      statusBuilder.write('Improve lighting conditions\n');
    }

    if (!_blinkDetected) {
      statusBuilder.write('Blink your eyes\n');
    }

    if (!_smileDetected) {
      statusBuilder.write('Smile\n');
    }

    if (!_faceMovementDetected) {
      statusBuilder.write('Slightly move your head\n');
    }

    if (_livenessScore >= _livenessThreshold) {
      statusBuilder.clear();
      statusBuilder.write('All checks passed! You can capture now.');
    }

    _updateUI(statusBuilder.toString().trim(), _livenessScore);
  }

  void _updateUI(String message, int progress) {
    setState(() {
      _statusMessage = message;
      _livenessScore = progress;
    });
  }

  void _resetLivenessState() {
    _blinkDetected = false;
    _smileDetected = false;
    _faceMovementDetected = false;
    _faceSizeAdequate = false;
    _faceWellPositioned = false;
    _faceWellLit = false;
    _livenessScore = 0;
    _lastFacePosition = null;
  }

  double _calculateDistance(Point<int> p1, Point<int> p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt((dx * dx) + (dy * dy));
  }

  Future<void> _captureFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
        _statusMessage = 'Face captured successfully!';
      });

      // Reset after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _resetLivenessState();
        });
      });
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        _statusMessage = 'Failed to capture image';
      });
    }
  }

  String _statusMessage = 'Waiting for face...';

  late Size screenSize;

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isCameraInitialized)
              Center(child: CameraPreview(_cameraController!))
            else
              const Center(child: CircularProgressIndicator()),

            // Face overlay
            Center(
              child: Container(
                width: 250,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 3),
                ),
              ),
            ),

            // Instruction text
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Text(
                'Position your face in the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  backgroundColor: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Status text
            Positioned(
              bottom: 150,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color:
                    _livenessScore >= _livenessThreshold
                        ? Colors.green.withOpacity(0.7)
                        : Colors.black.withOpacity(0.5),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            // Progress bar
            Positioned(
              bottom: 130,
              left: 20,
              right: 20,
              child: LinearProgressIndicator(
                value: _livenessScore / 100,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _livenessScore >= _livenessThreshold
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
            ),

            // Capture button
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed:
                      _livenessScore >= _livenessThreshold
                          ? _captureFace
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Capture', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),

            // Switch camera button
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black54,
                onPressed: _switchCamera,
                child: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
            ),

            // Flashlight button (only show if flash is available)
            if (_hasFlash)
              Positioned(
                top: 20,
                left: 20,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.black54,
                  onPressed: _toggleFlashlight,
                  child: Icon(
                    _isFlashlightOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                ),
              ),

            // Captured image preview
            if (_capturedImage != null)
              Positioned(
                bottom: 50,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    image: DecorationImage(
                      image: FileImage(File(_capturedImage!.path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _frameProcessingTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}
