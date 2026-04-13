import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_face_api/flutter_face_api.dart' hide LivenessException, LivenessErrorCode;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sprintliveness/sprintliveness.dart';
import 'package:sprintliveness/model/liveness_response.dart';

import '../sdk/face_detector_service.dart';

class NewCameraliveness {

  NewCameraliveness() {
    // initialize();
  }

  final _sprintlivenessPlugin = Sprintliveness();
  // Future<FaceCaptureImage?> takepicture() async {
  //   var response = await faceSdk.startFaceCapture();
  //   return response.image;
  // }

  // Future<double> comparefaceKyc(String image1, String image2) async {
  //   var encoded1 = base64Decode(image1);
  //   var bytes1 = Uint8List.fromList(encoded1);
  //   var encoded2 = base64Decode(image2);
  //   var bytes2 = Uint8List.fromList(encoded2);
  //   setImage1(bytes1, ImageType.EXTERNAL, 1);
  //   setImage1(bytes2, ImageType.EXTERNAL, 2);
  //
  //   var request = MatchFacesRequest([mfImage1!, mfImage2!]);
  //   var response = await faceSdk.matchFaces(request);
  //   var split = await faceSdk.splitComparedFaces(response.results, 0.75);
  //   var match = split.matchedFaces;
  //   if (match.isNotEmpty) {
  //     return (match[0].similarity * 100);
  //   } else {
  //     return 0;
  //   }
  // }

  final FaceDetectorService _faceService = FaceDetectorService();
  List<FaceDetectionResult> _results1 = [];
  List<FaceDetectionResult> _results2 = [];
  FaceComparisonResult? _comparisonResult;

  Future<double> comparefaceKyc(String image1, String image2) async {
    var encoded1 = base64Decode(image1);
    var bytes1 = Uint8List.fromList(encoded1);
    var encoded2 = base64Decode(image2);
    var bytes2 = Uint8List.fromList(encoded2);

    try {
      final input1 = InputImage.fromBytes(bytes: bytes1, metadata: bytes1);
      final input2 = InputImage.fromBytes(bytes: bytes2, metadata: bytes2)

      final results = await Future.wait([
        _faceService.detectFaces(input1),
        _faceService.detectFaces(input2),
      ]);

      _results1 = results[0];
      _results2 = results[1];

      // if (_results1.isEmpty || _results2.isEmpty) {
      //   setState(() {
      //     _error = 'No face detected in ${_results1.isEmpty ? "Image 1" : ""}${_results1.isEmpty && _results2.isEmpty ? " and " : ""}${_results2.isEmpty ? "Image 2" : ""}. Use images with clear faces.';
      //   });
      //   return;
      // }

      final emb1 = _results1[0].faceEmbedding;
      final emb2 = _results2[0].faceEmbedding;

      if (emb1 != null && emb2 != null) {
        final comparison = FaceDetectorService.compareFaces(emb1, emb2);

        dev.log(jsonEncode(comparison.toJson()));
        // setState(() => _comparisonResult = comparison);
        // _animController.forward(from: 0);
      }
    } catch (e) {
      // setState(() => _error = 'Comparison failed: $e');
    } finally {
      // setState(() => _isLoading = false);
    }
    return 30;
  }

  var faceSdk = FaceSDK.instance;

  MatchFacesImage? mfImage1;
  MatchFacesImage? mfImage2;


  Future<LivenessResult?> startLiveness(BuildContext context) async {
    var livenessResult = await _sprintlivenessPlugin.startLivenessCheck(context);
    dev.log(livenessResult.image!);
    return livenessResult;
  }

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