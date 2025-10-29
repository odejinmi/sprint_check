import 'dart:convert';

import 'package:cryptography/cryptography.dart';
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
    return MaterialApp(home: Mypage1());
    // return MaterialApp(home: LivenessCheckScreen(cameras: cameras));
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
        api_key: "scb*************************************",
        encryption_key: "enc*************************",
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
                    identifierController.text,
                    nin: bvnController.text,
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
                    identifierController.text,
                  );
                  showresult("response for the sdk: ${response}");
                  print("response for the sdk: ${response}");
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
                  showresult("response for the sdk: ${response}");
                  print("response for the sdk: ${response}");
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

  showresult(message) {
    showDialog(
      context: context,
      // barrierDismissible: false,
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

  // AES-GCM with 256-bit key
  final algorithm = AesGcm.with256bits();
  Future<void> startEncryption() async {
    // AES-256 requires a 32-byte key
    final keyBytes = utf8.encode('BaVkxaDFoNzI2U0FHa2o1OTJ2aytEeVY');
    final secretKey = SecretKey(keyBytes);

    // Generate a 12-byte random IV (nonce)
    final nonce = algorithm.newNonce(); // 12-byte random nonce

    var body = {"email": "odejinmiabraham@gmail.com", "password": "adeyemi"};
    var jsonbody1 = jsonEncode(body);

    // Calculate string length (number of characters)
    final length = jsonbody1.length;

    // Build PHP-style serialized string
    final phpSerialized = 's:$length:"$jsonbody1";';

    print(phpSerialized);
    var unrfy1 = utf8.encode(phpSerialized);

    // Encrypt
    final secretBox = await algorithm.encrypt(
      unrfy1,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Build JSON structure similar to Laravel
    final jsonResult = {
      "iv": base64Encode(secretBox.nonce), // 12-byte IV
      "value": base64Encode(secretBox.cipherText), // ciphertext
      "mac": "", // Laravel leaves empty for GCM
      "tag": base64Encode(secretBox.mac.bytes), // 16-byte tag
    };
    var jsonbody = jsonEncode(jsonResult);
    print(jsonbody);
    var unrfy = utf8.encode(jsonbody);
    print(base64Encode(unrfy));

    // --- Decrypt to verify ---
    // final decrypted = await algorithm.decrypt(secretBox, secretKey: secretKey);
    // print('Decrypted: ${utf8.decode(decrypted)}');
  }

  decryptData() async {
    // AES-256 requires a 32-byte key
    final keyBytes = utf8.encode('BaVkxaDFoNzI2U0FHa2o1OTJ2aytEeVY');
    final secretKey = SecretKey(keyBytes);

    var data =
        "eyJpdiI6InVwZzNCUUxVMTJJd2l2emUiLCJ2YWx1ZSI6ImRGbXlUTTNyWXgwbVBuL1IwTFZUOTFkV2ZSUkRLWnNlVFJOaDNYdVBTdk9kYzY5L1hWWFp0d1djS09pTFJ3cXpwa01PeU5LOVhSQkZmTVFROG1vSnplTT0iLCJtYWMiOiIiLCJ0YWciOiI0WisvUlBySWRIMUU2R011S3ZnWWNRPT0ifQ==";
    var unrfy = base64Decode(data);
    print(unrfy);
    var body = utf8.decode(unrfy);
    print(body);
    var bodyJson = jsonDecode(body);
    print(bodyJson);
    final decrypted = await algorithm.decrypt(
      SecretBox(
        base64Decode(bodyJson["value"]),
        nonce: base64Decode(bodyJson["iv"]),
        mac: Mac(base64Decode(bodyJson["tag"])),
      ),
      secretKey: secretKey,
    );
    print(utf8.decode(decrypted));
    // print('Decrypted: ${utf8.decode(decrypted)}');
  }
}
