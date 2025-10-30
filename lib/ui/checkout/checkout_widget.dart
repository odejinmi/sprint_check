import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:sprint_check/pages/initializepage.dart';
import 'package:sprint_check/ui/base_widget.dart';

import '../../models/charge.dart';
import '../custom_dialog.dart';


class CheckoutWidget extends StatefulWidget {

  final Charge charge;
  final String publicKey;
  final String secretKey;
  const CheckoutWidget({Key? key, required this.charge, required this.publicKey, required this.secretKey}) : super(key: key);

  @override
  _CheckoutWidgetState createState() => _CheckoutWidgetState(charge);
}

class _CheckoutWidgetState extends BaseState<CheckoutWidget>
    with TickerProviderStateMixin {
  // @override
  // Widget build(BuildContext context) {
  //   return Container();
  // }
  final Charge _charge;
  bool _iscard = false;
  bool _isbank = false;
  late AnimationController _animationController;
  _CheckoutWidgetState(this._charge);

  @override
  void initState() {
    super.initState();
    if (_charge.currency != "NGN") {
      _iscard = true;
    }
    // _init();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // _charge.card ??= PaymentCard.empty();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget buildChild(BuildContext context) {
    // TODO: implement buildChild
    return CustomAlertDialog(
      expanded: true,
      titlePadding: const EdgeInsets.all(0.0),
      onCancelPress: onCancelPress,
      content: SingleChildScrollView(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Container(
              padding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              child: Column(
                children: <Widget>[
                  Initializepage()
                ],
              )),
        ),
      ),
    );
  }
}
