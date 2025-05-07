import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';

import '../models/checkout_response.dart';
import '../pages/loading.dart';
import 'cameraliveness.dart';
import 'diorequest.dart';

class VerificationController extends GetxController {
  final _name = "Paste".obs;
  set name(value) => _name.value = value;
  get name => _name.value;

  final _displaymessage = "".obs;
  set displaymessage(value) => _displaymessage.value = value;
  get displaymessage => _displaymessage.value;

  final _publicKey = "".obs;
  set publicKey(value) => _publicKey.value = value;
  get publicKey => _publicKey.value;

  final _secretKey = "".obs;
  set secretKey(value) => _secretKey.value = value;
  get secretKey => _secretKey.value;

  final _identifier = "".obs;
  set identifier(value) => _identifier.value = value;
  get identifier => _identifier.value;

  final _sdkInitialized = false.obs;
  set sdkInitialized(value) => _sdkInitialized.value = value;
  get sdkInitialized => _sdkInitialized.value;
  final _checked = false.obs;
  set checked(value) => _checked.value = value;
  get checked => _checked.value;
  var _checkoutmethod = CheckoutMethod.selectable.obs;
  set checkoutmethod(value) => _checkoutmethod.value = value;
  get checkoutmethod => _checkoutmethod.value;

  final _score = 0.0.obs;
  set score(value) => _score.value = value;
  get score => _score.value;

  TextEditingController bvnController = TextEditingController();

  final _stage = 0.obs;
  set stage(value) => _stage.value = value;
  get stage => _stage.value;

  final _verificationstatus = 0.obs;
  set verificationstatus(value) => _verificationstatus.value = value;
  get verificationstatus => _verificationstatus.value;

  final _bvnimage = "".obs;
  set bvnimage(value) => _bvnimage.value = value;
  get bvnimage => _bvnimage.value;

  final _captureimage = "".obs;
  set captureimage(value) => _captureimage.value = value;
  get captureimage => _captureimage.value;

  final _reference = "".obs;
  set reference(value) => _reference.value = value;
  get reference => _reference.value;

  final _enrollmentdata = "".obs;
  set enrollmentdata(value) => _enrollmentdata.value = value;
  get enrollmentdata => _enrollmentdata.value;

  Cameraliveness faceapi = Get.put(Cameraliveness());
  fetchdetails(BuildContext context) async {
    // loader(context, "Loading");
    var result = await diorequest().post(checmethod.toLowerCase(), {
      'number': bvnController.text,
    });
    // Navigator.pop(context);
    if (result["success"] == 1) {
      bvnimage = result['data']['image'];
      reference = result['data']["reference"];
      if (captureimage.toString().isNotEmpty) {
        compareimage(context);
      }
    } else {
      stage = 2;
      displaymessage = "Invalid $checmethod provided";
      verificationstatus = 0;
    }
  }

  final _width = 60.0.obs;
  set width(value) => _width.value = value;
  get width => _width.value;
  Timer? timer;
  compareimage(BuildContext context) async {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _incrementCount(),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Loading();
      },
    );
    var result = await faceapi.comparefaceKyc(captureimage, bvnimage);
    print("image compare result $result");
    score = result;
    postdetails(context);
  }

  postdetails(context) async {
    // loader(context, "Loading");
    var result = await diorequest().put(checmethod.toLowerCase(), {
      'number': bvnController.text,
      'reference': reference,
      'identifier': identifier,
      'confidence': score.toInt(),
      'image': captureimage,
    });
    Navigator.pop(context);
    if (result["success"] == 1) {
      stage = 2;
      timer?.cancel();
      enrollmentdata = result["data"];
      displaymessage =
          score > 50
              ? 'We have verified that the ID belongs to you($enrollmentdata). Thanks for your cooperation.'
              : "Your face did not match the $checmethod provided";
      verificationstatus = score > 50 ? 2 : 1;
    } else {
      displaymessage = "connection Error";
      stage = 2;
      verificationstatus = 0;
    }
  }

  String get checmethod {
    switch (checkoutmethod) {
      case CheckoutMethod.bvn:
        return "BVN";
      case CheckoutMethod.nin:
        return "NIN";
      default:
        return "Selectable";
    }
  }

  final _start = 5.obs; // Set your countdown start value here
  set start(value) => _start.value = value;
  get start => _start.value;
  Timer? _timer;

  void startTimer(context) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (start <= 0) {
        closedialog(context, "Verification Completed");
        _timer!.cancel();
      } else {
        start--;
      }
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
  }

  closedialog(context, message) {
    timer?.cancel();
    stage = 0;
    start = 5;
    checked = false;
    Navigator.pop(
      context,
      CheckoutResponse(
        message: message,
        name: enrollmentdata,
        reference: reference,
        status: verificationstatus > 0,
        method: checkoutmethod,
        verify: verificationstatus == 2,
        confidence_level: score,
        bvn: checkoutmethod == CheckoutMethod.bvn ? bvnController.text : null,
        nin: checkoutmethod == CheckoutMethod.nin ? bvnController.text : null,
      ),
    );
    bvnController.clear();
    captureimage = "";
    bvnimage = "";
  }
}
