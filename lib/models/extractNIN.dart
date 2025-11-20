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
        return extractunknown(lines); // Return empty if type is unknown
    }
  }

  // For old paper slips
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

  // For the newer plastic cards
  static IDCardInfo _extractPlasticNIMCCard(List<String> lines) {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;
    String? dob;

     for (int i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();
      if (upper.contains('SURNAME/NOM') || upper.contains('SURNAME')) {
         if (i + 1 < lines.length) lastName = lines[i + 1].trim();
      } else if (upper.contains('GIVEN NAMES/PRÉNOMS') || upper.contains('GIVEN NAMES')) {
         if (i + 1 < lines.length) {
            final nameLine = lines[i+1].trim();
            final parts = nameLine.split(RegExp(r'[ ,]+'));
            firstName = parts.isNotEmpty ? parts[0] : null;
            if (parts.length > 1) middleName = parts.sublist(1).join(' ').trim();
         }
      }
      else if (upper.contains('DATE OF BIRTH')) {
         if (i + 1 < lines.length) {
            final dobLine = lines[i+1];
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
                }
            }
         }
      }
      // For plastic cards, the NIN is often a large standalone number
      else if (RegExp(r'^\d{4}\s+\d{3}\s+\d{4}$').hasMatch(upper.trim())) {
          idNumber = upper.replaceAll(' ', '');
      } else if (RegExp(r'^\d{4}\s+\d{4}\s+\d{4}\s+\d{4}$').hasMatch(upper.trim())) { // Fallback for Federal ID Card
          idNumber = upper.replaceAll(' ', '');
      }
    }

    return IDCardInfo(
        firstName: firstName, lastName: lastName, middleName: middleName, dateOfBirth: dob, idNumber: idNumber);
  }

  static IDCardInfo extractunknown(List<String> lines) {
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
        // fullName = line.trim();
        break;
      }
    }
    return IDCardInfo(
        firstName: firstName, lastName: lastName, middleName: middleName, dateOfBirth: dob, idNumber: idNumber, extracteddetails: extractedDetails);
  }
}
