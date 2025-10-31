import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:sprint_check/pages/initializepage.dart';
import 'package:sprint_check/pages/newinputpage.dart';
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
  const CheckoutWidget({Key? key, required this.charge, required this.publicKey, required this.secretKey, required this.method}) : super(key: key);

  @override
  _CheckoutWidgetState createState() => _CheckoutWidgetState(charge,method);
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
  bool showlogo = false;

  CheckoutMethod method = CheckoutMethod.selectable;
  late AnimationController _animationController;

  CheckoutResponse? _response;
  _CheckoutWidgetState(this._charge, this.method);

  @override
  void initState() {
    super.initState();

    // if (_charge.currency != "NGN") {
    //   _iscard = true;
    // }
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
      showlogo: showlogo,
      titlePadding: const EdgeInsets.all(0.0),
      onCancelPress: onCancelPress,
      content: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Container(
            child:
            _response?.method == CheckoutMethod.bvn || _response?.method == CheckoutMethod.nin || _response?.method == CheckoutMethod.facial ?
            Bvnverification(onResponse: _onPaymentResponse, charge: _charge, checkoutmethod: method,):
                _response?.method == CheckoutMethod.idcard ?
            Idcardverification(onResponse: _onPaymentResponse, charge: _charge, checkoutmethod: method,):
            Initializepage(onResponse: _onPaymentResponse, charge: _charge, checkoutmethod: method,)),
      ),
    );
  }


  void _onPaymentResponse(CheckoutResponse response) {
    print("response: $response");
    _response = response;
    if (!mounted) return;
      showlogo = true;
      if (response.method == CheckoutMethod.nin) {
        _isbank = true;
      } else {
        _iscard = true;
      }
    if(response.status){
      Navigator.of(context).pop(response);
    }else if(!response.status && response.confidence_level != null){
      response.method = CheckoutMethod.selectable;
      showlogo = false;
    }
    setState(() {

    });
  }

  @override
  getPopReturnValue() {
    return _getResponse();
  }

  CheckoutResponse _getResponse() {
    CheckoutResponse? response = _response;
    if (response == null) {
      response = CheckoutResponse.defaults();
      response.method = method;
    }
    // if (response.card != null) {
    //   response.card!.nullifyNumber();
    // }
    return response;
  }
}
