import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprint_check/ui/checkout/checkout_widget.dart';

import 'common/exceptions.dart';
import 'common/utils.dart';
import 'models/charge.dart';
import 'models/checkout_response.dart';
import 'sprint_check_platform_interface.dart';

/// An implementation of [SprintCheckPlatform] that uses method channels.
class MethodChannelSprintCheck extends SprintCheckPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sprint_check');


  bool _sdkInitialized = false;
  String _publicKey = "";
  String _secretKey = "";

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
  initialize({required String publicKey, required String secretKey}) async {
    assert(() {
      if (publicKey.isEmpty) {
        throw SprintCheckException('publicKey cannot be null or empty');
        // } else if (!publicKey.startsWith("pk_")) {
        //   throw SprintCheckException(Utils.getKeyErrorMsg('public'));
      } else if (secretKey.isEmpty) {
        throw SprintCheckException('secretKey cannot be null or empty');
        // } else if (!secretKey.startsWith("sk_")) {
        //   throw SprintCheckException(Utils.getKeyErrorMsg('secret'));
      } else {
        return true;
      }
    }());

    if (_sdkInitialized) return;

    // Using cascade notation to build the platform specific info
    try {
      // platformInfo = (await PlatformInfo.getinfo())!;
      _publicKey = publicKey;
      _secretKey = secretKey;
      _sdkInitialized = true;
    } on PlatformException {
      rethrow;
    }
  }

  void _validateSdkInitialized() {
    if (!_sdkInitialized) {
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
    if (_publicKey
        .isEmpty //||
    // !controller.publicKey.startsWith("pk_")
    ) {
      throw AuthenticationException(Utils.getKeyErrorMsg('public'));
    } else if (_secretKey
        .isEmpty //||
    //  !controller.secretKey.startsWith("sk_")
    ) {
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
    // assert(() {
    //   _validateChargeAndKey(charge);
    //   return true;
    // }());
    _performChecks();
    Charge charge = Charge(identifier);
    charge.bvn = bvn;
    charge.nin = nin;
    dev.log("identifier: $identifier, bvn: $bvn, nin: $nin");
    CheckoutResponse? response = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => CheckoutWidget(charge: charge, publicKey: _publicKey , secretKey: _secretKey, method: checkoutmethod,),
    );
    return response!;
  }
}

enum CheckoutMethod { bvn, nin, facial, idcard, selectable }

typedef OnResponse<CheckoutResponse> = void Function(CheckoutResponse response);
