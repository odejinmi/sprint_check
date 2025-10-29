import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class IDCardInfo {
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? dateOfBirth;
  final String? idNumber;

  IDCardInfo({
    this.firstName,
    this.lastName,
    this.middleName,
    this.dateOfBirth,
    this.idNumber,
  });
}

class IDCardParser {
  static Future<IDCardInfo> extractInfoFromImage(InputImage image) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      image,
    );

    String? firstName, lastName, dob, idNumber, middleName;
    String? fullName;
    final lines = <String>[];

    // List of lines to skip if encountered as candidates
    List<String> skipWords = [
      "federal republic of nigeria",
      "national identity management system",
      "national identification number slip",
      "national identification number (nins)",
      "surname",
      "first name",
      "middle name",
      "gender",
      "address",
      "nin",
    ];

    bool isValidSurname(String candidate) {
      if (candidate.isEmpty) return false;
      String c = candidate.toLowerCase();
      if (skipWords.contains(c)) return false;
      // Nigerian surnames are often all uppercase and one word
      if (!RegExp(r'^[A-Z]+[0-9]*$').hasMatch(candidate)) return false;
      if (candidate.length < 2) return false;
      return true;
    }

    // Flatten all lines for easier next-line lookup
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        lines.add(line.text.trim());
      }
    }

    // // Debug: Print all OCR lines for troubleshooting
    // for (var l in lines) {
    //   dev.log('[OCR LINE] ' + l + "  ${lines.length}");
    // }

    // --- CARD TYPE DETECTION ---
    String cardType = 'unknown';
    if (lines.any(
      (l) =>
          l.toUpperCase().contains(
            'INDEPENDENT NATIONAL ELECTORAL COMMISSION',
          ) ||
          l.toUpperCase().contains('VOTER'),
    )) {
      cardType = 'voter';
    } else if (lines.any(
      (l) =>
          l.toUpperCase().contains('PASSPORT / PASSEPORT') ||
          l.toUpperCase().contains('PASSPORT NO') ||
          l.toUpperCase().contains('PASSPORT NO.') ||
          l.toUpperCase().contains('PASSPORT NUMBER'),
    )) {
      cardType = 'national';
    } else if (lines.any((l) => l.contains('DIGITAL NIN SLIP'))) {
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
          l.toUpperCase().contains('DRIVER') ||
          l.toUpperCase().contains('LICENCE') ||
          l.toUpperCase().contains('L/NO'),
    )) {
      cardType = 'driver';
    } else if (lines.any(
      (l) =>
          l.toUpperCase().contains('NATIONAL IDENTITY CARD') ||
          l.toUpperCase().contains('NIMC'),
    )) {
      cardType = 'nimc';
    }

    // dev.log('[CARD TYPE] $cardType');

    void extractVoter() {
      // VOTER'S CARD LOGIC
      // ID Number (VIN)
      for (final line in lines) {
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
    }

    void extractNIN() {
      // NIN SLIP LOGIC
      // ID Number
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
    }

    void extractDriverLicense() {
      // DRIVER'S LICENSE LOGIC
      // ID Number
      for (final line in lines) {
        final text = line.toUpperCase();
        if (text.contains('L/NO') || text.startsWith('LNO')) {
          final match = RegExp(r'[A-Z0-9]{6,}').firstMatch(line);
          if (match != null) {
            idNumber = match.group(0);
            break;
          }
        }
      }
      // Name (try comma line or labeled fields)
      for (final line in lines) {
        final upper = line.toUpperCase();
        if (RegExp(r'^[A-Z ,]+$').hasMatch(upper) && upper.contains(',')) {
          final parts = upper.split(',');
          if (parts.length > 1) {
            lastName = parts[0].trim();
            final firstNames = parts[1].trim().split(' ');
            if (firstNames.isNotEmpty) {
              firstName = firstNames[0].trim();
            }
            if (firstNames.length > 1) {
              middleName = firstNames[1].trim();
            }
          }
        } else if (upper.startsWith('SURNAME')) {
          lastName = line.split(' ').last.trim();
        } else if (upper.startsWith('FIRST NAME')) {
          firstName = line.split(' ').last.trim();
        } else if (upper.startsWith('MIDDLE NAME')) {
          middleName = line.split(' ').last.trim();
        }
      }
      // DOB
      for (int i = 0; i < lines.length; i++) {
        final upper = lines[i].toUpperCase();
        if (upper.contains('DOB') ||
            upper.contains('D OF B') ||
            upper.contains('D OF 8')) {
          // Search this line and the next two lines for a date
          for (int j = 0; j <= 2 && i + j < lines.length; j++) {
            final dateMatch = RegExp(
              r'(\d{2})[-/](\d{2})[-/](\d{2,4})',
            ).firstMatch(lines[i + j]);
            if (dateMatch != null) {
              dob = dateMatch.group(0);
              break;
            }
          }
          if (dob != null) break;
        }
        // Also, if a line itself is just a date, pick it up
        final directDateMatch = RegExp(
          r'^\d{2}[-/]\d{2}[-/]\d{2,4}$',
        ).firstMatch(lines[i].trim());
        if (directDateMatch != null) {
          dob = directDateMatch.group(0);
          break;
        }
      }
    }

    void extractnational() {
      String? tempSurname, tempFirstName, tempMiddleName, tempDob, tempIdNumber;

      for (int i = 0; i < lines.length; i++) {
        final upper = lines[i].toUpperCase().trim();

        // Surname
        if ((upper.contains('SURNAME') && !upper.contains('GIVEN')) ||
            upper.contains('SURNAME / NOM')) {
          if (i + 1 < lines.length) tempSurname = lines[i + 3].trim();
        }
        // Given Names
        else if (upper.contains('GIVEN NAMES') ||
            upper.contains('GIVEN NAMES / PRÉNOMS') ||
            upper.contains('PRÉNOMS') ||
            upper.contains('Glven Names/ Prénoms')) {
          if (i + 1 < lines.length) {
            var names = lines[i + 1].trim().split(RegExp(r'\s+'));
            if (names.isNotEmpty) tempFirstName = names[0];
            if (names.length > 1) tempMiddleName = names.sublist(1).join(' ');
          }
        }
        // Date of Birth
        else if (upper.contains('DATE OF BIRTH') ||
            upper.contains('DATE DE NAISSANCE') ||
            upper.contains('DATE OF BIRTH /DATE DE NAISSANCE')) {
          if (i + 1 < lines.length) tempDob = lines[i + 1].trim();
        }
        // Passport No.
        else if (upper.contains('PASSPART NO.') ||
            upper.contains('N PASSEPORT') ||
            upper.contains('PASSPART NO./N PASSEPORT')) {
          // dev.log('PASSPORT NO');
          // dev.log(lines[i]);
          // dev.log(lines[i + 1]);
          if (i + 1 < lines.length) tempIdNumber = lines[i + 1].trim();
        }
      }

      if (tempSurname != null) lastName = tempSurname;
      if (tempFirstName != null) firstName = tempFirstName;
      if (tempMiddleName != null) middleName = tempMiddleName;
      if (tempDob != null) {
        // Clean up and normalize DOB string for national ID/passport
        String dobRaw =
            tempDob
                .toUpperCase()
                .replaceAll('É', 'E')
                .replaceAll('/', ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();

        // Map for both English and French abbreviations
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
          'JANV': '01',
          'FEV': '02',
          'AVR': '04',
          'MAI': '05',
          'JUI': '06',
          'JUIL': '07',
          'AOUT': '08',
        };

        // Match e.g. 12 DEC 96 or 12 DEC 1996
        final dobRegex = RegExp(r'(\d{1,2})\s+([A-Z]{3,5})\s+(\d{2,4})');
        final match = dobRegex.firstMatch(dobRaw);
        if (match != null) {
          String day = match.group(1)!.padLeft(2, '0');
          String monthStr = match.group(2)!;
          String year = match.group(3)!;
          monthStr = months[monthStr] ?? monthStr;
          if (year.length == 4) year = year.substring(2);
          dob = '$day/$monthStr/$year';
        } else {
          dob = tempDob;
        }
      }
      if (tempIdNumber != null) idNumber = tempIdNumber;
    }

    void extractnimc() {
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
    }

    void extractNINslip() {
      String? tempSurname, tempFirstName, tempMiddleName, tempDob, tempIdNumber;

      // DOB
      final dobRegex = RegExp(
        r'(\d{2})[ /-]([A-Z]{3})[ /-](\d{2,4})|(\d{2})[ /-](\d{2})[ /-](\d{2,4})',
      );
      for (int i = 0; i < lines.length; i++) {
        final upper = lines[i].toUpperCase().trim();

        final match = dobRegex.firstMatch(upper);

        // Surname
        if ((upper.contains('SURNAME') && !upper.contains('GIVEN')) ||
            upper.contains('SURNAME / NOM')) {
          if (i + 1 < lines.length) tempSurname = lines[i + 3].trim();
        }
        // Given Names
        else if (upper.contains('GIVEN NAMES') ||
            upper.contains('GIVEN NAMES / PRÉNOMS') ||
            upper.contains('PRÉNOMS') ||
            upper.contains('Glven Names/ Prénoms')) {
          if (i + 1 < lines.length) {
            var names = lines[i + 1].trim().split(RegExp(r'\s+'));
            if (names.isNotEmpty) tempFirstName = names[0];
            if (names.length > 1) tempMiddleName = names.sublist(1).join(' ');
          }
        }
        // Date of Birth
        else if (match != null) {
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
        }
        // Passport No.
        else if (upper.contains('NGA')) {
          // dev.log('PASSPORT NO');
          // dev.log(lines[i]);
          // dev.log(lines[i + 1]);
          if (i + 1 < lines.length) tempIdNumber = lines[i + 1].trim();
        }
      }

      if (tempSurname != null) lastName = tempSurname;
      if (tempFirstName != null) firstName = tempFirstName;
      if (tempMiddleName != null) middleName = tempMiddleName;
      if (tempIdNumber != null) idNumber = tempIdNumber;
    }

    void extractDigitalNINslip() {
      String? tempSurname, tempFirstName, tempMiddleName, tempDob, tempIdNumber;

      // DOB
      final dobRegex = RegExp(
        r'(\d{2})[ /-]([A-Z]{3})[ /-](\d{2,4})|(\d{2})[ /-](\d{2})[ /-](\d{2,4})',
      );
      for (int i = 0; i < lines.length; i++) {
        final upper = lines[i].toUpperCase().trim();

        final match = dobRegex.firstMatch(upper);

        // Surname
        if ((upper.contains('SURNAME') && !upper.contains('GIVEN')) ||
            upper.contains('SURNAME / NOM')) {
          if (i + 1 < lines.length) tempSurname = lines[i + 1].trim();
        }
        // Given Names
        else if (upper.contains('GIVEN NAMES') ||
            upper.contains('GIVEN NAMES / PRÉNOMS') ||
            upper.contains('PRÉNOMS') ||
            upper.contains('Glven Names/ Prénoms')) {
          if (i + 1 < lines.length) {
            var names = lines[i + 1].trim().split(RegExp(r'\s+'));
            if (names.isNotEmpty) tempFirstName = names[0];
            if (names.length > 1) tempMiddleName = names.sublist(1).join(' ');
          }
        }
        // Date of Birth
        else if (match != null) {
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
        }
        // Passport No.
        else if (upper.contains('NGA')) {
          if (i + 4 < lines.length) tempIdNumber = lines[i + 4].trim();
        }
      }

      if (tempSurname != null) lastName = tempSurname;
      if (tempFirstName != null) firstName = tempFirstName;
      if (tempMiddleName != null) middleName = tempMiddleName;
      if (tempIdNumber != null) idNumber = tempIdNumber;
    }

    void extractunknown() {
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
          fullName = line.trim();
          break;
        }
      }
    }

    // --- CARD-SPECIFIC EXTRACTION ---
    switch (cardType) {
      case 'voter':
        extractVoter();
        break;
      case 'national':
        extractnational();
        break;
      case 'nin':
        extractNIN();
        break;
      case 'driver':
        extractDriverLicense();
        break;
      case 'nimc':
        extractnimc();
        break;
      case 'ninslip':
        extractNINslip();
        break;
      case 'digitalninslip':
        extractDigitalNINslip();
        break;
      default:
        extractunknown();
        break;
    }
    return IDCardInfo(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dob,
      idNumber: idNumber,
    );
  }
}
