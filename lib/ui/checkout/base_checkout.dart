import 'package:flutter/material.dart';

import '../../sprint_check_method_channel.dart';
import '../animated_widget.dart';

abstract class BaseCheckoutMethodState<T extends StatefulWidget>
    extends BaseAnimatedState<T> {
  final CheckoutMethod _method;

  BaseCheckoutMethodState(this._method);

  CheckoutMethod get method => _method;
}
