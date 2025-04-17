import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_face_api/flutter_face_api.dart';
import 'package:get/get.dart';

import '../common/verificationController.dart';

class Facepage extends GetView<VerificationController> {
  @override
  Widget build(BuildContext context) {
    controller.fetchdetails(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Face Recognition',
            style: TextStyle(
              color: const Color(0xFF171D1E),
              fontSize: 22,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Image.asset(
              "assets/face.png",
              width: 245,
              height: 245,
              package: "sprint_check",
            ),
          ),
          SizedBox(height: 20),
          Text(
            'You are about to carry out a face liveliness check. \nPlease follow the instructions given below.',
            style: TextStyle(
              color: const Color(0xFF171D1E),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 40),
          Stack(
            children: [
              Positioned(
                top: 6,
                left: 7,
                child: Container(
                  // transform:
                  //     Matrix4.identity()
                  //       ..translate(0.0, 0.0)
                  //       ..rotateZ(1.57),
                  height: 90,
                  width: 0.7,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: const Color(0xFF137F0C) /* Green-700 */,
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFD9D9D9),
                          shape: OvalBorder(
                            side: BorderSide(
                              width: 3,
                              color: const Color(0xFF137F0C) /* Green-700 */,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Text(
                        'Be in a well lit environment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF6A6C6A),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFD9D9D9),
                          shape: OvalBorder(
                            side: BorderSide(
                              width: 3,
                              color: const Color(0xFF137F0C) /* Green-700 */,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Text(
                        'Position and follow the instructions given',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF6A6C6A),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFD9D9D9),
                          shape: OvalBorder(
                            side: BorderSide(
                              width: 3,
                              color: const Color(0xFF137F0C) /* Green-700 */,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Text(
                        'Have a successful verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF6A6C6A),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 40),
          Divider(),
          SizedBox(height: 10),
          InkWell(
            onTap: () async {
              if (controller.bvnController.text.length < 11 ||
                  controller.bvnController.text.length > 11) {
                // CustomAlertDialogloader(
                //   title: "Error",
                //   message: "Kindly Input or Paste your valid BVN and try again",
                //   negativeBtnText: "Ok",
                // );
                return;
              }
              LivenessResponse? pickedFile =
                  await controller.faceapi.startLiveness();
              if (pickedFile != null && pickedFile.image != null) {
                controller.captureimage = base64Encode(pickedFile.image!);
                if (controller.bvnimage.isNotEmpty) {
                  controller.compareimage(context);
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: const Color(0xFF137F0C) /* Green-700 */,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                'Open Camera',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFEAFFE6) /* Green-50 */,
                  fontSize: 14,
                  fontFamily: 'Inter',
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
