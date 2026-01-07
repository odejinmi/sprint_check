import 'IDCardInfo.dart';
import 'nin/digitalNINslip.dart';
import 'nin/extractunknown.dart';

class ExtractNIN {
  static Future<IDCardInfo> extractNIN(List<String> lines) async {
    final String fullText = lines.join(' ').toUpperCase();
    String cardType = 'unknown';

    if (fullText.contains('DIGITAL NIN SLIP')) {
      cardType = 'digitalninslip';
    } else if (fullText.contains('NATIONAL IDENTITY MANAGEMENT SYSTEM')) {
      cardType = 'ninslip';
    } else if (fullText.contains('NATIONAL IDENTITY CARD')) {
      cardType = 'nimc';
    } else if (fullText.contains('SURNAME/NOM') || fullText.contains('GIVEN NAMES')) {
      cardType = 'nimc';
    }

    switch (cardType) {
      case 'digitalninslip':
        return Digitalninslip.extractDigitalNINslip(lines);
      case 'ninslip':
        return _extractPaperNINSlip(lines);
      case 'nimc':
        return _extractPlasticNIMCCard(lines);
      default:
        return Extractunknown.extractunknown(lines);
    }
  }

  static IDCardInfo _extractPaperNINSlip(List<String> lines) {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;
    String? dob;
    String? extractedDetails;

    for (final line in lines) {
      if (extractedDetails == null) {
        extractedDetails = line;
      } else {
        extractedDetails += " ***videx*** " + line;
      }
    }

    // --- Deductive Extraction for Paper Slips ---
    Map<String, String> labeledNames = {};
    List<String> potentialNameParts = [];
    final nameRegex = RegExp(r'^[A-Z-]{2,15}$');

    // Pass 1: Find labeled names and potential "floating" name parts
    for (final line in lines) {
      final upper = line.toUpperCase().trim();

      if (upper.contains("FIRST NAME:")) {
        var value = upper.split(':').last.trim();
        if (value.isNotEmpty) labeledNames['first'] = value;
      } else if (upper.contains("MIDDLE NAME:")) {
        var value = upper.split(':').last.trim();
        if (value.isNotEmpty) labeledNames['middle'] = value;
      } else if (upper.contains("SURNAME:")) {
        var value = upper.split(':').last.trim();
        if (value.isNotEmpty && nameRegex.hasMatch(value)) {
          labeledNames['last'] = value;
        }
      } 
      else if (nameRegex.hasMatch(upper) &&
               !upper.contains("FEDERAL") &&
               !upper.contains("REPUBLIC") &&
               !upper.contains("NIGERIA") &&
               !upper.contains("NATIONAL") &&
               !upper.contains("GENDER") &&
               !upper.contains("ADDRESS")) {
        potentialNameParts.add(upper);
      }
    }

    firstName = labeledNames['first'];
    middleName = labeledNames['middle'];
    lastName = labeledNames['last'];

    // Pass 2: Deduce missing parts from floating candidates
    if (lastName == null && potentialNameParts.isNotEmpty) {
      var candidate = potentialNameParts.firstWhere((part) => part != firstName && part != middleName, orElse: () => '');
      if (candidate.isNotEmpty) {
        lastName = candidate;
        potentialNameParts.remove(candidate);
      }
    }
    if (firstName == null && potentialNameParts.isNotEmpty) {
      var candidate = potentialNameParts.firstWhere((part) => part != lastName && part != middleName, orElse: () => '');
      if (candidate.isNotEmpty) {
        firstName = candidate;
        potentialNameParts.remove(candidate);
      }
    }
    if (middleName == null && potentialNameParts.isNotEmpty) {
      var candidate = potentialNameParts.firstWhere((part) => part != lastName && part != firstName, orElse: () => '');
      if (candidate.isNotEmpty) {
        middleName = candidate;
        potentialNameParts.remove(candidate);
      }
    }

    // 3. Robust NIN Extraction
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toUpperCase().contains('NIN')) {
        var potentialId = lines[i].replaceAll(RegExp(r'[^0-9]'), '');
        if (potentialId.length >= 11) {
          idNumber = potentialId.substring(0, 11);
          break;
        }
        if (i + 1 < lines.length) {
          potentialId = lines[i + 1].replaceAll(RegExp(r'[^0-9]'), '');
          if (potentialId.length >= 11) {
            idNumber = potentialId.substring(0, 11);
            break;
          }
        }
      }
    }
    if (idNumber == null) {
      for (final line in lines) {
        final cleaned = line.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleaned.length == 11) {
          idNumber = cleaned;
          break;
        }
      }
    }

    return IDCardInfo(
        firstName: firstName, lastName: lastName, middleName: middleName, idNumber: idNumber, dateOfBirth: dob, extracteddetails: extractedDetails);
  }

  static IDCardInfo _extractPlasticNIMCCard(List<String> lines) {
    return Extractunknown.extractunknown(lines);
  }
}
