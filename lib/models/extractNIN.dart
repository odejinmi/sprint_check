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
        firstName: firstName, lastName: lastName, middleName: middleName, idNumber: idNumber, dateOfBirth: dob, extracteddetails: extractedDetails);
  }

  static IDCardInfo _extractPlasticNIMCCard(List<String> lines) {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;
    String? dob;
    String? extractedDetails;
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
        extracteddetails: extractedDetails);
  }


}
