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

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  initializeCamera() {
    availableCameras().then((camera) {
      cameras = camera;
      if (cameras.isNotEmpty && cameracontroller == null) {
        cameracontroller = CameraController(
          cameras[0],
          ResolutionPreset.high, // Use high resolution for better quality
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
    if (cameracontroller == null || !cameracontroller!.value.isInitialized) {
      return;
    }

    // 1. Take the picture
    final pictureFile = await cameracontroller!.takePicture();

    // 2. Find the location and size of the frame on the screen
    final RenderBox frameBox = frameKey.currentContext!.findRenderObject() as RenderBox;
    final frameSize = frameBox.size;
    final framePosition = frameBox.localToGlobal(Offset.zero);

    // 3. Get screen and image dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height - 60;

    final imageBytes = await pictureFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes)!;

    // 4. Calculate the scale and offset to map screen coordinates to image coordinates.
    // This logic accounts for the CameraPreview's `BoxFit.cover` behavior.
    final previewRatio = cameracontroller!.value.aspectRatio;
    final screenRatio = screenWidth / screenHeight;
    
    double scale;
    double xOffset = 0, yOffset = 0;

    if (previewRatio > screenRatio) { // Preview is wider than the screen
      scale = screenHeight / originalImage.height;
      xOffset = (originalImage.width - screenWidth / scale) / 2;
    } else { // Preview is taller than or same ratio as the screen
      scale = screenWidth / originalImage.width;
      yOffset = (originalImage.height - screenHeight / scale) / 2;
    }
    
    // 5. Calculate the crop rectangle in image pixels.
    final cropLeft = (framePosition.dx / scale) + xOffset;
    final cropTop = (framePosition.dy / scale) + yOffset;
    final cropWidth = frameSize.width / scale;
    final cropHeight = frameSize.height / scale;

    // 6. Crop the image
    final croppedImage = img.copyCrop(
      originalImage,
      x: cropLeft.toInt(),
      y: cropTop.toInt(),
      width: cropWidth.toInt(),
      height: cropHeight.toInt(),
    );

    // 7. Save the cropped image to a temporary file
    final tempDir = await getTemporaryDirectory();
    final croppedFile = File('${tempDir.path}/cropped_id.jpg');
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

    // 8. Return the path of the cropped image
    widget.onResponse({'image': croppedFile.path});
  }

  @override
  void dispose() {
    cameracontroller?.dispose();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    if (cameracontroller == null ||
        !cameracontroller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: const Color(0xFF4F4F4F),
      child: Stack(
        children: [
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: cameracontroller!.value.aspectRatio,
              child: CameraPreview(cameracontroller!),
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
