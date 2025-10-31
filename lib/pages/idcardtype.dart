import 'package:flutter/material.dart';

class Idcardtype extends StatefulWidget {
  final Function(Map<String, dynamic>) onResponse;

  const Idcardtype({Key? key, required this.onResponse}) : super(key: key);

  @override
  State<Idcardtype> createState() => _IdcardtypeState();
}

class _IdcardtypeState extends State<Idcardtype> {

  // List of ID card types
  final List<Map<String, String>> idCardTypes = [
    {'name': "Internation Passport",},
    {'name': "Voter's Card"},
    {'name': "Driver's License"},
    {'name': 'National identity card'},
    {'name': 'Plate Number Verification'},
  ];

   Map<String, dynamic> idCardType = {};
  @override
  Widget build(BuildContext context) {

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID Verification',
              style: TextStyle(
                color: const Color(0xFF181619),
                fontSize: 18,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w600,
                height: 1.78,
              ),
            ),
            if (idCardType.isEmpty)
            Text(
              'Please choose a verification method to begin.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.41,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: idCardTypes.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      idCardType = idCardTypes[index];
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: double.infinity,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: idCardType == idCardTypes[index] ? const Color(0xFF181619) : const Color(0xFFE1E1E1),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        idCardTypes[index]['name']!,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w500,
                          height: 1.60,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            InkWell(
              onTap: () {
                if (idCardType.isEmpty) return;
                widget.onResponse(idCardType);
              },
              child: Opacity(
                opacity: idCardType.isEmpty ? 0.05 : 1,
                child: Container(
                  width: double.infinity,
                  height: 47,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF181619),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Powered by SprintCheck',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        );
  }
}
