import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../common/verificationController.dart';

class Verificationscore extends GetView<VerificationController> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Score',
            style: TextStyle(
              color: const Color(0xFF171D1E),
              fontSize: 22,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: 100,
                showTicks: false,
                showLabels: true,
                labelsPosition: ElementsPosition.outside,
                axisLineStyle: AxisLineStyle(
                  thickness: 0.15,
                  cornerStyle: CornerStyle.bothCurve,
                  color: Colors.grey.shade300,
                  thicknessUnit: GaugeSizeUnit.factor,
                ),
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: controller.score,
                    needleColor: Colors.black,
                    knobStyle: KnobStyle(color: Colors.black),
                  ),
                ],
                ranges: <GaugeRange>[
                  GaugeRange(
                    startValue: 0,
                    endValue: 50,
                    color: Colors.red,
                    startWidth: 10,
                    endWidth: 10,
                  ),
                  GaugeRange(
                    startValue: 50,
                    endValue: 75,
                    color: Colors.orange,
                    startWidth: 10,
                    endWidth: 10,
                  ),
                  GaugeRange(
                    startValue: 75,
                    endValue: 100,
                    color: Colors.green,
                    startWidth: 10,
                    endWidth: 10,
                  ),
                ],
              ),
            ],
          ),
          Center(
            child: Text(
              controller.score.toInt().toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 45,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                height: 1.16,
              ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Your Score is ',
                    style: TextStyle(
                      color: const Color(0xFF6A6C6A),
                      fontSize: 22,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.27,
                    ),
                  ),
                  TextSpan(
                    text: controller.score > 50 ? 'Good' : 'BAD',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.27,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 40),
          Divider(),
          Text(
            'KYC Verification ${controller.score > 50 ? "Completed" : "Failed"}',
            style: TextStyle(
              color:
                  controller.score > 50
                      ? const Color(0xFF137F0C)
                      : const Color(0xFFF11313),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 1.43,
              letterSpacing: 0.10,
            ),
          ),
          SizedBox(height: 20),
          Text(
            controller.displaymessage,
            style: TextStyle(
              color: const Color(0xFF6A6C6A),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.33,
              letterSpacing: 0.40,
            ),
          ),
          SizedBox(height: 20),
          Divider(),
          SizedBox(height: 10),
          InkWell(
            onTap: () {
              if (controller.verificationstatus == 2) {
                controller.closedialog(context, "Verification Completed");
              } else if (controller.verificationstatus == 0) {
                controller.stage = 0;
              } else {
                controller.stage = 1;
              }
            },
            child: Container(
              width: double.infinity,
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: const Color(0xFF137F0C) /* Green-700 */,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                controller.verificationstatus == 2
                    ? 'Go Home'
                    : controller.verificationstatus == 1
                    ? "Retry Face Recognition"
                    : "Start Over",
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
          SizedBox(height: 10),
          if (controller.verificationstatus == 1)
            InkWell(
              onTap: () {
                controller.stage = 0;
              },
              child: Center(
                child: Text(
                  'Start Over',
                  style: TextStyle(
                    color: const Color(0xFF1D1B20),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: 0.40,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
