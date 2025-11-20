import 'IDCardInfo.dart';
import 'nin/digitalNINslip.dart';

class ExtractNIN {
  static Future<IDCardInfo> extractNIN(List<String> lines) async {
    // First, determine the type of NIN card/slip based on unique keywords.
    final String fullText = lines.join(' ').toUpperCase();
    String cardType = 'unknown';

    if (fullText.contains('DIGITAL NIN SLIP')) {
      cardType = 'digitalninslip';
    } else if (fullText.contains('NATIONAL IDENTITY MANAGEMENT SYSTEM')) {
      cardType = 'ninslip'; // The old paper slip
    } else if (fullText.contains('NATIONAL IDENTITY CARD')) {
      cardType = 'nimc'; // The plastic card
    } else if (fullText.contains('SURNAME/NOM')){
        cardType = 'nimc'; // Fallback for plastic card
    }

    switch (cardType) {
      case 'digitalninslip':
        return Digitalninslip.extractDigitalNINslip(lines);
      case 'ninslip':
        return _extractPaperNINSlip(lines);
      case 'nimc':
        return _extractPlasticNIMCCard(lines);
      default:
        return extractunknown(lines); // Use the powerful fallback
    }
  }

  static IDCardInfo _extractPaperNINSlip(List<String> lines) {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;

    for (final line in lines) {
        final upper = line.toUpperCase();
        if(upper.startsWith("SURNAME:")) {
            lastName = upper.split(':').last.trim();
        } else if (upper.startsWith("FIRST NAME:")) {
            firstName = upper.split(':').last.trim();
        } else if (upper.startsWith("MIDDLE NAME:")) {
            middleName = upper.split(':').last.trim();
        } else if (upper.startsWith("NIN:")) {
            idNumber = upper.replaceAll(RegExp(r'[^0-9]'), '');
        }
    }

    return IDCardInfo(firstName: firstName, lastName: lastName, middleName: middleName, idNumber: idNumber);
  }

  static IDCardInfo _extractPlasticNIMCCard(List<String> lines) {
     // This function is now superseded by the more robust `extractunknown` logic
     // but is kept for structure. The default case will handle plastic cards.
    return extractunknown(lines);
  }

  // A powerful fallback extractor that can handle multiple NIN card layouts.
  static IDCardInfo extractunknown(List<String> lines) {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;
    String? dob;
    String? extractedDetails; // Preserved as requested

    for (final line in lines) {
      if (extractedDetails == null) {
        extractedDetails = line;
      } else {
        extractedDetails += " ***videx*** $line";
      }
    }

    // --- Robust, Multi-Strategy Extraction ---

    // 1. Find NIN (most reliable feature)
    for (final line in lines) {
        final cleanedLine = line.replaceAll(' ', '');
        if (RegExp(r'^\d{11}$').hasMatch(cleanedLine)) {
            idNumber = cleanedLine;
            break;
        }
        final match = RegExp(r'(\d{4}\d{3}\d{4})').firstMatch(line.replaceAll(' ', ''));
        if (match != null) {
            idNumber = match.group(1);
            break;
        }
    }

    // 2. Find Name and DOB by intelligent label search
    for (int i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();

      // --- Name ---
      if (upper.contains('SURNAME/NOM') || upper.contains('SURNAME')) {
        var value = upper.split(RegExp(r'SURNAME(?:/NOM)?\s*[:]?\s*')).last.trim();
        if (value.isNotEmpty) {
          lastName = value;
        } else if (i + 1 < lines.length) {
          lastName = lines[i + 1].trim();
        }
      }
      else if (upper.contains('GIVEN NAMES') || upper.contains('FIRST NAME')) {
        var value = upper.split(RegExp(r'(?:GIVEN|FIRST) NAMES(?:/PRÉNOMS)?\s*[:]?\s*')).last.trim();
        if (value.isEmpty && i + 1 < lines.length) {
          value = lines[i+1].trim();
        }
        
        if (value.isNotEmpty) {
            final parts = value.split(RegExp(r'[ ,]+'));
            firstName = parts.isNotEmpty ? parts[0].trim() : null;
            if (parts.length > 1) middleName = parts.sublist(1).join(' ').trim();
        }
      }

      // --- DOB ---
      else if (upper.contains('DATE OF BIRTH')) {
         var value = upper.split(RegExp(r'DATE OF BIRTH\s*[:]?\s*')).last.trim();
         if (value.isEmpty && i + 1 < lines.length) {
          value = lines[i+1].trim();
        }

        if (value.isNotEmpty) {
            final dobRegex = RegExp(r'(\d{1,2})[.\s]+([A-Z]{3})[.\s]+(\d{4})', caseSensitive: false);
            final match = dobRegex.firstMatch(value.toUpperCase());
            if (match != null) {
              String day = match.group(1)!.padLeft(2, '0');
              String monthStr = match.group(2)!;
              String year = match.group(3)!;
              final months = {
                  'JAN': '01', 'FEB': '02', 'MAR': '03', 'APR': '04', 'MAY': '05', 'JUN': '06',
                  'JUL': '07', 'AUG': '08', 'SEP': '09', 'OCT': '10', 'NOV': '11', 'DEC': '12',
              };
              String? month = months[monthStr];
              if (month != null) {
                  dob = '$day-$month-$year';
              }
            }
        }
      }
    }

    return IDCardInfo(
        firstName: firstName, lastName: lastName, middleName: middleName, dateOfBirth: dob, idNumber: idNumber, extracteddetails: extractedDetails);
  }
}
