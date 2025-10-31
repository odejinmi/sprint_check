import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class Newcaptureidcard extends StatefulWidget {
  final Function(Map<String, dynamic>) onResponse;
  const Newcaptureidcard({Key? key, required this.onResponse}) : super(key: key);

  @override
  State<Newcaptureidcard> createState() => _NewcaptureidcardState();
}

class _NewcaptureidcardState extends State<Newcaptureidcard> {
  CameraController? cameracontroller;
  List<CameraDescription> cameras = [];
  final GlobalKey frameKey = GlobalKey();
  final GlobalKey previewKey = GlobalKey();

  String? _croppedImagePath;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    cameracontroller?.dispose();
    super.dispose();
  }

  initializeCamera() {
    availableCameras().then((camera) {
      cameras = camera;
      if (cameras.isNotEmpty) {
        cameracontroller = CameraController(
          cameras[0],
          ResolutionPreset.high,
        );
        cameracontroller!.initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }

  Future<void> _captureAndCrop() async {
    if (cameracontroller == null ||
        !cameracontroller!.value.isInitialized ||
        frameKey.currentContext == null ||
        previewKey.currentContext == null) {
      return;
    }

    final pictureFile = await cameracontroller!.takePicture();
    final imageBytes = await pictureFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes)!;

    final previewBox = previewKey.currentContext!.findRenderObject() as RenderBox;
    final frameBox = frameKey.currentContext!.findRenderObject() as RenderBox;

    // Get the render object of the preview and frame
    final previewSize = previewBox.size;
    // Get the position of the frame within the preview
    final framePosition = frameBox.localToGlobal(Offset.zero, ancestor: previewBox);
    final frameSize = frameBox.size;

    // Calculate the scale factor
    final scaleY = originalImage.height / previewSize.height;
    final scaleX = originalImage.width / previewSize.width;

    // Calculate the crop rectangle in image pixels
    final cropLeft = framePosition.dx * scaleX;
    final cropTop = framePosition.dy * scaleY;
    final cropWidth = frameSize.width * scaleX;
    final cropHeight = frameSize.height * scaleY;

    final croppedImage = img.copyCrop(
      originalImage,
      x: cropLeft.toInt(),
      y: cropTop.toInt(),
      width: cropWidth.toInt(),
      height: cropHeight.toInt(),
    );

    final tempDir = await getTemporaryDirectory();
    final croppedFile = File('${tempDir.path}/cropped_id${DateTime.now().millisecondsSinceEpoch}.jpg');
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

    cameracontroller?.dispose();
    // 8. Return the path of the cropped image
    widget.onResponse({'image': croppedFile.path});
  }

  @override
  Widget build(BuildContext context) {
    if (cameracontroller == null ||
        !cameracontroller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: const Color(0xFF4F4F4F),
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: CameraPreview(cameracontroller!, key: previewKey),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Front of ID',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  height: 1.78,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 85.6 / 53.98, // Standard ID card aspect ratio
                      child: Container(
                        key: frameKey,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                'Fit entire ID inside the above\nframe to capture.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _captureAndCrop,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 40)),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                color: Colors.white,
                child: const Text(
                  'Powered by SprintCheck',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
