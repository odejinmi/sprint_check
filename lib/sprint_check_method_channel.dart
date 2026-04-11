import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sprint_check/common/verificationController.dart';
import 'package:sprint_check/pages/checkout_widget.dart';

import 'common/exceptions.dart';
import 'common/utils.dart';
import 'models/checkout_response.dart';
import 'sprint_check_platform_interface.dart';

/// An implementation of [SprintCheckPlatform] that uses method channels.
class MethodChannelSprintCheck extends SprintCheckPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sprint_check');

  VerificationController controller = Get.put(VerificationController());
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  /// Initialize the SPRINTCHECK object. It should be called as early as possible
  /// (preferably in initState() of the Widget.
  ///
  /// [publicKey] - your SPRINTCHECK public key. This is mandatory
  ///
  /// use [checkout] and you want this plugin to initialize the transaction for you.
  /// Please check [checkout] for more information
  ///
  @override
  Future<Map<String, dynamic>> initialize({required String publicKey, required String secretKey}) async {
    assert(() {
      if (publicKey.isEmpty) {
        throw SprintCheckException('publicKey cannot be null or empty');
      } else if (secretKey.isEmpty) {
        throw SprintCheckException('secretKey cannot be null or empty');
      } else {
        return true;
      }
    }());

    if (controller.sdkInitialized) return {"status": false, "message":"SDK already initialized"};

    try {
      controller.publicKey = publicKey;
      controller.secretKey = secretKey;
      controller.sdkInitialized = true;
      return {"status": true, "message":"SDK initialized successfully"};
    } on PlatformException catch (e) {
      return {"status": false, "message":e.message ?? "Failed to initialize SDK"};
    } catch (e) {
      return {"status":false, "message":e.toString()};
    }
  }

  _validateSdkInitialized() {
    if (!controller.sdkInitialized) {
      throw SprintCheckSdkNotInitializedException(
        'SprintCheck SDK has not been initialized. The SDK has'
        ' to be initialized before use',
      );
    }
  }

  void _performChecks() {
    //validate that sdk has been initialized
    _validateSdkInitialized();
    //check for null value, and length and starts with pk_
    if (controller.publicKey.isEmpty) {
      throw AuthenticationException(Utils.getKeyErrorMsg('public'));
    } else if (controller.secretKey.isEmpty) {
      throw AuthenticationException(Utils.getKeyErrorMsg('secret'));
    }
  }

  @override
  Future<CheckoutResponse> checkout(
    BuildContext context,
    CheckoutMethod checkoutmethod,
    String identifier, {
    String? bvn,
    String? nin,
  }) async {
    _performChecks();
    controller.checkoutmethod = checkoutmethod;
    controller.identifier = identifier;
    controller.bvnNumber = bvn;
    controller.ninNumber = nin;
    if (bvn != null && bvn.isNotEmpty) {
      controller.directcheckout = true;
      controller.bvnController.text = bvn;
      controller.stage = 1;
    }
    if (nin != null && nin.isNotEmpty) {
      controller.directcheckout = true;
      controller.bvnController.text = nin;
      controller.stage = 1;
    }
    CheckoutResponse? response = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => CheckoutWidget(),
    );
    controller.directcheckout = false;
    return response!;
  }
}

enum CheckoutMethod { bvn, nin, facial, idcard, selectable }

typedef OnResponse<CheckoutResponse> = void Function(CheckoutResponse response);
