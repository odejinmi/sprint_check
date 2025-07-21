import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprint_check/sprint_check.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Mypage());
  }
}

class Mypage extends StatefulWidget {
  const Mypage({Key? key}) : super(key: key);

  @override
  State<Mypage> createState() => _MypageState();
}

class _MypageState extends State<Mypage> {
  String _platformVersion = 'Unknown';
  final _sprintCheckPlugin = SprintCheck();

  TextEditingController bvnController = TextEditingController(
    text: "odejinmiabraham@gmail.com",
  );
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
        api_key: "scb1edcd88-64f7485186d9781ca624a903",
        encryption_key: "enc67fe4978b16fc1744718200",
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
                    bvnController.text,
                  );
                  showresult("response for the sdk: ${response}");
                  print("response for the sdk: ${response}");
                },
                child: Text("Start BVN verification"),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  var response = await _sprintCheckPlugin.checkout(
                    context,
                    CheckoutMethod.nin,
                    "odejinmiabraham@gmail.com",
                  );
                  showresult("response for the sdk: ${response}");
                  print("response for the sdk: ${response}");
                },
                child: Text("Start NIN verification"),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  var response = await _sprintCheckPlugin.checkout(
                    context,
                    CheckoutMethod.facial,
                    "odejinmiabraham@gmail.com",
                  );
                  showresult("response for the sdk: ${response}");
                  print("response for the sdk: ${response}");
                },
                child: Text("Start Face verification"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  showresult(message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            // color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Sdk result"),
                SizedBox(height: 20),
                Text(message),
              ],
            ),
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
