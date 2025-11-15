import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/IDCardInfo.dart';
import 'newcaptureidcard.dart';

class Idcardpage extends StatefulWidget {
  final Function(Map<String, dynamic>) onResponse;
  final Map<String, dynamic> idcard;
  const Idcardpage({super.key, required this.onResponse, required this.idcard});

  @override
  _IdcardpageState createState() => _IdcardpageState();
}

class _IdcardpageState extends State<Idcardpage> {

  String? _image;
  Timer? timer;

  bool capture = false;
  double width = 155.0;

  int stage = 0;

  IDCardInfo? idcardinfo;

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
    if (!mounted) {
      return;
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
    if (!mounted) {
      return;
    }
    setState(() {

    });
  }
  @override
  Widget build(BuildContext context) {
    return capture ?Newcaptureidcard(onResponse: (value){
      setState(() {
        _image = value['image'];
      });
      capture = false;
      setState(() {
      });
    }) : SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          Text(widget.idcard['name']!,
            style: TextStyle(
              color: const Color(0xFF181619),
              fontSize: 18,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              height: 1.78,
            ),
          ),
          Container(
            width:double.infinity,
            height: _image != null ? null : 183,
            // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                // side: BorderSide(
                //   width: 1,
                //   color: const Color(0xFF7D7D7D),
                // ),
                borderRadius: BorderRadius.circular(8),
              ),
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/Input.png', package: "sprint_check"),
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                if(_image != null)
                Image.file(File(_image!),
                  fit: BoxFit.fill,
                ),
                if(_image == null)
                Center(
                  child: InkWell(
                    onTap: () {
                      capture = true;
                      setState(() {
                      });
                    },
                    child: Image.asset('assets/capture.png',
                      package: "sprint_check", height: 40,
                    ),
                  ),
                ),
                if(_image != null)
                Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _image = null;
                        stage = 0;
                      });
                    },
                    child: Image.asset('assets/delete.png',
                      package: "sprint_check", height: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          stage == 0 ?
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  SizedBox(width: 20, height: 20, child: Icon(Icons.done, color: Colors.black)),
                  Expanded(
                    child: Text(
                      'We need and collect your Full name, Photo, Address, Date of birth',
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
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  SizedBox(width: 20, height: 20, child: Icon(Icons.done, color: Colors.black)),
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
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  SizedBox(width: 20, height: 20, child: Icon(Icons.done, color: Colors.black)),
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
              SizedBox(height: 20,),
              InkWell(
                onTap: () async {
                  // widget.onResponse(widget.idcard);
                  if (_image != null) {
                    setState(() {
                      stage = 1;
                    });
                    timercount();
                    final inputImage = InputImage.fromFilePath(_image!);
                    idcardinfo = await IDCardParser.extractInfoFromImage(inputImage,widget.idcard['name']);
                    // idnameController.text = "${info.firstName} ${info.lastName}";
                    // idnumberController.text = "${info.idNumber}";
                    // dobController.text = "${info.dateOfBirth}";
                    dev.log('Card details: ${idcardinfo.toString()}');
                    // result =
                    // 'First Name: ${info.firstName}\nLast Name: ${info.lastName}\nDOB: ${info.dateOfBirth}\nID Number: ${info.idNumber}';
                    setState(() {
                      stage = 2;
                    });
                  }
                },
                child: Opacity(
                  opacity: _image == null ? 0.05 : 1,
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
                    child: const Text(
                      'Continue',
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
              ),
            ],
          ):
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
                  'Extracting information...',
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
            width: 338,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                // if(debug)
                Image.file(File(idcardinfo!.faceImagePath!),
                  fit: BoxFit.fill,
                ),
                Text(
                  "Id Card Number: ${idcardinfo?.idNumber??""}",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                  ),
                ),
                Text(
                  "Name: ${idcardinfo?.firstName ?? ""} ${idcardinfo?.middleName ?? ""} ${idcardinfo?.lastName ?? ""}",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                  ),
                ),
                Text(
                  "Date of Birth: ${idcardinfo?.dateOfBirth??""}",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                  ),
                ),
                SizedBox(height: 20,),
                Center(
                  child: Text(
                    'If your information is wrong kindly recapture or click continue to proceed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFF5257),
                      fontSize: 12,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    File file = File(idcardinfo!.faceImagePath!);
                    widget.onResponse({
                      "bvnimage": base64Encode(file.readAsBytesSync()),
                      "number": idcardinfo!.idNumber,
                      "name": "${idcardinfo!.firstName} ${idcardinfo!.middleName} ${idcardinfo!.lastName}",
                      "procced": 2,
                      "message": "Extracted Successfully",
                    });
                  },
                  child: Opacity(
                    opacity: _image == null ? 0.05 : 1,
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
                      child: const Text(
                        'Continue',
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
                ),
              ],
            ),
          ),
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
      ),
    );
  }
}
