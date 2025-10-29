import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_face_api/flutter_face_api.dart';
import 'package:get/get.dart';

class Cameraliveness extends GetxController {
  @override
  Future<void> onInit() async {
    super.onInit();

    if (!await initialize()) return;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Future<FaceCaptureImage?> takepicture() async {
    var response = await faceSdk.startFaceCapture();
    return response.image;
  }

  Future<double> comparefaceKyc(image1, image2) async {
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
      // var similarityStatus =
      //     (match[0].similarity * 100).toStringAsFixed(2) + "%";
      // if ((match[0].similarity * 100) > 70) {
      //   return (match[0].similarity * 100);
      // } else {
      return (match[0].similarity * 100);
      // }
    } else {
      return 0;
    }
  }

  var faceSdk = FaceSDK.instance;

  MatchFacesImage? mfImage1;
  MatchFacesImage? mfImage2;

  Future<LivenessResponse?> startLiveness() async {
    var result = await faceSdk.startLiveness(
      config: LivenessConfig(skipStep: [LivenessSkipStep.ONBOARDING_STEP]),
      notificationCompletion: (notification) {
        // dev.log(notification.status);
      },
    );
    return result;
  }

  matchFaces1() async {
    if (mfImage1 == null || mfImage2 == null) {
      // status = "Both images required!";
      return;
    }
    // status = "Processing...";
    var request = MatchFacesRequest([mfImage1!, mfImage2!]);
    var response = await faceSdk.matchFaces(request);
    var split = await faceSdk.splitComparedFaces(response.results, 0.75);
    var match = split.matchedFaces;
    if (match.isNotEmpty) {
      // similarityStatus = (match[0].similarity * 100).toStringAsFixed(2) + "%";
    }
    // status = "Ready";
  }

  // If 'assets/regula.license' exists, init using license(enables offline match)
  // otherwise init without license.
  Future<bool> initialize() async {
    // status = "Initializing...";
    var license = await loadAssetIfExists("assets/regula.license");
    InitConfig? config = null;
    if (license != null) config = InitConfig(license);
    var (success, error) = await faceSdk.initialize(config: config);
    if (!success) {
      // status = error!.message;
      // dev.log("${error!.code}: ${error.message}");
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

  setImage1(Uint8List bytes, ImageType type, int number) {
    var mfImage = MatchFacesImage(bytes, type);
    if (number == 1) {
      mfImage1 = mfImage;
    }
    if (number == 2) {
      mfImage2 = mfImage;
    }
  }
}
