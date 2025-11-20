import 'IDCardInfo.dart';

class ExtractNIN {
  static Future<IDCardInfo> extractNIN(List<String> lines) async {
    String cardType = 'unknown';
    if (lines.any((l) => l.contains('DIGITAL NIN SLIP'))) {
      cardType = 'digitalninslip';
    } else if (lines.any((l) => l.contains('National ldentification Number'))) {
      cardType = 'ninslip';
    } else if (lines.any(
          (l) =>
      l.toUpperCase().contains('NATIONAL IDENTITY MANAGEMENT') ||
          l.toUpperCase().contains('NIN'),
    )) {
      cardType = 'nin';
    } else if (lines.any(
          (l) =>
      l.toUpperCase().contains('NATIONAL IDENTITY CARD') ||
          l.toUpperCase().contains('NIMC'),
    )) {
      cardType = 'nimc';
    }

    // --- Multi-Layered Extraction Strategy ---

    // --- CARD-SPECIFIC EXTRACTION ---
    switch (cardType) {
    // case 'nin':
    //   extractNIN();
    //   break;
    // case 'nimc':
    //   extractnimc();
    //   break;
    // case 'ninslip':
    //   extractNINslip();
    //   break;
      case 'digitalninslip':
        return await extractDigitalNINslip(lines);
        break;
      default:
        return IDCardInfo();
      // extractunknown();
        break;
    }
  }

  static Future<IDCardInfo> extractDigitalNINslip(List<String> lines) async {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;
    String? dob;
    String? extractedDetails;

    // VOTER'S CARD LOGIC
    for (final line in lines) {
      if (extractedDetails == null){
        extractedDetails = line;
      }else{
        extractedDetails += " ***videx*** $line";
      }
    }

    // --- Multi-Layered Extraction Strategy ---

    // 1. NIN (National Identification Number)
    // Primary Target: Look for a prominent 11-digit number, possibly with spaces.
    for (final line in lines) {
      final cleanedLine = line.replaceAll(' ', '');
      if (RegExp(r'^\d{11}$').hasMatch(cleanedLine)) {
        idNumber = cleanedLine;
        break;
      }
    }
    // Secondary Target: Look for the "NIN" label.
    if (idNumber == null) {
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].toUpperCase().contains('NIN')) {
          // Check same line first
          var potentialId = lines[i].replaceAll(RegExp(r'[^0-9]'), '');
          if (potentialId.length == 11) {
            idNumber = potentialId;
            break;
          }
          // Check next line if not found
          if (i + 1 < lines.length) {
            potentialId = lines[i + 1].replaceAll(RegExp(r'[^0-9]'), '');
            if (potentialId.length == 11) {
              idNumber = potentialId;
              break;
            }
          }
        }
      }
    }

    // 2. Name
    // Primary Target: Look for explicit labels.
    for (int i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();
      if (upper.contains('SURNAME')) {
        String nameLine = "";
        if (i + 1 < lines.length && !lines[i+1].toUpperCase().contains('NAME')) {
          nameLine = lines[i+1];
        } else {
          try {
            nameLine = upper.split(RegExp(r'SURNAME[:/\s]*', caseSensitive: false)).last.trim();
          } catch (e) {}
        }
        if (nameLine.isNotEmpty) lastName = nameLine;
      }
      if (upper.contains('GIVEN NAMES') || upper.contains('FIRST NAME')) {
        String nameLine = "";
        if (i + 1 < lines.length && !lines[i+1].toUpperCase().contains('NAME')) {
          nameLine = lines[i+1];
        } else {
          try {
            nameLine = upper.split(RegExp(r'(GIVEN|FIRST) NAMES?[:/\s]*', caseSensitive: false)).last.trim();
          } catch (e) {}
        }
        if(nameLine.isNotEmpty) {
          final parts = nameLine.split(RegExp(r'[ ,]+'));
          firstName = parts.isNotEmpty ? parts[0] : null;
          middleName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
        }
      }
      if (upper.contains('MIDDLE NAME')) {
        String nameLine = "";
        if (i + 1 < lines.length && !lines[i+1].toUpperCase().contains('NAME')){
          nameLine = lines[i+1];
        } else {
          try {
            nameLine = upper.split(RegExp(r'MIDDLE NAME[:/\s]*', caseSensitive: false)).last.trim();
          } catch (e) {}
        }
        if (nameLine.isNotEmpty) middleName = nameLine;
      }
    }

    // 3. Date of Birth
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toUpperCase().contains('DATE OF BIRTH')) {
        String dobLine = "";
        if(i + 1 < lines.length) {
          dobLine = lines[i+1];
        } else {
          try {
            dobLine = lines[i].split(RegExp(r'BIRTH[:/\s]*', caseSensitive: false)).last.trim();
          } catch(e){}
        }

        final dobRegex = RegExp(r'(\d{1,2})\s+([A-Z]{3})\s+(\d{4})', caseSensitive: false);
        final match = dobRegex.firstMatch(dobLine.toUpperCase());
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
            break;
          }
        }
      }
    }

    return IDCardInfo(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dob,
      idNumber: idNumber,
      extracteddetails: extractedDetails,
    );
  }
}