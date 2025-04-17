import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sprint_check/models/checkout_response.dart';

import 'sprint_check_method_channel.dart';

abstract class SprintCheckPlatform extends PlatformInterface {
  /// Constructs a SprintCheckPlatform.
  SprintCheckPlatform() : super(token: _token);

  static final Object _token = Object();

  static SprintCheckPlatform _instance = MethodChannelSprintCheck();

  /// The default instance of [SprintCheckPlatform] to use.
  ///
  /// Defaults to [MethodChannelSprintCheck].
  static SprintCheckPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SprintCheckPlatform] when
  /// they register themselves.
  static set instance(SprintCheckPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  initialize({required String publicKey, required String secretKey}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<CheckoutResponse> checkout(
    BuildContext context,
    CheckoutMethod checkoutmethod,
  ) async {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
