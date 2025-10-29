import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';

import '../models/IDCardInfo.dart';
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

  final _bvnNumber = Rx<String?>(null);
  set bvnNumber(value) => _bvnNumber.value = value;
  String? get bvnNumber => _bvnNumber.value;

  final _ninNumber = Rx<String?>(null);
  set ninNumber(value) => _ninNumber.value = value;
  String? get ninNumber => _ninNumber.value;

  final _identifier = "".obs;
  set identifier(value) => _identifier.value = value;
  get identifier => _identifier.value;

  final _sdkInitialized = false.obs;
  set sdkInitialized(value) => _sdkInitialized.value = value;
  get sdkInitialized => _sdkInitialized.value;
  final _checked = false.obs;
  set checked(value) => _checked.value = value;
  get checked => _checked.value;
  final _checkoutmethod = CheckoutMethod.selectable.obs;
  set checkoutmethod(value) {
    if (value == CheckoutMethod.facial) {
      stage = 1;
      facetitle = "Face Verification";
    } else if (value == CheckoutMethod.idcard) {
      stage = 3;
      initializeCamera();
    } else {
      stage = 0;
    }
    _checkoutmethod.value = value;
  }

  get checkoutmethod => _checkoutmethod.value;

  final _directcheckout = false.obs;
  set directcheckout(value) => _directcheckout.value = value;
  get directcheckout => _directcheckout.value;

  final _score = 0.0.obs;
  set score(value) => _score.value = value;
  get score => _score.value;

  TextEditingController bvnController = TextEditingController(
    text: "00000000000000",
  );

  TextEditingController idnameController = TextEditingController(text: "00");
  TextEditingController idnumberController = TextEditingController(text: "00");
  TextEditingController dobController = TextEditingController(
    text: "00/00/0000",
  );

  final _stage = 0.obs;
  set stage(value) => _stage.value = value;
  get stage => _stage.value;

  final _verificationstatus = 0.obs;
  set verificationstatus(value) => _verificationstatus.value = value;
  get verificationstatus => _verificationstatus.value;

  final _bvnimage = "".obs;
  set bvnimage(value) => _bvnimage.value = value;
  get bvnimage => _bvnimage.value;

  final _facetitle = "Face Recognition".obs;
  set facetitle(value) => _facetitle.value = value;
  get facetitle => _facetitle.value;

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
    Future.delayed(const Duration(milliseconds: 50), () {
      loading(context);
    });
    var result = await diorequest().post(checmethod.toLowerCase(), {
      'number': bvnController.text,
      'identifier': identifier,
    });
    Navigator.pop(context);
    if (result["success"] == 1) {
      var image = result['data']['image'];
      if (isUrl(image)) {
        bvnimage = await urlToBase64(image);
      } else {
        // Assume it's already base64
        bvnimage = image;
      }
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

  // Returns true if the string is a URL
  bool isUrl(String str) {
    final urlPattern = r'^(http|https):\/\/';
    return RegExp(urlPattern, caseSensitive: false).hasMatch(str);
  }

  // Converts image URL to base64 string
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

  final _width = 60.0.obs;
  set width(value) => _width.value = value;
  get width => _width.value;
  Timer? timer;

  loading(BuildContext context) {
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
  }

  compareimage(BuildContext context) async {
    var result = await faceapi.comparefaceKyc(captureimage, bvnimage);
    // dev.log("image compare result $result");
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
      case CheckoutMethod.facial:
        return "FACIAL";
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

  final _cameracontroller = Rx<CameraController?>(null);
  set cameracontroller(value) => _cameracontroller.value = value;
  CameraController? get cameracontroller => _cameracontroller.value;

  final _cameras = <CameraDescription>[].obs;
  set cameras(value) => _cameras.value = value;
  get cameras => _cameras;
  final _result = ''.obs;
  set result(value) => _result.value = value;
  get result => _result.value;

  Future<void> captureAndExtract() async {
    if (cameracontroller == null || !cameracontroller!.value.isInitialized)
      return;
    final image = await cameracontroller!.takePicture();
    final inputImage = InputImage.fromFilePath(image.path);
    final info = await IDCardParser.extractInfoFromImage(inputImage);
    idnameController.text = "${info.firstName} ${info.lastName}";
    idnumberController.text = "${info.idNumber}";
    dobController.text = "${info.dateOfBirth}";
    // dev.log('First Name: ${info.firstName}');
    // dev.log('Last Name: ${info.lastName}');
    // dev.log('DOB: ${info.dateOfBirth}');
    // dev.log('ID Number: ${info.idNumber}');
    result =
        'First Name: ${info.firstName}\nLast Name: ${info.lastName}\nDOB: ${info.dateOfBirth}\nID Number: ${info.idNumber}';
    stage = 3;
  }

  Future<void> pickAndExtractIDCardInfo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final info = await IDCardParser.extractInfoFromImage(inputImage);

      // dev.log('First Name: ${info.firstName}');
      // dev.log('Last Name: ${info.lastName}');
      // dev.log('DOB: ${info.dateOfBirth}');
      // dev.log('ID Number: ${info.idNumber}');
      // Show these in your UI as needed
      result =
          'First Name: ${info.firstName}\nLast Name: ${info.lastName}\nDOB: ${info.dateOfBirth}\nID Number: ${info.idNumber}';
    }
  }

  initializeCamera() {
    availableCameras().then((camera) {
      cameras = camera;
      if (cameras.isNotEmpty) {
        cameracontroller = CameraController(
          cameras[0],
          ResolutionPreset.medium,
        );
        cameracontroller!.initialize().then((_) {
          name = "Paste";
          update();
        });
      }
    });
  }
}
