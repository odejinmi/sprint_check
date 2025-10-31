import 'package:flutter/material.dart';
import 'package:sprint_check/pages/scorepage.dart';

import '../models/charge.dart';
import '../models/checkout_response.dart';
import '../pages/newfacepage.dart';
import '../pages/newinputpage.dart';
import '../sprint_check_method_channel.dart';
import 'checkout/base_checkout.dart';

class Bvnverification extends StatefulWidget {
  final Charge charge;
  final CheckoutMethod checkoutmethod;
  final Function(CheckoutResponse) onResponse;
  const Bvnverification({Key? key, required this.charge, required this.checkoutmethod, required this.onResponse}) : super(key: key);

  @override
  _BvnverificationState createState() => _BvnverificationState(charge, onResponse);
}

class _BvnverificationState extends BaseCheckoutMethodState<Bvnverification> {
  _BvnverificationState(this._charge, OnResponse<CheckoutResponse> onResponse)
      : super(onResponse, CheckoutMethod.bvn);

  Charge _charge;

  String bvnimage = "";
  String reference = "";
  double score = 0;
  String enrollmentdata = "";
  String message = "";

  int stage = 0;

  @override
  Widget buildAnimatedChild() {
    // TODO: implement buildAnimatedChild
    return stage == 0?
        Newinputpage(charge: _charge, checkoutmethod: widget.checkoutmethod, onResponse: (response)
        {
          _charge.bvn = response["number"];
          bvnimage = response["bvnimage"];
          reference = response["reference"];
          stage = response["procced"];
          message = response["message"];
          setState(() {

          });
        }) : stage == 1?
        Newfacepage(charge: _charge, checkoutmethod: widget.checkoutmethod, bvnimage: bvnimage, reference: reference, onResponse: (response)
        {
          score = response["score"];
          enrollmentdata = response["enrollmentdata"];
          stage = 2;
          setState(() {

          });
        }):
        Scorepage(score: score, checkoutmethod: widget.checkoutmethod,onResponse: (res)
        {
            var response = CheckoutResponse(
              message: message,
              reference: reference,
              status: res["close"],
              method: widget.checkoutmethod,
              verify: score > 50,
              name: enrollmentdata,
              confidence_level: score,
              bvn: widget.charge.bvn,
              nin: widget.charge.nin,
            );
            onResponse(response);
        })
    ;
  }

}
