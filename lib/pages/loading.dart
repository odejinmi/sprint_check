import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/verificationController.dart';

class Loading extends GetView<VerificationController> {
  const Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AlertDialog(
        content: Container(
          // color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Obx(() {
                  return Image.asset(
                    "assets/logo.jpg",
                    width: controller.width,
                    package: "sprint_check",
                  );
                }),
              ),
              Text("Loading"),
            ],
          ),
        ),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }
}
