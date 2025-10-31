import 'dart:developer' as dev;

import 'IDCardInfo.dart';

class ExtractNational {
  static Future<IDCardInfo> extractnational(List<String> lines) async {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;
    String? dob;
    String? nin; // Added for NIN
    String? extractedDetails;

    Map<String, String> extractedData = {};

    for (int i = 0; i < lines.length; i++) {
      if(extractedDetails == null){
        extractedDetails = lines[i];
      }else{
        extractedDetails += " ***videx*** " + lines[i];
      }
      final upper = lines[i].toUpperCase().trim();

      // Passport No. (Corrected Typo and Logic)
      if (upper.contains('PASSPORT NO')) {
        String searchArea = lines[i];
        if (i + 1 < lines.length) {
          searchArea += " " + lines[i + 1];
        }
        final match = RegExp(r'([A-Z]\d{8,})').firstMatch(searchArea.replaceAll(' ', ''));
        if (match != null) {
          extractedData['idNumber'] = match.group(1)!;
        }
      }
      // Surname
      else if (upper.contains('SURNAME / NOM')) {
        if (i + 1 < lines.length) {
          extractedData['lastName'] = lines[i + 1].trim();
        }
      }
      // Given Names
      else if (upper.contains('GIVEN NAMES / PRÉNOMS')) {
        if (i + 1 < lines.length) {
          var names = lines[i + 1].trim().split(RegExp(r'\s+'));
          if (names.isNotEmpty) extractedData['firstName'] = names[0];
          if (names.length > 1) {
            extractedData['middleName'] = names.sublist(1).join(' ');
          }
        }
      }
      // Date of Birth
      else if (upper.contains('DATE OF BIRTH / DATE DE NAISSANCE')) {
        if (i + 1 < lines.length) {
          extractedData['dobRaw'] = lines[i + 1].trim();
        }
      }
      // NIN (New addition)
      else if (upper.contains('NIN')) {
        final match = RegExp(r'(\d{11})').firstMatch(upper.replaceAll(' ', ''));
        if (match != null) {
          extractedData['nin'] = match.group(1)!;
        } else if (i + 1 < lines.length) {
          final nextLineMatch = RegExp(r'(\d{11})').firstMatch(lines[i + 1].replaceAll(' ', ''));
          if (nextLineMatch != null) {
            extractedData['nin'] = nextLineMatch.group(1)!;
          }
        }
      }
    }

    lastName = extractedData['lastName'];
    firstName = extractedData['firstName'];
    middleName = extractedData['middleName'];
    idNumber = extractedData['idNumber'];
    nin = extractedData['nin'];

    if (extractedData.containsKey('dobRaw')) {
      String dobRaw = extractedData['dobRaw']!
          .toUpperCase()
          .replaceAll('É', 'E')
          .replaceAll('/', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final months = {
        'JAN': '01', 'FEB': '02', 'MAR': '03', 'APR': '04', 'MAY': '05', 'JUN': '06',
        'JUL': '07', 'AUG': '08', 'SEP': '09', 'OCT': '10', 'NOV': '11', 'DEC': '12',
      };

      final dobRegex = RegExp(r'(\d{1,2})\s+([A-Z]{3})\s+(\d{2,4})');
      final match = dobRegex.firstMatch(dobRaw);

      if (match != null) {
        String day = match.group(1)!.padLeft(2, '0');
        String monthStr = match.group(2)!;
        String year = match.group(3)!;
        String? month = months[monthStr];

        if (month != null) {
          if (year.length == 2) {
            int yr = int.parse(year);
            year = (yr > (DateTime.now().year % 100)) ? '19' + year : '20' + year;
          }
          dob = '$day-$month-$year';
        }
      } else {
        dob = extractedData['dobRaw'];
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