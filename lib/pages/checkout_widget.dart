import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sprint_check/pages/inputpage.dart';
import 'package:sprint_check/pages/verificationscore.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';

import '../common/verificationController.dart';
import 'capture_i_d_card_page.dart';
import 'facepage.dart';

class CheckoutWidget extends GetView<VerificationController> {
  const CheckoutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF5F5F5),
      // ? Colors.white
      // : Colors.grey,
      child: Obx(() {
        if (controller.stage == 2) {
          controller.startTimer(context);
        }
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 10.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (controller.stage != 0) {
                          if (controller.stage == 3) {
                            controller.closedialog(
                              context,
                              "user cancel the process",
                            );
                          } else if (controller.checkoutmethod ==
                              CheckoutMethod.idcard) {
                            controller.stage = 3;
                          } else if (controller.checkoutmethod ==
                                  CheckoutMethod.facial ||
                              controller.directcheckout) {
                            controller.closedialog(
                              context,
                              "user cancel the process",
                            );
                          } else {
                            controller.stage--;
                          }
                        } else {
                          controller.closedialog(
                            context,
                            "user cancel the process",
                          );
                        }
                      },
                      icon: Icon(Icons.arrow_back),
                    ),
                  ],
                ),
                Expanded(
                  child:
                      controller.stage == 0
                          ? Inputpage()
                          : controller.stage == 1
                          ? Facepage()
                          : controller.stage == 3
                          ? CaptureIDCardPage()
                          : Verificationscore(),
                ),
                SizedBox(height: 20),
                controller.stage != 2
                    ? Text(
                      'POWERED BY SPRINTCHECK',
                      style: TextStyle(
                        color: const Color(0xFF137F0C),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    )
                    : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Closing in ',
                            style: TextStyle(
                              color: const Color(0xFFF11313),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.33,
                              letterSpacing: 0.40,
                            ),
                          ),
                          TextSpan(
                            text: '${controller.start}secs',
                            style: TextStyle(
                              color: const Color(0xFFF11313),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w800,
                              height: 1.33,
                              letterSpacing: 0.40,
                            ),
                          ),
                        ],
                      ),
                    ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      }),
    );
  }
}
