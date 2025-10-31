import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'extractDriverLicense.dart';
import 'extractnational.dart';

class IDCardInfo {
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? dateOfBirth;
  final String? idNumber;
  final String? extracteddetails;
  final String? faceImagePath; // New field for the cropped face

  IDCardInfo({
    this.firstName,
    this.lastName,
    this.middleName,
    this.dateOfBirth,
    this.idNumber,
    this.faceImagePath,
    this.extracteddetails,
  });

  // copyWith method to easily add the face image path later
  IDCardInfo copyWith({
    String? firstName,
    String? lastName,
    String? middleName,
    String? dateOfBirth,
    String? idNumber,
    String? faceImagePath,
    String? extracteddetails,
  }) {
    return IDCardInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idNumber: idNumber ?? this.idNumber,
      faceImagePath: faceImagePath ?? this.faceImagePath,
      extracteddetails: extracteddetails ?? this.extracteddetails,
    );
  }

  @override
  toString() =>
      'IDCardInfo(firstName: $firstName, lastName: $lastName, middleName: $middleName, dateOfBirth: $dateOfBirth, idNumber: $idNumber, faceImagePath: $faceImagePath, extracteddetails: $extracteddetails)';
}

class IDCardParser {
  static Future<IDCardInfo> extractInfoFromImage(
      InputImage image, String cardType) async {
    // --- 1. TEXT RECOGNITION ---
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(image);
    final lines = <String>[];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        lines.add(line.text.trim());
      }
    }

    // --- 2. CARD-SPECIFIC TEXT EXTRACTION ---
    IDCardInfo idCardInfo = IDCardInfo();
    switch (cardType) {
      case "Voter's Card":
        idCardInfo = await extractVoter(lines);
        break;
      case 'Internation Passport':
        idCardInfo = await ExtractNational.extractnational(lines);
        break;
      case 'National identity card':
        idCardInfo = await extractNIN(lines);
        break;
      case "Driver's License":
        idCardInfo = await ExtractDriverLicense.extractDriverLicense(lines);
        break;
      case 'nimc':
        idCardInfo = await extractnimc(lines);
        break;
      case 'ninslip':
        idCardInfo = await extractNINslip(lines);
        break;
      case 'digitalninslip':
        idCardInfo = await extractDigitalNINslip(lines);
        break;
      default:
        idCardInfo = await extractunknown(lines);
        break;
    }

    // --- 3. FACE DETECTION AND CROPPING ---
    String? croppedFacePath;
    final imageBytes = image.bytes ?? (image.filePath != null ? await File(image.filePath!).readAsBytes() : null);
    
    if (imageBytes != null) {
      try {
        final faceDetector = FaceDetector(options: FaceDetectorOptions());
        final List<Face> faces = await faceDetector.processImage(image);

        if (faces.isNotEmpty) {
          faces.sort((a, b) => b.boundingBox.width.compareTo(a.boundingBox.width));
          final Face largestFace = faces.first;

          final originalImage = img.decodeImage(imageBytes);

          if (originalImage != null) {
            final x = (largestFace.boundingBox.left - 20).clamp(0, originalImage.width).toInt();
            final y = (largestFace.boundingBox.top - 20).clamp(0, originalImage.height).toInt();
            final w = (largestFace.boundingBox.width + 40).clamp(0, originalImage.width - x).toInt();
            final h = (largestFace.boundingBox.height + 40).clamp(0, originalImage.height - y).toInt();

            final croppedFace = img.copyCrop(originalImage, x: x, y: y, width: w, height: h);

            final tempDir = await getTemporaryDirectory();
            final file = await File('${tempDir.path}/face_crop${DateTime.now().millisecondsSinceEpoch}.jpg').create();
            file.writeAsBytesSync(img.encodeJpg(croppedFace));
            croppedFacePath = file.path;
          }
        }
        await faceDetector.close();
      } catch (e) {
        print('Error cropping face from ID card: $e');
      }
    }

    // --- 4. RETURN COMBINED INFO ---
    return idCardInfo.copyWith(faceImagePath: croppedFacePath);
  }
  
  static Future<IDCardInfo> extractVoter(List<String> lines) async {
    // This function will be implemented based on Voter's card specifics
    return IDCardInfo();
  }

  static Future<IDCardInfo> extractNIN(List<String> lines) async {
    // This function will be implemented based on NIN specifics
     return IDCardInfo();
  }
  

  static Future<IDCardInfo> extractnimc(List<String> lines) async {
    // This function will be implemented based on NIMC specifics
     return IDCardInfo();
  }

  static Future<IDCardInfo> extractNINslip(List<String> lines) async {
    // This function will be implemented based on NIN Slip specifics
     return IDCardInfo();
  }

  static Future<IDCardInfo> extractDigitalNINslip(List<String> lines) async {
    // This function will be implemented based on Digital NIN Slip specifics
     return IDCardInfo();
  }

  static Future<IDCardInfo> extractunknown(List<String> lines) async {
    // This function will be a generic fallback
     return IDCardInfo();
  }
}
