import 'package:flutter/material.dart';



class Idcarddetails extends StatelessWidget {
  const Idcarddetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("ID Card Details"),
        SizedBox(height: 20),
        TextFormField(
          autofillHints: [AutofillHints.telephoneNumber],
          decoration: InputDecoration(
            labelText: "Card Name",
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Color(0xFF6A6C6A)),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Color(0xFF6A6C6A)),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [],
          // controller: controller.idnameController,
          onChanged: (value) {},
          validator: (value) {
            if (value!.isEmpty) {
              return "Kindly input your Card Name";
            }

            return null;
          },
        ),
        SizedBox(height: 20),
        TextFormField(
          autofillHints: [AutofillHints.telephoneNumber],
          decoration: InputDecoration(
            labelText: "Card Number",
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Color(0xFF6A6C6A)),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Color(0xFF6A6C6A)),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [],
          // controller: controller.idnumberController,
          onChanged: (value) {},
          validator: (value) {
            if (value!.isEmpty) {
              return "Kindly input your Id Card Number";
            }

            return null;
          },
        ),
        SizedBox(height: 20),
        TextFormField(
          autofillHints: [AutofillHints.telephoneNumber],
          decoration: InputDecoration(
            labelText: "Date of Birth",
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Color(0xFF6A6C6A)),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              borderSide: BorderSide(color: Color(0xFF6A6C6A)),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [],
          // controller: controller.dobController,
          onChanged: (value) {},
          validator: (value) {
            if (value!.isEmpty) {
              return "Kindly input your Date of Birth";
            }

            return null;
          },
        ),
        Divider(),
        SizedBox(height: 10),
        InkWell(
          onTap: () {
            // controller.stage = 1;
          },
          child: Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              // color:
              //     controller.checked
              //         ? const Color(0xFF137F0C)
              //         : Color(0xFF6A6C6A) /* Green-700 */,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              'Continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFEAFFE6) /* Green-50 */,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}
