import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_face_api/flutter_face_api.dart' hide LivenessException, LivenessErrorCode;
import 'package:image/image.dart' as img;
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

  /// Decodes image bytes, fixes orientation, and saves as a proper JPEG file
  Future<File> _createOrientedImageFile(Uint8List bytes, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$filename';
    
    // Decode the image using the image package
    final decodedImage = img.decodeImage(bytes);
    
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }
    
    // Fix orientation - the image package handles EXIF orientation automatically
    // when decoding. We also explicitly correct any remaining orientation issues.
    final orientedImage = img.bakeOrientation(decodedImage);
    
    // Encode as JPEG with good quality
    final jpegBytes = img.encodeJpg(orientedImage, quality: 95);
    
    // Write to file
    final file = File(filePath);
    await file.writeAsBytes(jpegBytes);
    
    return file;
  }


  var faceSdk = FaceSDK.instance;

  MatchFacesImage? mfImage1;
  MatchFacesImage? mfImage2;

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


  void setImage1(Uint8List bytes, ImageType type, int number) {
    var mfImage = MatchFacesImage(bytes, type);
    if (number == 1) {
      mfImage1 = mfImage;
    }
    if (number == 2) {
      mfImage2 = mfImage;
    }
  }

  Future<double> comparefaceKyc1(String image1, String image2) async {
    try {
      // Decode base64 strings to bytes
      Uint8List bytes1;
      Uint8List bytes2;
      
      try {
        final encoded1 = base64Decode(image1);
        bytes1 = Uint8List.fromList(encoded1);
      } catch (e) {
        // If base64 decode fails, assume it's already raw bytes encoded as string
        dev.log('Image 1 base64 decode failed, treating as raw data: $e');
        bytes1 = Uint8List.fromList(utf8.encode(image1));
      }
      
      try {
        final encoded2 = base64Decode(image2);
        bytes2 = Uint8List.fromList(encoded2);
      } catch (e) {
        dev.log('Image 2 base64 decode failed, treating as raw data: $e');
        bytes2 = Uint8List.fromList(utf8.encode(image2));
      }

      // Create properly oriented image files
      final file1 = await _createOrientedImageFile(bytes1, 'img1_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final file2 = await _createOrientedImageFile(bytes2, 'img2_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final input1 = InputImage.fromFile(file1);
      final input2 = InputImage.fromFile(file2);

      final results = await Future.wait([
        _faceService.detectFaces(input1),
        _faceService.detectFaces(input2),
      ]);
      
      // Check for empty results and return early
      if (results[0].isEmpty) {
        dev.log('No face detected in Image 1. Use an image with a clear face.');
        await _cleanupFiles([file1, file2]);
        return 0;
      }
      
      if (results[1].isEmpty) {
        dev.log('No face detected in Image 2. Use an image with a clear face.');
        await _cleanupFiles([file1, file2]);
        return 0;
      }
      
      final emb1 = results[0][0].faceEmbedding;
      final emb2 = results[1][0].faceEmbedding;

      // Clean up temp files
      await _cleanupFiles([file1, file2]);

      if (emb1 != null && emb2 != null) {
        final comparison = FaceDetectorService.compareFaces(emb1, emb2);

        dev.log(jsonEncode(comparison.toJson()));
        return comparison.similarityPercentage;
      } else {
        dev.log('Face embeddings could not be generated');
        return 0;
      }
    } catch (e) {
      dev.log('Comparison failed: $e');
      return 0;
    }
  }
  
  /// Clean up temporary files
  Future<void> _cleanupFiles(List<File> files) async {
    for (final file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        dev.log('Failed to delete temp file: $e');
      }
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