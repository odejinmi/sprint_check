import 'dart:developer' as dev;

import 'IDCardInfo.dart';

class ExtractNational {
  static Future<IDCardInfo> extractnational(List<String> lines) async {
    String? idNumber;
    String? firstName;
    String? lastName;
    String? middleName;
    String? dob;
    String? nin;
    String? extractedDetails;

    // --- Primary Extraction from Machine-Readable Zone (MRZ) ---
    String? mrzLine1, mrzLine2;
    for (final line in lines) {
      if(extractedDetails == null){
        extractedDetails = line;
      }else{
        extractedDetails += " ***videx*** $line";
      }
      final normalizedLine = line.replaceAll(' ', '');
      if (normalizedLine.startsWith('P<NGA')) {
        mrzLine1 = line; 
      } else if (RegExp(r'^[A-Z0-9<]{9,}[0-9]NGA').hasMatch(normalizedLine)) {
        mrzLine2 = normalizedLine;
      }
    }

    // 1. Full Name from MRZ (Highest Confidence)
    if (mrzLine1 != null) {
      try {
        String mrzNamePart = mrzLine1.substring(5); // Skip 'P<NGA'
        List<String> nameParts = mrzNamePart.split('<<');
        if (nameParts.length > 1) {
          lastName = nameParts[0].replaceAll('<', ' ').trim();
          String givenNames = nameParts[1].replaceAll('<', ' ').trim();
          List<String> givenNameParts = givenNames.split(RegExp(r'\s+'));
          if (givenNameParts.isNotEmpty) {
            firstName = givenNameParts[0];
          }
          if (givenNameParts.length > 1) {
            middleName = givenNameParts.sublist(1).join(' ');
          }
        }
      } catch (e) {
        dev.log("Error parsing MRZ name line: $e");
      }
    }

    // 2. ID Number from MRZ (Highest Confidence)
    if (mrzLine2 != null) {
      try {
        idNumber = mrzLine2.substring(0, 9).replaceAll('<', '');
      } catch (e) {
        dev.log("Error parsing MRZ ID line: $e");
      }
    }

    // --- Secondary/Fallback Extraction ---

    // Fallback for ID Number
    if (idNumber == null || idNumber.isEmpty) {
      for (final line in lines) {
        final match = RegExp(r'^[A-Z][0-9]{8}$').firstMatch(line.trim());
        if (match != null) {
          idNumber = match.group(0);
          break;
        }
      }
    }

    // Fallback for Name
    if (firstName == null || lastName == null) {
        for (final line in lines) {
            final upper = line.toUpperCase().trim();
            final parts = upper.split(RegExp(r'\s+'));
            if (parts.length >= 2 && parts.length <= 4 && parts.every((p) => RegExp(r'^[A-Z]+$').hasMatch(p)) && !upper.contains('FEDERAL') && !upper.contains('REPUBLIC')) {
                lastName = parts[0];
                firstName = parts[1];
                if (parts.length > 2) {
                    middleName = parts.sublist(2).join(' ');
                }
                break;
            }
        }
    }
    
    // Label-based extraction for DOB and NIN (can be run regardless)
     for (int i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase().trim();
      final dobRegex = RegExp(r'(\d{1,2})\s+([A-Z]{3})(?:\s*[/]?\s*[A-Z]{3})?\s+(\d{2,4})');
      final match = dobRegex.firstMatch(upper.toUpperCase());
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
          if (year.length == 2) {
            int yr = int.parse(year);
            year = (yr > (DateTime.now().year % 100)) ? '19$year' : '20$year';
          }
          dob = '$day-$month-$year';
        }
      }

      // NIN Extraction
      // if (upper.contains('NIN')) {
         final match1 = RegExp(r'(\d{11})').firstMatch(upper.replaceAll(' ', ''));
         if (match1 != null) {
           nin = match1.group(1)!;
         // } else if (i + 1 < lines.length) {
         //   final nextLineMatch = RegExp(r'(\d{11})').firstMatch(lines[i + 1].replaceAll(' ', ''));
         //   if (nextLineMatch != null) {
         //     nin = nextLineMatch.group(1)!;
         //   }
         }
         dev.log("nin: $nin");
      // }
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
