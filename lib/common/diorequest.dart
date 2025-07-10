import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as Get;

import 'verificationController.dart';

class diorequest {
  final dio = Dio();
  final baseurl = "https://api.sprintcheck.megasprintlimited.com.ng/api/sdk/";

  VerificationController controller = Get.Get.put(VerificationController());
  //final baseurl = "https://abs.paylony.com/api/v1/";

  String generateHmacSha512(String message) {
    var key = utf8.encode(controller.secretKey);
    var bytes = utf8.encode(message);

    var hmacSha512 = Hmac(sha512, key); // HMAC-SHA512
    var digest = hmacSha512.convert(bytes);

    return digest.toString();
  }

  Future<dynamic> get(String endpoint) async {
    try {
      var header = {
        'Content-Type': Headers.jsonContentType,
        'Authorization': controller.publicKey,
        "signature": "",
      };
      final options = Options(headers: header);
      String url = "";
      if (endpoint.contains("https://")) {
        url = endpoint;
      } else {
        url = '$baseurl$endpoint';
      }
      debugPrint(url);
      debugPrint("headers: $header");
      Response response = await dio.get(url, options: options);
      if (response.statusCode == 200) {
        debugPrint(jsonEncode(response.data));
        return response.data;
      } else if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Try and login again",
          "status": "false",
        };
      }
    } on DioException catch (e) {
      debugPrint("response error");
      debugPrint(e.toString());
      debugPrint(e.message);
      return {
        "success": false,
        "message": "Connection error try again later",
        "status": "false",
      };
      // return {"success": false,"message":e.message.toString(),"status":"false"};
    }
  }

  // $join = $terminalId.'|'.$terminalSerial.'|'.$posType.'|'.$request->reference;
  // $keyPair = hash("sha512",$join);

  Future<dynamic> post(String endpoint, Object data) async {
    String url = '$baseurl$endpoint';
    print(url);
    var header = {
      'Content-Type': Headers.jsonContentType,
      'Authorization': controller.publicKey,
      "signature": generateHmacSha512(jsonEncode(data)),
    };

    debugPrint(url);
    debugPrint(jsonEncode(data));
    debugPrint(generateHmacSha512(jsonEncode(data)));
    debugPrint("headers: \n $header");
    debugPrint("unencrypted payload \n ${data.toString()}");

    // final decrypted = encrypter.decrypt(encrypted, iv: iv);
    // debugPrint('Decrypted: $decrypted');
    try {
      Response response;
      final options = Options(headers: header);
      response = await dio.post(url, options: options, data: data);
      if (response.statusCode == 200) {
        debugPrint(jsonEncode(response.data));
        return response.data;
      } else if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Try and login again",
          "status": "false",
        };
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please log in again.",
          "status": "false",
        };
      }

      debugPrint("error");
      debugPrint(e.message);
      return {
        "success": false,
        "message": "Connection error try again later",
        "status": "false",
      };
      // return {"success": false,"message":e.message.toString(),"status":"false"};
    }
  }

  Future<dynamic> put(String endpoint, Object data) async {
    String url = '$baseurl$endpoint';
    print(url);
    var header = {
      'Content-Type': Headers.jsonContentType,
      'Authorization': controller.publicKey,
      "signature": generateHmacSha512(data.toString()),
    };

    debugPrint(url);
    debugPrint("headers: \n $header");
    debugPrint("unencrypted payload \n ${data.toString()}");

    // final decrypted = encrypter.decrypt(encrypted, iv: iv);
    // debugPrint('Decrypted: $decrypted');
    try {
      Response response;
      final options = Options(headers: header);
      response = await dio.put(url, options: options, data: data);
      if (response.statusCode == 200) {
        debugPrint(jsonEncode(response.data));
        return response.data;
      } else if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Try and login again",
          "status": "false",
        };
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {
          "success": false,
          "message": "Session expired. Please log in again.",
          "status": "false",
        };
      }

      debugPrint("error");
      debugPrint(e.message);
      return {
        "success": false,
        "message": "Connection error try again later",
        "status": "false",
      };
      // return {"success": false,"message":e.message.toString(),"status":"false"};
    }
  }
}
