 import 'IDCardInfo.dart';

class ExtractDriverLicense {

   static Future<IDCardInfo> extractDriverLicense(List<String> lines) async {
     String? idNumber;
     String? firstName;
     String? lastName;
     String? middleName;
     String? dob;
     String? extracteddetails;

     // 1. ID Number Extraction
     for (final line in lines) {
       final upperLine = line.toUpperCase().trim();
       final match = RegExp(r'(?:L/NO|LNO\.?)\s*([A-Z]{3}\d+[A-Z]+\d*)').firstMatch(upperLine);
       if (match != null) {
         idNumber = match.group(1)?.replaceAll(RegExp(r'\s'), '');
         break;
       }
     }
     if (idNumber == null) {
       for (final line in lines) {
         final text = line.toUpperCase();
         if (text.contains('L/NO') || text.startsWith('LNO')) {
           final match = RegExp(r'([A-Z0-9]{10,})').firstMatch(line.replaceAll(' ',''));
           if (match != null) {
             idNumber = match.group(0);
             break;
           }
         }
       }
     }

     // 2. Name Extraction (Independent Step)
     for (final line in lines) {
       if(extracteddetails == null){
         extracteddetails = line;
       }else{
         extracteddetails += " ***videx*** $line";
       }
       final upper = line.toUpperCase();
       // Look for "LASTNAME, FIRSTNAME MIDDLE..."
       if (RegExp(r'^[A-Z, ]+$').hasMatch(upper) && upper.contains(',')) {
         final parts = upper.split(',');
         if (parts.length > 1) {
           lastName = parts[0].trim();
           final nameParts = parts[1].trim().split(RegExp(r'\s+'));
           if (nameParts.isNotEmpty) {
             firstName = nameParts[0];
             if (nameParts.length > 1) {
               middleName = nameParts.sublist(1).join(' ');
             }
           }
           // Once name is found, we can break
           if(lastName.isNotEmpty && firstName != null && firstName.isNotEmpty) break;
         }
       }
     }

     // 3. DOB Extraction (Independent Step)
     final dobLabelRegex = RegExp(r'(D\s*OF\s*[B8]|DOB|DOR|DOTB|O\s*OF|OOF|D\s*O\s*B|Dor|Dof|Oor|or\s*8|D\s*of\s*8)', caseSensitive: false);
     final dateRegex = RegExp(r'(\d{2})[\s\-/]+(\d{2})[\s\-/]+(\d{4})');

     for (int i = 0; i < lines.length; i++) {
       String searchArea = lines[i];

       if (i + 1 < lines.length) {
         searchArea += " ${lines[i+1]}";
       }

       if (dobLabelRegex.hasMatch(searchArea)) {
         final dateMatch = dateRegex.firstMatch(searchArea);
         if (dateMatch != null) {
           dob = '${dateMatch.group(1)}-${dateMatch.group(2)}-${dateMatch.group(3)}';
           break;
         }
       }
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