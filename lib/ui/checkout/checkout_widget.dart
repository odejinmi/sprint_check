import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:sprint_check/pages/initializepage.dart';
import 'package:sprint_check/ui/base_widget.dart';

import '../../models/charge.dart';
import '../../models/checkout_response.dart';
import '../../sprint_check_method_channel.dart';
import '../bvnverification.dart';
import '../custom_dialog.dart';
import '../idcardverification.dart';


class CheckoutWidget extends StatefulWidget {

  final Charge charge;
  final String publicKey;
  final String secretKey;
  final CheckoutMethod method;
  const CheckoutWidget({super.key, required this.charge, required this.publicKey, required this.secretKey, required this.method});

  @override
  State<CheckoutWidget> createState() => _CheckoutWidgetState();
}

class _CheckoutWidgetState extends BaseState<CheckoutWidget>
    with TickerProviderStateMixin {
  
  bool showlogo = false;

  late AnimationController _animationController;

  CheckoutResponse? _response;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget buildChild(BuildContext context) {
    return CustomAlertDialog(
      expanded: true,
      showlogo: showlogo,
      titlePadding: const EdgeInsets.all(0.0),
      onCancelPress: onCancelPress,
      content: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Container(
            child:
            _response?.method == CheckoutMethod.bvn || _response?.method == CheckoutMethod.nin || _response?.method == CheckoutMethod.facial ?
            Bvnverification(onResponse: _onPaymentResponse, charge: widget.charge, checkoutmethod: widget.method, publicKey: widget.publicKey, secretKey: widget.secretKey,):
                _response?.method == CheckoutMethod.idcard ?
            Idcardverification(onResponse: _onPaymentResponse, charge: widget.charge, checkoutmethod: widget.method, publicKey: widget.publicKey, secretKey: widget.secretKey,):
            Initializepage(onResponse: _onPaymentResponse, charge: widget.charge, checkoutmethod: widget.method,)),
      ),
    );
  }


  void _onPaymentResponse(CheckoutResponse response) {
    _response = response;
    if (!mounted) return;
      showlogo = true;
    if(response.status){
      Navigator.of(context).pop(response);
    }else if(!response.status && response.confidenceLevel != null){
      response.method = CheckoutMethod.selectable;
      showlogo = false;
    }
    setState(() {

    });
  }

  @override
  CheckoutResponse? getPopReturnValue() {
    return CheckoutResponse.defaults();
  }

}
