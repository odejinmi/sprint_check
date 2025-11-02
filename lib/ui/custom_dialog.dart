import 'dart:math' as math;

import 'package:flutter/material.dart';

/// This is a modification of [AlertDialog]. A lot of modifications was made. The goal is
/// to retain the dialog feel and look while adding the close IconButton
class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({
    super.key,
    this.title,
    this.titlePadding,
    this.onCancelPress,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 10.0),
    this.expanded = false,
    this.showlogo = false,
    required this.content,
  });

  final Widget? title;
  final EdgeInsetsGeometry? titlePadding;
  final Widget content;
  final EdgeInsetsGeometry contentPadding;
  final VoidCallback? onCancelPress;
  final bool expanded;
  final bool showlogo;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    if (title != null && titlePadding != null) {
      children.add(Padding(
        padding: titlePadding!,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.titleLarge!,
          child: Semantics(namesRoute: true, child: title),
        ),
      ));
    }

    children.add(Flexible(
      child: Padding(
        padding: contentPadding,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.titleMedium!,
          child: content,
        ),
      ),
    ));

    return buildContent(context, children);
  }

  Widget buildContent(BuildContext context, List<Widget> children) {
    Widget widget = Material(
      color: Colors.white,
      // color: Theme.of(context).scaffoldBackgroundColor,
      // ? Colors.white
      // : Colors.grey,
      child: Container(
          child: onCancelPress == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    // horizontal: 10.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Spacer(flex: 2,),
                        if(showlogo)
                        Image.asset(
                          "assets/logo.png",
                          height: 34,
                          package: "sprint_check",
                        ),
                        Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                          ),
                          onPressed: onCancelPress,
                          color: Colors.black54,
                          // padding: const EdgeInsets.all(15.0),
                          iconSize: 30.0,
                        ),
                      ],
                    ),
                    Expanded(
                        child: Column(
                      children: children,
                    )),
                  ],
                )),
    );

    return widget;
  }
}

/// This is a modification of [Dialog]. The only modification is increasing the
/// elevation and changing the Material type.
class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.child,
    required this.expanded,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
  });

  final Widget child;
  final Duration insetAnimationDuration;
  final Curve insetAnimationCurve;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets +
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      duration: insetAnimationDuration,
      curve: insetAnimationCurve,
      child: MediaQuery.removeViewInsets(
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        context: context,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: expanded
                    ? math.min(
                        (MediaQuery.of(context).size.width - 40.0), 332.0)
                    : 280.0),
            child: Material(
              elevation: 50.0,
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
