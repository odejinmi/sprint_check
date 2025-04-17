import 'package:flutter_test/flutter_test.dart';
import 'package:sprint_check/sprint_check.dart';
import 'package:sprint_check/sprint_check_platform_interface.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSprintCheckPlatform
    with MockPlatformInterfaceMixin
    implements SprintCheckPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
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
