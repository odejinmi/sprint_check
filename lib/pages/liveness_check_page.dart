import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// A screen that provides a real-time liveness check experience.
class LivenessCheckScreen extends StatefulWidget {
  const LivenessCheckScreen({Key? key}) : super(key: key);

  @override
  _LivenessCheckScreenState createState() => _LivenessCheckScreenState();
}

class _LivenessCheckScreenState extends State<LivenessCheckScreen> {
  /// Controller for the camera.
  CameraController? _cameraController;
  /// Detector for faces in the camera stream.
  FaceDetector? _faceDetector;
  /// The feedback message displayed to the user.
  String _feedbackMessage = 'Position your face in the oval';
  /// Timer to handle the countdown before auto-capturing.
  Timer? _captureTimer;
  /// Flag to indicate if the camera is currently processing an image.
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    _captureTimer?.cancel();
    super.dispose();
  }

  /// Initializes the camera controller and face detector.
  void _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        // Return null if no front camera is found.
        orElse: () => throw Exception('No front camera found'));

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: true,
      ),
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        _cameraController!.startImageStream(_processImage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Error: Could not initialize camera.';
        });
      }
    }
  }

  /// Processes each frame from the camera stream for face detection.
  void _processImage(CameraImage image) {
    if (_isProcessing) return;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final camera = _cameraController!.description;
    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );

    _isProcessing = true;
    _faceDetector?.processImage(inputImage).then((faces) {
      if (mounted) {
        _updateFeedback(faces);
      }
      _isProcessing = false;
    }).catchError((_) {
      _isProcessing = false;
    });
  }

  /// Updates the user feedback based on the face detection results.
  void _updateFeedback(List<Face> faces) {
    if (faces.isEmpty) {
      _resetCaptureTimer();
      setState(() {
        _feedbackMessage = 'No face detected';
      });
      return;
    }

    final face = faces.first;
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;

    if (headEulerAngleY.abs() > 10 || headEulerAngleZ.abs() > 10) {
      _resetCaptureTimer();
      setState(() {
        _feedbackMessage = 'Look straight';
      });
      return;
    }

    setState(() {
      _feedbackMessage = 'Hold still...';
    });

    _startCaptureTimer();
  }

  /// Resets the auto-capture timer.
  void _resetCaptureTimer() {
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  /// Starts the auto-capture timer if it's not already running.
  void _startCaptureTimer() {
    if (_captureTimer != null && _captureTimer!.isActive) return;

    _captureTimer = Timer(const Duration(seconds: 2), () {
      _captureImage();
    });
  }

  /// Captures a high-quality image and returns the result.
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    await _cameraController!.stopImageStream();

    final XFile imageFile = await _cameraController!.takePicture();

    if (mounted) {
      Navigator.of(context).pop(imageFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          (MediaQuery.of(context).size.height * 0.5) / 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: Text(
                _feedbackMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
