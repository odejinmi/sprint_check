import 'package:sprint_check/models/IDCardInfo.dart';

class Extractunknown {
  static IDCardInfo extractunknown(List<String> lines) {
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

    // 1. Find NIN (most reliable feature)
    for (final line in lines) {
      final cleanedLine = line.replaceAll(' ', '');
      if (RegExp(r'^\d{11}$').hasMatch(cleanedLine)) {
        idNumber = cleanedLine;
        break;
      }
    }
    if (idNumber == null) {
      for (final line in lines) {
        final match = RegExp(r'(\d{4})\s*(\d{3})\s*(\d{4})').firstMatch(line);
        if (match != null) {
          idNumber = '${match.group(1)}${match.group(2)}${match.group(3)}';
          break;
        }
      }
    }

    // 2. Find the Anchor (Date of Birth) and extract names relative to it.
    int dobLineIndex = -1;

    final dobRegexDMY = RegExp(r'(\d{1,2})[.\s-]+([A-Z]{3})[.\s-]+(\d{4})', caseSensitive: false);
    final dobRegexYMD = RegExp(r'(\d{4})-(\d{2})-(\d{2})');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final matchDMY = dobRegexDMY.firstMatch(line);
      final matchYMD = dobRegexYMD.firstMatch(line);

      if (matchDMY != null) {
        dobLineIndex = i;
        String day = matchDMY.group(1)!.padLeft(2, '0');
        String monthStr = matchDMY.group(2)!.toUpperCase();
        String year = matchDMY.group(3)!;
        final months = {
          'JAN': '01', 'FEB': '02', 'MAR': '03', 'APR': '04', 'MAY': '05', 'JUN': '06',
          'JUL': '07', 'AUG': '08', 'SEP': '09', 'OCT': '10', 'NOV': '11', 'DEC': '12',
        };
        String? month = months[monthStr];
        if (month != null) {
          dob = '$day-$month-$year';
        }
        break;
      } else if (matchYMD != null) {
        dobLineIndex = i;
        String year = matchYMD.group(1)!;
        String month = matchYMD.group(2)!;
        String day = matchYMD.group(3)!;
        dob = '$day-$month-$year';
        break;
      }
    }

    // 3. Extract Names RELATIVE to the Anchor
    if (dobLineIndex > 1) {
      final givenNamesLine = lines[dobLineIndex - 1].trim();
      final surnameLine = lines[dobLineIndex - 2].trim();

      if (!surnameLine.toUpperCase().contains('NAME') && surnameLine.split(' ').length < 3) {
        lastName = surnameLine;
      }

      if (!givenNamesLine.toUpperCase().contains('NAME')) {
        final cleanedGivenNames = givenNamesLine.replaceAll('8', 'B').replaceAll('0', 'O');
        final parts = cleanedGivenNames.split(RegExp(r'[ ,]+'));
        firstName = parts.isNotEmpty ? parts[0] : null;
        if (parts.length > 1) {
          middleName = parts.sublist(1).join(' ');
        }
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