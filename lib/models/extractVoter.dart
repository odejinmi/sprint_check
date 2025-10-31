
import 'IDCardInfo.dart';

class ExtractVoter {
  static Future<IDCardInfo> extractVoter(List<String> lines) async {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;
    String? dob;
    String? fullName;
    String? extractedDetails;

    // VOTER'S CARD LOGIC
    // ID Number (VIN)
    for (final line in lines) {
      if (extractedDetails == null){
        extractedDetails = line;
      }else{
        extractedDetails += " ***videx*** $line";
      }
      final upper = line.toUpperCase();
      if (upper.contains('VIN')) {
        final vinMatch = RegExp(r'VIN\s*([A-Z0-9 ]+)').firstMatch(upper);
        if (vinMatch != null) {
          final vinNumber = vinMatch
              .group(1)!
              .replaceAll(RegExp(r'[^A-Z0-9]'), '');
          if (vinNumber.length >= 16) {
            idNumber = vinNumber;
            break;
          }
        }
      }
    }
    // Name
    const nonNameKeywords = ['DELIM', 'STATE', 'LGA', 'OSUN', 'IREWOLE'];
    for (final line in lines) {
      final upper = line.toUpperCase().trim();
      final parts = upper.split(RegExp(r'\s+'));
      if (parts.length == 3 &&
          RegExp(r'^[A-Z ]+$').hasMatch(upper) &&
          !nonNameKeywords.any((kw) => upper.contains(kw)) &&
          !upper.contains('OCCUPATION')) {
        lastName = parts[0].trim();
        firstName = parts[1].trim();
        middleName = parts[2].trim();
        fullName = line.trim();
        break;
      }
    }
    // DOB
    for (final line in lines) {
      if (line.toUpperCase().contains('DATE OF BIRTH')) {
        // Try to find date on this line or next line
        String dobLine = line;
        int idx = lines.indexOf(line);
        if (!RegExp(r'\d').hasMatch(dobLine) && idx + 1 < lines.length) {
          dobLine = lines[idx + 1];
        }
        // Match dd MMM yyyy, dd-mm-yyyy, dd/mm/yyyy, dd-mm-yy, etc.
        final dobRegex = RegExp(
          r'(\d{2})[ /-]([A-Z]{3}|\d{2})[ /-](\d{2,4})',
          caseSensitive: false,
        );
        final match = dobRegex.firstMatch(dobLine.toUpperCase());
        if (match != null) {
          String day = match.group(1)!;
          String month = match.group(2)!;
          String year = match.group(3)!;
          // Convert month name to number if needed
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
          if (months.containsKey(month)) {
            month = months[month]!;
          }
          dob = '$day-$month-$year';
          break;
        }
      } else if (RegExp(r'\d{2}[-/]\d{2}[-/]\d{4}').hasMatch(line.trim())) {
        // If the line itself is a date
        dob = RegExp(
          r'\d{2}[-/]\d{2}[-/]\d{4}',
        ).firstMatch(line.trim())!.group(0);
        break;
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