import 'package:flutter/material.dart';
import 'package:sprint_check/models/checkout_response.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';

import 'sprint_check_platform_interface.dart';
export 'models/checkout_response.dart';
export 'sprint_check_method_channel.dart';

/// The main class for interacting with the SprintCheck SDK.
class SprintCheck {
  /// Returns the current platform version.
  Future<String?> getPlatformVersion() {
    return SprintCheckPlatform.instance.getPlatformVersion();
  }

  /// Initializes the SprintCheck SDK.
  ///
  /// This must be called before any other method.
  /// [api_key] is your public API key from the SprintCheck dashboard.
  /// [encryption_key] is your encryption key from the SprintCheck dashboard.
  void initialize({required String apiKey, required String encryptionKey}) {
    SprintCheckPlatform.instance.initialize(
      publicKey: apiKey,
      secretKey: encryptionKey,
    );
  }

  /// Starts the checkout process.
  ///
  /// [context] is the BuildContext of the widget calling this method.
  /// [checkoutmethod] is the verification method to use.
  /// [identifier] is a unique identifier for the user.
  /// [bvn] is the user's Bank Verification Number (optional).
  /// [nin] is the user's National Identification Number (optional).
  Future<CheckoutResponse> checkout(
    BuildContext context,
    CheckoutMethod checkoutmethod,
    String identifier, {
    String? bvn,
    String? nin,
  }) async {
    return SprintCheckPlatform.instance.checkout(
      context,
      checkoutmethod,
      identifier,
      bvn: bvn,
      nin: nin,
    );
  }
}
