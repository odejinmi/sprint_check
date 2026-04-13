import 'dart:convert';
import 'dart:developer' as dev;

// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_face_api/flutter_face_api.dart' hide LivenessException, LivenessErrorCode;
import 'package:sprintliveness/sprintliveness.dart';
import 'package:sprintliveness/model/liveness_response.dart';
import 'package:permission_handler/permission_handler.dart';

class NewCameraliveness {

  NewCameraliveness() {
    initialize();
  }

  final _sprintlivenessPlugin = Sprintliveness();
  Future<FaceCaptureImage?> takepicture() async {
    var response = await faceSdk.startFaceCapture();
    return response.image;
  }

  Future<double> comparefaceKyc(String image1, String image2) async {
    var encoded1 = base64Decode(image1);
    var bytes1 = Uint8List.fromList(encoded1);
    var encoded2 = base64Decode(image2);
    var bytes2 = Uint8List.fromList(encoded2);
    setImage1(bytes1, ImageType.EXTERNAL, 1);
    setImage1(bytes2, ImageType.EXTERNAL, 2);

    var request = MatchFacesRequest([mfImage1!, mfImage2!]);
    var response = await faceSdk.matchFaces(request);
    var split = await faceSdk.splitComparedFaces(response.results, 0.75);
    var match = split.matchedFaces;
    if (match.isNotEmpty) {
      return (match[0].similarity * 100);
    } else {
      return 0;
    }
  }

  var faceSdk = FaceSDK.instance;

  MatchFacesImage? mfImage1;
  MatchFacesImage? mfImage2;


  Future<LivenessResult?> startLiveness(BuildContext context) async {
    dev.log("start liveness");
    var livenessResult = await _sprintlivenessPlugin.startLivenessCheck(context);
    dev.log("liveness result: $livenessResult");
    return livenessResult;
  }
  // Future<LivenessResponse?> startLiveness() async {
  //   dev.log("start liveness");
  //   var result = await faceSdk.startLiveness(
  //     config: LivenessConfig(skipStep: [LivenessSkipStep.ONBOARDING_STEP]),
  //     notificationCompletion: (notification) {
  //       // dev.log(notification.status);
  //     },
  //   );
  //   return result;
  // }

  // matchFaces1() async {
  //   if (mfImage1 == null || mfImage2 == null) {
  //     return;
  //   }
  //   var request = MatchFacesRequest([mfImage1!, mfImage2!]);
  //   var response = await faceSdk.matchFaces(request);
  //   var split = await faceSdk.splitComparedFaces(response.results, 0.75);
  // }

  Future<bool> initialize() async {
    dev.log("initializing");
    var license = await loadAssetIfExists("assets/regula.license");
    InitConfig? config;
    if (license != null) config = InitConfig(license);
    var (success, error) = await faceSdk.initialize(config: config);
    if (!success) {
      // status = error!.message;
    }
    return success;
  }

  Future<ByteData?> loadAssetIfExists(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

  void setImage1(Uint8List bytes, ImageType type, int number) {
    var mfImage = MatchFacesImage(bytes, type);
    if (number == 1) {
      mfImage1 = mfImage;
    }
    if (number == 2) {
      mfImage2 = mfImage;
    }
  }
}