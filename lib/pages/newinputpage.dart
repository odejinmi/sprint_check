import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../common/digits_only_formatter.dart';
import '../common/diorequest.dart';
import '../models/charge.dart';
import '../sprint_check_method_channel.dart';

class Newinputpage extends StatefulWidget {
  final String publicKey;
  final String secretKey;
  final Charge charge;
  final CheckoutMethod checkoutmethod;
  final Function(Map<String, dynamic>) onResponse;
  const Newinputpage({super.key, required this.charge, required this.checkoutmethod, required this.onResponse, required this.publicKey, required this.secretKey});

  @override
  State<Newinputpage> createState() => _NewinputpageState();
}

class _NewinputpageState extends State<Newinputpage> {


  TextEditingController bvnController = TextEditingController();
  Timer? timer;
  double width = 155.0;

  bool success = false;
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
  String get title {
    switch (widget.checkoutmethod) {
      case CheckoutMethod.bvn:
        return "Bank Verification Number \n(BVN)";
      case CheckoutMethod.nin:
        return "National Identification Number \n(NIN)";
      case CheckoutMethod.facial:
        return "FACIAL";
      default:
        return "Selectable";
    }
  }
  String get checmethod {
    switch (widget.checkoutmethod) {
      case CheckoutMethod.bvn:
        return "BVN";
      case CheckoutMethod.nin:
        return "NIN";
      case CheckoutMethod.facial:
        return "FACIAL";
      default:
        return "Selectable";
    }
  }

  int stage = 0;
  var bvnimage = "";
  var reference = "";
  var message = "";
  int procced = 1;
//22314756491
  Future<void> fetchdetails() async {
    timercount();
      stage = 1;
      setState(() {

      });
    var result = await Diorequest().post(checmethod.toLowerCase(), {
      'number': bvnController.text,
      'identifier': widget.charge.identifier,
    }, widget.publicKey, widget.secretKey);
    stage = 2;
    timer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {

    });
    // var result = {"success":1,"message":"Verified Successfully","confidence_level":"80","data":{"image":"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","reference":"3c46d0c1-0855-42b4-88db-cece7aca6665"}};
    if (result["success"] == 1) {
      procced = 1;
      message = result["message"];
      success = true;
      var image = result['data']['image'];
      if (isUrl(image)) {
         bvnimage = await urlToBase64(image);
      } else {
        // Assume it's already base64
         bvnimage = image;
      }
       reference = result['data']["reference"];
    } else {
      message = result["message"];
      procced = 2;
      success = false;
      // stage = 2;
      // displaymessage = "Invalid $checmethod provided";
      // verificationstatus = 0;
    }
    setState(() {

    });
  }
  bool isUrl(String str) {
    final urlPattern = r'^(http|https):\/\/';
    return RegExp(urlPattern, caseSensitive: false).hasMatch(str);
  }
  Future<String> urlToBase64(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // dev.log(response.bodyBytes);
      Uint8List bytes = response.bodyBytes;
      return base64Encode(bytes);
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  void initState() {
    if(widget.checkoutmethod == CheckoutMethod.facial){
      bvnController.text = "0000000";
      fetchdetails();
    }else
   if ((widget.charge.bvn != null && widget.charge.bvn!.isNotEmpty) || (widget.charge.nin != null && widget.charge.nin!.isNotEmpty)) {
     bvnController.text = widget.charge.bvn ?? widget.charge.nin ?? "";
     fetchdetails();
   }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
              stage == 0 ?
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title ',
                    style: TextStyle(
                      color: const Color(0xFF181619),
                      fontSize: 18,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.78,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    autofillHints: [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      hintText: "Enter your ${checmethod.toLowerCase()}",
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        borderSide: BorderSide(color: Color(0xFFE1E1E1)),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        borderSide: BorderSide(color: Color(0xFFE1E1E1)),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // ⬅️ This ensures only digits are allowed
                      DigitsOnlyFormatter(),
                    ],
                    controller: bvnController,
                    onChanged: (value) {
                      setState(() {

                      });
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Kindly input your $checmethod";
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 20, height: 20, child: Icon(Icons.done, size: 20, color: Colors.black)),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'We need and collect your Full name, Phone number, Date of birth',
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
                      SizedBox(height: 25),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 20, height: 20, child: Icon(Icons.done, size: 20, color: Colors.black)),
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
                    ],
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
                      'Validation ${success? "Successful" : "Failed"}',
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
              onTap: () {
                if (stage == 0) {
                  if (bvnController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter your $checmethod')),
                    );
                    return;
                  }
                  fetchdetails();
                } else if (stage == 2) {
                  widget.onResponse({
                    "bvnimage": bvnimage,
                    "reference": reference,
                    "number": bvnController.text,
                    "procced": procced,
                    "message": message,
                  });
                }
              },
              child: Opacity(
                opacity: stage == 1|| bvnController.text.length < 11 ? 0.05 : 1,
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
        ),
      ),
    );
  }
}
