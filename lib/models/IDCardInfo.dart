import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'extractDriverLicense.dart';
import 'extractVoter.dart';
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
        idCardInfo = await ExtractVoter.extractVoter(lines);
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

  static Future<IDCardInfo> extractNIN(List<String> lines) async {
    var idNumber;
    var firstName;
    var lastName;
    var middleName;
    var dob;
    var fullName;

    // NIN SLIP LOGIC
    // ID Number
    for (final line in lines) {
      final text = line.toUpperCase();
      if (text.startsWith('NIN')) {
        final parts = line.split(':');
        String candidate =
        (parts.length > 1) ? parts[1].replaceAll(RegExp(r'\D'), '') : '';
        if (candidate.isEmpty) {
          final nextIdx = lines.indexOf(line) + 1;
          if (nextIdx < lines.length) {
            candidate = lines[nextIdx].replaceAll(RegExp(r'\D'), '').trim();
          }
        }
        if (candidate.isNotEmpty) {
          idNumber = candidate;
          break;
        }
      }
    }
    if (idNumber == null) {
      for (int i = 0; i < lines.length - 1; i++) {
        final line1Raw = lines[i];
        var line2Raw = lines[i + 1];
        if (line2Raw.length > 4) {
          line2Raw = line2Raw.substring(4);
        } else {
          line2Raw = '';
        }
        if (RegExp(r'^[0-9 ]+$').hasMatch(line1Raw) &&
            RegExp(r'^[0-9 ]+$').hasMatch(line2Raw)) {
          final combined = (line1Raw + line2Raw).replaceAll(' ', '');
          if (combined.length >= 16) {
            idNumber = combined;
            break;
          }
        }
      }
      String digitsOnly = lines.join(' ').replaceAll(RegExp(r'[^0-9]'), ' ');
      final idCandidates =
      digitsOnly.split(' ').where((s) => s.length >= 10).toList();
      idCandidates.sort((a, b) => b.length.compareTo(a.length));
      if (idCandidates.isNotEmpty) {
        idNumber = idCandidates.first;
      }
    }
    // Name
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.startsWith('SURNAME')) {
        lastName = line.split(' ').last.trim();
      } else if (upper.startsWith('FIRST NAME')) {
        firstName = line.split(' ').last.trim();
      } else if (upper.startsWith('MIDDLE NAME')) {
        middleName = line.split(' ').last.trim();
      }
    }
    // DOB
    final dobRegex = RegExp(
      r'(\d{2})[ /-]([A-Z]{3})[ /-](\d{2,4})|(\d{2})[ /-](\d{2})[ /-](\d{2,4})',
    );
    for (final line in lines) {
      final match = dobRegex.firstMatch(line.toUpperCase());
      if (match != null) {
        if (match.group(2) != null) {
          final day = match.group(1);
          final monStr = match.group(2);
          final year = match.group(3);
          final months = {
            'JAN': '01',
            'FEB': '02',
            'MAR': '03',
            'APR': '04',
            'MAY': '05',
            'JUN': '06',
            'JUL': '07',
            'AUG': '08',
            'SEP': '09',
            'OCT': '10',
            'NOV': '11',
            'DEC': '12',
          };
          final mon = months[monStr] ?? monStr;
          dob = '$day-$mon-$year';
        } else if (match.group(4) != null &&
            match.group(5) != null &&
            match.group(6) != null) {
          dob = '${match.group(4)}-${match.group(5)}-${match.group(6)}';
        }
        break;
      }
    }
    return IDCardInfo(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dob,
      idNumber: idNumber,
    );
  }


  static Future<IDCardInfo> extractnimc(List<String> lines) async {
    var idNumber;
    var firstName;
    var lastName;
    var middleName;
    var dob;
    var fullName;

    // NIMC card number extraction with duplicate group handling
    List<String> digitLines =
    lines
        .where((l) => RegExp(r'^[0-9 ]{6,}$').hasMatch(l.trim()))
        .toList();
    if (digitLines.length >= 2) {
      var firstLine = digitLines[0].replaceAll(' ', '');
      var secondLine = digitLines[1].replaceAll(' ', '');
      var firstGroups = digitLines[0].trim().split(' ');
      var lastGroup = firstGroups.isNotEmpty ? firstGroups.last : '';
      if (lastGroup.isNotEmpty &&
          digitLines[1].trim().startsWith(lastGroup)) {
        // Remove the duplicate group from the start of second line
        var dedupedSecond =
        digitLines[1].trim().substring(lastGroup.length).trim();
        idNumber = (digitLines[0] + ' ' + dedupedSecond).replaceAll(' ', '');
      } else {
        idNumber = (digitLines[0] + digitLines[1]).replaceAll(' ', '');
      }
    }

    // Name extraction for NIMC: always use the value after the label
    String? tempSurname, tempFirstName, tempMiddleName;
    for (int i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase().trim();
      if (upper == 'SURNAME' && i + 1 < lines.length) {
        tempSurname = lines[i + 1].trim();
      } else if (upper == 'FIRST NAME' && i + 1 < lines.length) {
        tempFirstName = lines[i + 1].trim();
      } else if (upper == 'MIDDLE NAME' && i + 1 < lines.length) {
        tempMiddleName = lines[i + 1].trim();
      }
    }
    if (tempSurname != null) lastName = tempSurname;
    if (tempFirstName != null) firstName = tempFirstName;
    if (tempMiddleName != null) middleName = tempMiddleName;

    // DOB
    final dobRegex = RegExp(
      r'(\d{2})[ /-]([A-Z]{3})[ /-](\d{2,4})|(\d{2})[ /-](\d{2})[ /-](\d{2,4})',
    );
    for (final line in lines) {
      final match = dobRegex.firstMatch(line.toUpperCase());
      if (match != null) {
        if (match.group(2) != null) {
          final day = match.group(1);
          final monStr = match.group(2);
          final year = match.group(3);
          final months = {
            'JAN': '01',
            'FEB': '02',
            'MAR': '03',
            'APR': '04',
            'MAY': '05',
            'JUN': '06',
            'JUL': '07',
            'AUG': '08',
            'SEP': '09',
            'OCT': '10',
            'NOV': '11',
            'DEC': '12',
          };
          final mon = months[monStr] ?? monStr;
          dob = '$day-$mon-$year';
        } else if (match.group(4) != null &&
            match.group(5) != null &&
            match.group(6) != null) {
          dob = '${match.group(4)}-${match.group(5)}-${match.group(6)}';
        }
        break;
      }
    }
    return IDCardInfo(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dob,
      idNumber: idNumber,
    );
  }

  static Future<IDCardInfo> extractNINslip(List<String> lines) async {
    var idNumber;
    var firstName;
    var lastName;
    var middleName;
    var dob;
    var fullName;
    String? tempSurname, tempFirstName, tempMiddleName, tempDob, tempIdNumber;

    // DOB
    final dobRegex = RegExp(
      r'(\d{2})[ /-]([A-Z]{3})[ /-](\d{2,4})|(\d{2})[ /-](\d{2})[ /-](\d{2,4})',
    );
    for (int i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase().trim();

      final match = dobRegex.firstMatch(upper);

      // Surname
      if ((upper.contains('SURNAME') && !upper.contains('GIVEN')) ||
          upper.contains('SURNAME / NOM')) {
        if (i + 1 < lines.length) tempSurname = lines[i + 3].trim();
      }
      // Given Names
      else if (upper.contains('GIVEN NAMES') ||
          upper.contains('GIVEN NAMES / PRÉNOMS') ||
          upper.contains('PRÉNOMS') ||
          upper.contains('Glven Names/ Prénoms')) {
        if (i + 1 < lines.length) {
          var names = lines[i + 1].trim().split(RegExp(r'\s+'));
          if (names.isNotEmpty) tempFirstName = names[0];
          if (names.length > 1) tempMiddleName = names.sublist(1).join(' ');
        }
      }
      // Date of Birth
      else if (match != null) {
        if (match.group(2) != null) {
          final day = match.group(1);
          final monStr = match.group(2);
          final year = match.group(3);
          final months = {
            'JAN': '01',
            'FEB': '02',
            'MAR': '03',
            'APR': '04',
            'MAY': '05',
            'JUN': '06',
            'JUL': '07',
            'AUG': '08',
            'SEP': '09',
            'OCT': '10',
            'NOV': '11',
            'DEC': '12',
          };
          final mon = months[monStr] ?? monStr;
          dob = '$day-$mon-$year';
        } else if (match.group(4) != null &&
            match.group(5) != null &&
            match.group(6) != null) {
          dob = '${match.group(4)}-${match.group(5)}-${match.group(6)}';
        }
      }
      // Passport No.
      else if (upper.contains('NGA')) {
        // dev.log('PASSPORT NO');
        // dev.log(lines[i]);
        // dev.log(lines[i + 1]);
        if (i + 1 < lines.length) tempIdNumber = lines[i + 1].trim();
      }
    }

    if (tempSurname != null) lastName = tempSurname;
    if (tempFirstName != null) firstName = tempFirstName;
    if (tempMiddleName != null) middleName = tempMiddleName;
    if (tempIdNumber != null) idNumber = tempIdNumber;
    return IDCardInfo(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dob,
      idNumber: idNumber,
    );
  }

  static Future<IDCardInfo> extractDigitalNINslip(List<String> lines) async {
    var idNumber;
    var firstName;
    var lastName;
    var middleName;
    var dob;
    var fullName;
    String? tempSurname, tempFirstName, tempMiddleName, tempDob, tempIdNumber;

    // DOB
    final dobRegex = RegExp(
      r'(\d{2})[ /-]([A-Z]{3})[ /-](\d{2,4})|(\d{2})[ /-](\d{2})[ /-](\d{2,4})',
    );
    for (int i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase().trim();

      final match = dobRegex.firstMatch(upper);

      // Surname
      if ((upper.contains('SURNAME') && !upper.contains('GIVEN')) ||
          upper.contains('SURNAME / NOM')) {
        if (i + 1 < lines.length) tempSurname = lines[i + 1].trim();
      }
      // Given Names
      else if (upper.contains('GIVEN NAMES') ||
          upper.contains('GIVEN NAMES / PRÉNOMS') ||
          upper.contains('PRÉNOMS') ||
          upper.contains('Glven Names/ Prénoms')) {
        if (i + 1 < lines.length) {
          var names = lines[i + 1].trim().split(RegExp(r'\s+'));
          if (names.isNotEmpty) tempFirstName = names[0];
          if (names.length > 1) tempMiddleName = names.sublist(1).join(' ');
        }
      }
      // Date of Birth
      else if (match != null) {
        if (match.group(2) != null) {
          final day = match.group(1);
          final monStr = match.group(2);
          final year = match.group(3);
          final months = {
            'JAN': '01',
            'FEB': '02',
            'MAR': '03',
            'APR': '04',
            'MAY': '05',
            'JUN': '06',
            'JUL': '07',
            'AUG': '08',
            'SEP': '09',
            'OCT': '10',
            'NOV': '11',
            'DEC': '12',
          };
          final mon = months[monStr] ?? monStr;
          dob = '$day-$mon-$year';
        } else if (match.group(4) != null &&
            match.group(5) != null &&
            match.group(6) != null) {
          dob = '${match.group(4)}-${match.group(5)}-${match.group(6)}';
        }
      }
      // Passport No.
      else if (upper.contains('NGA')) {
        if (i + 4 < lines.length) tempIdNumber = lines[i + 4].trim();
      }
    }

    if (tempSurname != null) lastName = tempSurname;
    if (tempFirstName != null) firstName = tempFirstName;
    if (tempMiddleName != null) middleName = tempMiddleName;
    if (tempIdNumber != null) idNumber = tempIdNumber;
    return IDCardInfo(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dob,
      idNumber: idNumber,
    );
  }

  static Future<IDCardInfo> extractunknown(List<String> lines) async {
    var idNumber;
    var firstName;
    var lastName;
    var middleName;
    var dob;
    var fullName;

    // GENERIC FALLBACK LOGIC (try to extract what we can)
    // Try to extract DOB
    final dobRegex = RegExp(
      r'(\d{2})[ /-]([A-Z]{3})[ /-](\d{2,4})|(\d{2})[ /-](\d{2})[ /-](\d{2,4})',
    );
    for (final line in lines) {
      final match = dobRegex.firstMatch(line.toUpperCase());
      if (match != null) {
        if (match.group(2) != null) {
          final day = match.group(1);
          final monStr = match.group(2);
          final year = match.group(3);
          final months = {
            'JAN': '01',
            'FEB': '02',
            'MAR': '03',
            'APR': '04',
            'MAY': '05',
            'JUN': '06',
            'JUL': '07',
            'AUG': '08',
            'SEP': '09',
            'OCT': '10',
            'NOV': '11',
            'DEC': '12',
          };
          final mon = months[monStr] ?? monStr;
          dob = '$day-$mon-$year';
        } else if (match.group(4) != null &&
            match.group(5) != null &&
            match.group(6) != null) {
          dob = '${match.group(4)}-${match.group(5)}-${match.group(6)}';
        }
        break;
      }
    }
    // Try to extract ID number (longest digit/letter sequence)
    String idText = lines.join(' ');
    final idMatch = RegExp(
      r'[A-Z0-9]{10,}',
    ).firstMatch(idText.replaceAll(' ', ''));
    if (idMatch != null) {
      idNumber = idMatch.group(0);
    }
    // Try to extract name (first all-uppercase 2-3 word line)
    for (final line in lines) {
      final upper = line.toUpperCase().trim();
      final parts = upper.split(RegExp(r'\s+'));
      if ((parts.length == 2 || parts.length == 3) &&
          RegExp(r'^[A-Z ]+$').hasMatch(upper)) {
        lastName = parts[0].trim();
        if (parts.length > 1) firstName = parts[1].trim();
        if (parts.length > 2) middleName = parts[2].trim();
        fullName = line.trim();
        break;
      }
    }
    return IDCardInfo(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dob,
      idNumber: idNumber,
    );
  }
}
