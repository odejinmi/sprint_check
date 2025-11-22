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
    } else if (fullText.contains('SURNAME/NOM') || fullText.contains('GIVEN NAMES')){
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
    return extractunknown(lines);
  }

  // A powerful fallback extractor that uses fuzzy matching and a "next line" strategy.
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
        extractedDetails += " ***videx*** $line";
      }
    }

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

    // 2. Find Name and DOB by fuzzy label search ("Find Label, Get Next Line")
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final upper = line.toUpperCase();

      // Regex for fuzzy matching of labels based on logs
      final surnameRegex = RegExp(r'SURNA|SIAH|BERAE|SURNAME|^[A-Z]+$', caseSensitive: false);
      final givenNamesRegex = RegExp(r'G[I|V|U]VEN|NAES|NAMES|^[A-Z]+$', caseSensitive: false);
      final dobRegexLabel = RegExp(r'DATE\s*OF\s*BIR|DATE\s*AT\s*FIS|^\d{1,2}[\s-]*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*[\s-]*\d{4}', caseSensitive: false);
      final nameAfterAMOS = RegExp(r'AMOS\s*\*\*\*videx\*\*\*\s*([A-Z][A-Z0-9\s,]+?)(?:\*\*\*videx\*\*\*|$)', caseSensitive: false);

      // Try to extract name after AMOS pattern
      if (upper.contains('AMOS') && firstName == null) {
        final match = nameAfterAMOS.firstMatch(line);
        if (match != null) {
          String namePart = match.group(1)?.trim() ?? '';
          // Clean up the name part (remove any remaining videx or special characters)
          namePart = namePart.replaceAll('***videx***', ' ').replaceAll(RegExp(r'[^A-Z0-9\s,]', caseSensitive: false), ' ').trim();
          // Split by comma or space and clean up
          var nameParts = namePart.split(RegExp(r'[,\s]+'));
          if (nameParts.isNotEmpty) {
            // The first part is usually the last name or first name
            // Check if we already have a last name
            if (lastName == null && nameParts.length > 1) {
              lastName = nameParts[0].trim();
              firstName = nameParts[1].trim();
              if (nameParts.length > 2) {
                middleName = nameParts.sublist(2).where((p) => p.isNotEmpty).join(' ').trim();
              }
            } else if (firstName == null) {
              firstName = nameParts[0].trim();
            }
          }
        }
      }

      // --- Name ---
      if (lastName == null && surnameRegex.hasMatch(upper) && i + 1 < lines.length) {
        lastName = lines[i + 1].trim();
      }
      else if (firstName == null && givenNamesRegex.hasMatch(upper) && i + 1 < lines.length) {
        final value = lines[i + 1].trim();
        final parts = value.split(RegExp(r'[ ,]+'));
        firstName = parts.isNotEmpty ? parts[0].trim() : null;
        if (parts.length > 1) middleName = parts.sublist(1).join(' ').trim();
      }

      if (dobRegexLabel.hasMatch(upper)) {
        var value = upper.split(dobRegexLabel).last.trim();
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
      // --- DOB ---
      if (dob == null) {
        // Try to find date in current line
        final dobMatch = RegExp(r'(\d{1,2})[\s-]*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*[\s-]*(\d{4})', caseSensitive: false).firstMatch(upper);
        if (dobMatch != null) {
          String day = dobMatch.group(1)!.padLeft(2, '0');
          String monthStr = dobMatch.group(2)!.toUpperCase().substring(0, 3);
          String year = dobMatch.group(3)!;

          final months = {
            'JAN': '01', 'FEB': '02', 'MAR': '03', 'APR': '04', 'MAY': '05', 'JUN': '06',
            'JUL': '07', 'AUG': '08', 'SEP': '09', 'OCT': '10', 'NOV': '11', 'DEC': '12',
          };

          String? month = months[monthStr];
          if (month != null) {
            dob = '$day-$month-$year';
          }
        }
        // If not found in current line, check next line if this looks like a DOB label
        else if (dobRegexLabel.hasMatch(upper) && i + 1 < lines.length) {
          final value = lines[i + 1].trim();
          final nextLineMatch = RegExp(r'(\d{1,2})[\s-]*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*[\s-]*(\d{4})', caseSensitive: false).firstMatch(value.toUpperCase());
          if (nextLineMatch != null) {
            String day = nextLineMatch.group(1)!.padLeft(2, '0');
            String monthStr = nextLineMatch.group(2)!.toUpperCase().substring(0, 3);
            String year = nextLineMatch.group(3)!;

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
