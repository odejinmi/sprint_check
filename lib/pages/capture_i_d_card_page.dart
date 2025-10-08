import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/verificationController.dart';

class CaptureIDCardPage extends GetView<VerificationController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.name;
      print("controller.cameracontroller");
      print(controller.cameracontroller == null);
      print(!controller.cameracontroller!.value.isInitialized);
      print(controller.cameracontroller!.value);
      if (controller.cameracontroller == null ||
          !controller.cameracontroller!.value.isInitialized) {
        return Center(child: CircularProgressIndicator());
      }
      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: AspectRatio(
              aspectRatio: controller.cameracontroller!.value.aspectRatio,
              child: CameraPreview(controller.cameracontroller!),
            ),
          ),
          Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Scan your document',
                    style: TextStyle(
                      color: const Color(0xFF171D1E),
                      fontSize: 22,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      height: 1.64,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'This is a message from the initiator',
                    style: TextStyle(
                      color: const Color(0xFF6A6C6A),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                      letterSpacing: 0.40,
                    ),
                  ),
                  Row(),
                ],
              ),
              SizedBox(height: 20),
              Spacer(),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFF38393D)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Scan Front of ID',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        height: 0.83,
                        letterSpacing: 0.10,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      controller.result.isEmpty
                          ? '\nStart by positioning the front of your\nPassport in the frame. Use a\nwell-lit area and a simple dark background.'
                          : controller.result,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.43,
                        letterSpacing: 0.10,
                      ),
                    ),
                    SizedBox(height: 20),
                    InkWell(
                      onTap: controller.captureAndExtract,
                      child: Container(
                        width: 79,
                        height: 79,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Container(
                                width: 63,
                                height: 63,
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: OvalBorder(),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 79,
                                height: 79,
                                decoration: ShapeDecoration(
                                  shape: OvalBorder(
                                    side: BorderSide(width: 2, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              // ElevatedButton(
              //   onPressed: controller.pickAndExtractIDCardInfo,
              //   child: Text('upload & Extract'),
              // ),
              // if (controller.result != null)
              //   Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: Text(controller.result!),
              //   ),
            ],
          ),
        ],
      );
    });
  }
}
