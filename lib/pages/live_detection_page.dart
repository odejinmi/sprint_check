// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
//
// enum DetectionState { loading, ready, error }
//
// class LiveDetectionPage extends StatefulWidget {
//   const LiveDetectionPage({Key? key}) : super(key: key);
//
//   @override
//   State<LiveDetectionPage> createState() => _LiveDetectionPageState();
// }
//
// class _LiveDetectionPageState extends State<LiveDetectionPage> {
//   CameraController? _cameraController;
//   late FaceDetector _faceDetector;
//   bool _isDetecting = false;
//   List<Face> _faces = [];
//   DetectionState _state = DetectionState.loading;
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   Future<void> _init() async {
//     try {
//       final cameras = await availableCameras();
//       final camera = cameras.firstWhere(
//         (c) => c.lensDirection == CameraLensDirection.front,
//         orElse: () => cameras.first,
//       );
//       _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
//       await _cameraController!.initialize();
//       _faceDetector = FaceDetector(
//         options: FaceDetectorOptions(
//           enableContours: true,
//           enableClassification: true,
//         ),
//       );
//       _cameraController!.startImageStream(_processCameraImage);
//       setState(() => _state = DetectionState.ready);
//     } catch (e) {
//       setState(() => _state = DetectionState.error);
//     }
//   }
//
//   void _processCameraImage(CameraImage image) async {
//     if (_isDetecting) return;
//     _isDetecting = true;
//     try {
//       final WriteBuffer allBytes = WriteBuffer();
//       for (var plane in image.planes) {
//         allBytes.putUint8List(plane.bytes);
//       }
//       final bytes = allBytes.done().buffer.asUint8List();
//
//       final inputImage = InputImage.fromBytes(
//         bytes: bytes,
//         inputImageData: InputImageData(
//           size: Size(image.width.toDouble(), image.height.toDouble()),
//           imageRotation: InputImageRotation.rotation0deg,
//           inputImageFormat: InputImageFormatMethods.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
//           planeData: image.planes.map(
//             (plane) => InputImagePlaneMetadata(
//               bytesPerRow: plane.bytesPerRow,
//               height: plane.height,
//               width: plane.width,
//             ),
//           ).toList(),
//         ),
//       );
//
//       final faces = await _faceDetector.processImage(inputImage);
//       if (mounted) {
//         setState(() => _faces = faces);
//       }
//     } catch (_) {}
//     _isDetecting = false;
//   }
//
//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     _faceDetector.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_state == DetectionState.loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_state == DetectionState.error || _cameraController == null) {
//       return const Scaffold(body: Center(child: Text('Camera error')));
//     }
//     return Scaffold(
//       appBar: AppBar(title: const Text('Live Face Detection')),
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           CameraPreview(_cameraController!),
//           ..._faces.map((face) => Positioned(
//                 left: face.boundingBox.left,
//                 top: face.boundingBox.top,
//                 width: face.boundingBox.width,
//                 height: face.boundingBox.height,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.red, width: 2),
//                   ),
//                 ),
//               )),
//         ],
//       ),
//     );
//   }
// }
