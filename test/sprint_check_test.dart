import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sprint_check/models/checkout_response.dart';
import 'package:sprint_check/sprint_check.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';
import 'package:sprint_check/sprint_check_platform_interface.dart';

class MockSprintCheckPlatform
    with MockPlatformInterfaceMixin
    implements SprintCheckPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<CheckoutResponse> checkout(
    BuildContext context,
    CheckoutMethod checkoutmethod,
    String identifier,
  ) {
    // TODO: implement checkout
    throw UnimplementedError();
  }

  @override
  initialize({required String publicKey, required String secretKey}) {
    // TODO: implement initialize
    throw UnimplementedError();
  }
}

void main() {
  final SprintCheckPlatform initialPlatform = SprintCheckPlatform.instance;

  test('$MethodChannelSprintCheck is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSprintCheck>());
  });

  test('getPlatformVersion', () async {
    SprintCheck sprintCheckPlugin = SprintCheck();
    MockSprintCheckPlatform fakePlatform = MockSprintCheckPlatform();
    SprintCheckPlatform.instance = fakePlatform;

    expect(await sprintCheckPlugin.getPlatformVersion(), '42');
  });
}
