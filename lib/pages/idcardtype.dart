import 'package:flutter/material.dart';

class Idcardtype extends StatelessWidget {
  const Idcardtype({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List of ID card types
    final List<Map<String, String>> idCardTypes = [
      {'name': "Voter's Card", 'image': 'assets/images/voters_card.png'},
      {'name': 'National Passport', 'image': 'assets/images/passport.png'},
      {'name': 'NIN Slip', 'image': 'assets/images/nin_slip.png'},
      {'name': 'Digital NIN Slip', 'image': 'assets/images/digital_nin_slip.png'},
      {'name': 'NIMC', 'image': 'assets/images/nimc.png'},
      {'name': "Driver's License", 'image': 'assets/images/drivers_license.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select ID Card Type'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select the type of ID you want to verify',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: idCardTypes.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Image.asset(
                        idCardTypes[index]['image']!,
                        width: 50,
                        height: 50,
                        // Add error builder to handle missing assets
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.credit_card, size: 40);
                        },
                      ),
                      title: Text(idCardTypes[index]['name']!),
                      onTap: () {
                        // Handle the selection of the ID card type
                        print('Selected: ${idCardTypes[index]['name']}');
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle the continue action
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
