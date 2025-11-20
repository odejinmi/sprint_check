
import '../IDCardInfo.dart';

class Digitalninslip {
  static IDCardInfo extractDigitalNINslip(List<String> lines) {
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

    for (int i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();
      if (upper.contains('SURNAME/NOM')) {
        if (i + 1 < lines.length) lastName = lines[i + 1].trim();
      } else if (upper.contains('GIVEN NAMES/PRÉNOMS')) {
        if (i + 1 < lines.length) {
          final nameLine = lines[i+1].trim();
          final parts = nameLine.split(RegExp(r'[ ,]+'));
          firstName = parts.isNotEmpty ? parts[0] : null;
          if (parts.length > 1) middleName = parts.sublist(1).join(' ').trim();
        }
      } else if (upper.contains('DATE OF BIRTH')) {
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
      } else if (RegExp(r'^\d{4}\s+\d{3}\s+\d{4}$').hasMatch(upper)) {
        idNumber = upper.replaceAll(' ', '');
      }
    }
    return IDCardInfo(
        firstName: firstName, lastName: lastName, middleName: middleName, dateOfBirth: dob, idNumber: idNumber, extracteddetails: extractedDetails);
  }
}