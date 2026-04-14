import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sprintliveness/sprintliveness.dart';
import 'package:sprintliveness/model/liveness_response.dart';

import '../sdk/face_detector_service.dart';

class NewCameraliveness {

  NewCameraliveness() {
    // initialize();
    _initModels();
  }


  Future<void> _initModels() async {
    try {
      await _faceService.initialize();
      // setState(() => _modelsReady = true);
    } catch (e) {
      dev.log( 'Failed to initialize: $e');
    }
  }

  final _sprintlivenessPlugin = Sprintliveness();

  final FaceDetectorService _faceService = FaceDetectorService();

  Future<double> comparefaceKyc(String image1, String image2) async {
    var encoded1 = base64Decode(image1);
    var bytes1 = Uint8List.fromList(encoded1);
    var encoded2 = base64Decode(image2);
    var bytes2 = Uint8List.fromList(encoded2);

    try {
      final tempDir = await getTemporaryDirectory();

    final file1 = File('${tempDir.path}/img1.jpg');
    await file1.writeAsBytes(bytes1);
    final file2 = File('${tempDir.path}/img2.jpg');
    await file2.writeAsBytes(bytes2);

    final input1 = InputImage.fromFile(file1);
    final input2 = InputImage.fromFile(file2);

      final results = await Future.wait([
        _faceService.detectFaces(input1),
        _faceService.detectFaces(input2),
      ]);
      if (results[0].isEmpty || results[1].isEmpty) {
          print('No face detected in ${results[0].isEmpty ? "Image 1" : ""}${results[0].isEmpty && results[1].isEmpty ? " and " : ""}${results[1].isEmpty ? "Image 2" : ""}. Use images with clear faces.');
      }
      final emb1 = results[0][0].faceEmbedding;
      final emb2 = results[1][0].faceEmbedding;

      if (emb1 != null && emb2 != null) {
        print("object");
        final comparison = FaceDetectorService.compareFaces(emb1, emb2);

        dev.log(jsonEncode(comparison.toJson()));
        // setState(() => _comparisonResult = comparison);
        // _animController.forward(from: 0);
        return comparison.similarityPercentage;
      }else{
        return 0;
      }
    } catch (e) {
      // setState(() => _error = 'Comparison failed: $e');
      return 0;
    } finally {
      // setState(() => _isLoading = false);
    }
  }


  Future<LivenessResult?> startLiveness(BuildContext context) async {
    var livenessResult = await _sprintlivenessPlugin.startLivenessCheck(context);
    dev.log(livenessResult.image!);
    return livenessResult;
  }


  Future<ByteData?> loadAssetIfExists(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

}