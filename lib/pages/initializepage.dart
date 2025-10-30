import 'package:flutter/material.dart';

class Initializepage extends StatelessWidget {
  const Initializepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Image.asset(
              "assets/logo.jpg",
              width: 163,
              package: "sprint_check",
            ),
          Text(
            'This application uses SprintCheck to verifiy your identity',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF1B1B1B),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 1.47,
              letterSpacing: -0.41,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 25,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  Container(width: 20, height: 20, child: Stack()),
                  Text(
                    'All personal and login information is confidential. Our system uses end-to-end encryption to ensure secure verification.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.41,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  Container(width: 20, height: 20, child: Stack()),
                  Text(
                    'This verification step helps us confirm it’s really you. Do not share your code or authentication details with anyone, even if they claim to be from our team.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.41,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  Container(width: 20, height: 20, child: Stack()),
                  Text(
                    'Your personal and account information is handled under strict security protocols',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.41,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 150),
          Text.rich(
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
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 47,
            decoration: ShapeDecoration(
              color: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 10,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
