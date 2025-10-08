import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../common/verificationController.dart';

class Inputpage extends GetView<VerificationController> {
  @override
  Widget build(BuildContext context) {
    controller.bvnController.clear();
    return SingleChildScrollView(
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'Enter your verification details',
              style: TextStyle(
                color: const Color(0xFF171D1E),
                fontSize: 22,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This is a message from the initiator',
              style: TextStyle(
                color: const Color(0xFF6A6C6A),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 40),
            Text(
              controller.checmethod,
              style: TextStyle(
                color: const Color(0xFF454745),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    autofillHints: [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      hintText: "22200000....",
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Color(0xFF6A6C6A)),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Color(0xFF6A6C6A)),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // ⬅️ This ensures only digits are allowed
                      DigitsOnlyFormatter(),
                    ],
                    controller: controller.bvnController,
                    onChanged: (value) {},
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Kindly input your ${controller.checmethod}";
                      }

                      return null;
                    },
                  ),
                ),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: () async {
                    final ClipboardData? data = await Clipboard.getData(
                      Clipboard.kTextPlain,
                    );

                    if (data != null) {
                      final digitsOnly = data.text!.replaceAll(
                        RegExp(r'[^\d]'),
                        '',
                      );
                      controller.bvnController.text = digitsOnly;
                    }
                    controller.name = "Pasted!";
                    Future.delayed(Duration(milliseconds: 3000), () {
                      controller.name = "Paste";
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF8ADD88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.name,
                          style: TextStyle(
                            color: Color(0xFF000E3B),
                            fontSize: 14,
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            height: 1.09,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 140),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 7,
              children: [
                Obx(() {
                  return Checkbox(
                    value: controller.checked,
                    onChanged: (value) {
                      controller.checked = value;
                    },
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFCFCFCF),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'I certify that the information provided belongs to me and it is accurate and I agree to the ',
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: 16,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: 'User Agreement',
                          style: TextStyle(
                            color: const Color(0xFF2752E7),
                            fontSize: 16,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: ' and ',
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: 16,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: const Color(0xFF2752E7),
                            fontSize: 16,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(),
            // SizedBox(height: 10),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const LiveDetectionPage()),
            //     );
            //   },
            //   child: const Text('Live Face Detection'),
            // ),
            SizedBox(height: 10),
            InkWell(
              onTap: () {
                if (controller.checked) {
                  controller.stage = 1;
                }
              },
              child: Container(
                width: double.infinity,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color:
                      controller.checked
                          ? const Color(0xFF137F0C)
                          : Color(0xFF6A6C6A) /* Green-700 */,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  'Continue',
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
        );
      }),
    );
  }
}

class DigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }
}
