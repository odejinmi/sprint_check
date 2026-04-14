import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprint_check/sprint_check.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';

import 'mypage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // final cameras = await availableCameras();
  // runApp(MyApp(cameras: cameras));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // final List<CameraDescription> cameras;
  // const MyApp({super.key, required this.cameras});
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        home: Mypage1());
    // return MaterialApp(home: LivenessCheckScreen(cameras: cameras));
  }
}

class Mypage extends StatefulWidget {
  const Mypage({super.key});

  @override
  State<Mypage> createState() => _MypageState();
}

class _MypageState extends State<Mypage> {
  String _platformVersion = 'Unknown';
  final _sprintCheckPlugin = SprintCheck();

  TextEditingController identifierController = TextEditingController(
    text: "odejinmiabraham@gmail.com",
  );
  TextEditingController bvnController = TextEditingController();
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _sprintCheckPlugin.getPlatformVersion() ??
          'Unknown platform version';
      _sprintCheckPlugin.initialize(
        apiKey: "scb*************************************",
        encryptionKey: "enc*************************",
      );
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              SizedBox(height: 20),
              TextFormField(
                autofillHints: [AutofillHints.telephoneNumber],
                decoration: InputDecoration(
                  hintText: "asfdgsd@gmail.com",
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
                controller: identifierController,
                onChanged: (value) {},
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Kindly input your identifier";
                  }

                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                autofillHints: [AutofillHints.telephoneNumber],
                decoration: InputDecoration(
                  hintText: "22123456768",
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
                controller: bvnController,
                onChanged: (value) {},
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Kindly input your identifier";
                  }

                  return null;
                },
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  var response = await _sprintCheckPlugin.checkout(
                    context,
                    CheckoutMethod.bvn,
                    identifierController.text,
                    bvn: bvnController.text,
                  );
                  showresult("response for the sdk: $response");
                  dev.log("response for the sdk: $response");
                },
                child: Text("Start BVN verification"),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  var response = await _sprintCheckPlugin.checkout(
                    context,
                    CheckoutMethod.nin,
                    identifierController.text,
                    nin: bvnController.text,
                  );
                  showresult("response for the sdk: $response");
                  dev.log("response for the sdk: $response");
                },
                child: Text("Start NIN verification"),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  var response = await _sprintCheckPlugin.checkout(
                    context,
                    CheckoutMethod.facial,
                    identifierController.text,
                  );
                  showresult("response for the sdk: $response");
                  dev.log("response for the sdk: $response");
                },
                child: Text("Start Face verification"),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  var response = await _sprintCheckPlugin.checkout(
                    context,
                    CheckoutMethod.idcard,
                    identifierController.text,
                  );
                  showresult("response for the sdk: $response");
                  dev.log("response for the sdk: $response");
                  // startEncryption();
                  // // decryptData();
                },
                child: Text("Start Id card verification"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showresult(String message) {
    showDialog(
      context: context,
      // barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sdk result"),
              SizedBox(height: 20),
              Text(message),
            ],
          ),
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        );
      },
    );
  }

}
