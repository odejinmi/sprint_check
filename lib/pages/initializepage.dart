import 'package:flutter/material.dart';

import '../models/charge.dart';
import '../models/checkout_response.dart';
import '../sprint_check_method_channel.dart';

class Initializepage extends StatelessWidget {
  final OnResponse<CheckoutResponse> onResponse;
  final Charge charge;
  final CheckoutMethod checkoutmethod;
  const Initializepage({super.key, required this.onResponse, required this.charge, required this.checkoutmethod});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Image.asset(
            "assets/logo.png",
            width: 163,
            package: "sprint_check",
          ),
          const SizedBox(height: 20),
          const Text(
            'This application uses SprintCheck to verifiy your identity',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1B1B1B),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 1.47,
              letterSpacing: -0.41,
            ),
          ),
          const SizedBox(height: 25),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.done, size: 20, color: Colors.black),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'All personal and login information is confidential. Our system uses end-to-end encryption to ensure secure verification.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.41,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.done, size: 20, color: Colors.black),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'This verification step helps us confirm it’s really you. Do not share your code or authentication details with anyone, even if they claim to be from our team.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.41,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.done, size: 20, color: Colors.black),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Your personal and account information is handled under strict security protocols',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.41,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'By clicking “Continue” you agree to the \n',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                  ),
                ),
                TextSpan(
                  text: 'Sprintcheck privacy policy',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    letterSpacing: -0.41,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {

              var response = CheckoutResponse(
                  message: "i agreed ",
                  reference: "",
                  status: false,
                  method: checkoutmethod,
                  verify: false,
                  name: '',
                  confidenceLevel: null,
                  bvn: charge.bvn,
                  nin: charge.nin,
                  base64Image: null);
              onResponse(response);
            },
            child: Container(
              width: double.infinity,
              height: 47,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
