import 'dart:async';
// import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:flutter_face_api/flutter_face_api.dart';
import 'package:sprintliveness/model/liveness_response.dart';

import '../common/diorequest.dart';
import '../common/new_cameraliveness.dart';
import '../models/charge.dart';
import '../sprint_check_method_channel.dart';

class Newfacepage extends StatefulWidget {
  final String publicKey;
  final String secretKey;
  final String bvnimage;
  final String reference;
  final Charge charge;
  final CheckoutMethod checkoutmethod;
  final Function(Map<String, dynamic>) onResponse;
  const Newfacepage({super.key,required this.onResponse, required this.bvnimage, required this.reference, required this.charge, required this.checkoutmethod, required this.publicKey, required this.secretKey});

  @override
  _NewfacepageState createState() => _NewfacepageState();
}

class _NewfacepageState extends State<Newfacepage> {

  var faceapi = NewCameraliveness();

  var score = 0.0;
  int stage = 0;

  Timer? timer;
  double width = 155.0;
  String enrollmentdata = "";
  String? capturedImageBase64;

  void timercount(){
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(
      const Duration(milliseconds: 100),
          (timer) => _incrementCount(),
    );
    setState(() {

    });
  }

  void _incrementCount() {
    if (width < 160.0) {
      width += 20.0;
    } else {
      width = 140.0;
      timer?.cancel();
      timer = Timer.periodic(
        const Duration(milliseconds: 100),
            (timer) => _decrementCount(),
      );
    }
    setState(() {

    });
  }

  void _decrementCount() {
    width -= 20.0;
    if (width == 60.0) {
      timer?.cancel();
      timer = Timer.periodic(
        const Duration(milliseconds: 100),
            (timer) => _incrementCount(),
      );
    }
    setState(() {

    });
  }
  Future<void> compareimage(String captureimage, String bvnimage) async {
    stage = 1;
    capturedImageBase64 = captureimage;
    timercount();
    setState(() {

    });
    var result = await faceapi.comparefaceKyc(captureimage, bvnimage);
    // dev.log("image compare result $result");
    score = result;
    postdetails(captureimage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: stage == 0? Column(
            children: [
              Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/face.png",
                      package: "sprint_check",),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 30,),
              Expanded(
                child: Column(
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
                        SizedBox(width: 20, height: 20, child: Icon(Icons.done, size: 20, color: Colors.black)),
                        Expanded(
                          child: Text(
                            'Please make sure your face matches your BVN details so we can verify your identity.',
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 7,
                      children: [
                        SizedBox(width: 20, height: 20, child: Icon(Icons.done, size: 20, color: Colors.black)),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 7,
                      children: [
                        SizedBox(width: 20, height: 20, child: Icon(Icons.done, color: Colors.black, )),
                        Expanded(
                          child: Text(
                            'Stay in a bright lite environment',
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 7,
                      children: [
                        SizedBox(width: 20, height: 20, child: Icon(Icons.done, color: Colors.black, )),
                        Expanded(
                          child: Text(
                            'Remove eye glasses, hats, face mask, or any face coverings',
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
              ),
            ],
          ) :
          stage == 1?
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(),
                Spacer(),
                Center(
                  child: Image.asset(
                    "assets/logo.png",
                    width: width,
                    package: "sprint_check",
                  ),
                ),
                SizedBox(height: 20,),
                Text(
                  'Validating Credentials...',
                  style: TextStyle(
                    color: const Color(0xFF181619),
                    fontSize: 15,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                    height: 2.13,
                  ),
                ),
                Spacer()
              ],
            ),
          ):
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(),
                Spacer(),
                Center(
                  child: Image.asset(
                    "assets/logo.png",
                    width: 155.0,
                    package: "sprint_check",
                  ),
                ),
                SizedBox(height: 20,),
                Text(
                  'Validation Successful',
                  style: TextStyle(
                    color: const Color(0xFF181619),
                    fontSize: 15,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                    height: 2.13,
                  ),
                ),
                Spacer()
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            if (stage == 0) {
              // stage = 2;
              // score = 94;
              // enrollmentdata = "ODEJINMI TOLULOPE ABRAHAM";
              // setState(() {});
              // LivenessResponse? pickedFile =
              // await faceapi.startLiveness();
              // if (pickedFile != null && pickedFile.image != null) {
              //   var captureimage = base64Encode(pickedFile.image!);
              //   // controller.loading(context);
              //   compareimage(captureimage, widget.bvnimage);
              // }
              LivenessResult? pickedFile =
              await faceapi.startLiveness(context);
              if (pickedFile != null && pickedFile.image != null) {
                var captureimage = pickedFile.image!;
                // controller.loading(context);
                compareimage(captureimage, widget.bvnimage);
              }
            }else if (stage == 2) {
              widget.onResponse({
                "score": score,
                "enrollmentdata": enrollmentdata,
                "base64Image": capturedImageBase64
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 47,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: const Color(0xFF181619),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              stage ==0? 'Start face verification': 'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
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
    );
  }

  Future<void> postdetails(String captureimage) async {
    var result = await Diorequest().put(checmethod.toLowerCase(), {
      'number': widget.charge.bvn,
      'reference': widget.reference,
      'identifier': widget.charge.identifier,
      'confidence': score.toInt(),
      'image': captureimage,
    }, widget.publicKey, widget.secretKey,);
    // var result = {"success":1,"message":"Recorded Successfully","data":"ODEJINMI TOLULOPE ABRAHAM"}
    stage = 2;
    timer?.cancel();
    if (result["success"] == 1) {
      enrollmentdata = result["data"];
    }
    widget.onResponse({
      "score": score,
      "enrollmentdata": enrollmentdata,
      "base64Image": capturedImageBase64
    });
  }

  String get checmethod {
    switch (widget.checkoutmethod) {
      case CheckoutMethod.bvn:
        return "BVN";
      case CheckoutMethod.nin:
        return "NIN";
      case CheckoutMethod.facial:
        return "FACIAL";
      case CheckoutMethod.idcard:
        return "IDCARD";
      default:
        return "Selectable";
    }
  }
}
