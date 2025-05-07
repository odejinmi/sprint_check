import 'package:flutter/material.dart';
import 'package:sprint_check/models/checkout_response.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';

import 'sprint_check_platform_interface.dart';

class SprintCheck {
  Future<String?> getPlatformVersion() {
    return SprintCheckPlatform.instance.getPlatformVersion();
  }

  initialize({required String api_key, required String encryption_key}) {
    SprintCheckPlatform.instance.initialize(
      publicKey: api_key,
      secretKey: encryption_key,
    );
  }

  Future<CheckoutResponse> checkout(
    BuildContext context,
    CheckoutMethod checkoutmethod,
    String identifier,
  ) async {
    return SprintCheckPlatform.instance.checkout(
      context,
      checkoutmethod,
      identifier,
    );
  }
}
