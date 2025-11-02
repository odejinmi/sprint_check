import 'package:flutter/material.dart';

/// A stub implementation of [BaseState] for web compatibility.
abstract class BaseState<T extends StatefulWidget> extends State<T> {
  /// This method is not implemented for web.
  void onCancelPress() => throw UnimplementedError();

  /// This method is not implemented for web.
  Never getPopReturnValue() => throw UnimplementedError();

  @override
  Widget build(BuildContext context) {
    return buildChild(context);
  }

  Widget buildChild(BuildContext context);
}
