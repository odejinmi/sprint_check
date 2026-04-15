import 'package:flutter/material.dart';
import 'package:sprint_check/pages/scorepage.dart';

import '../models/charge.dart';
import '../models/checkout_response.dart';
import '../pages/newfacepage.dart';
import '../pages/newinputpage.dart';
import '../sprint_check_method_channel.dart';
import 'checkout/base_checkout.dart';

class Bvnverification extends StatefulWidget {
  final String publicKey;
  final String secretKey;
  final Charge charge;
  final CheckoutMethod checkoutmethod;
  final Function(CheckoutResponse) onResponse;
  const Bvnverification({super.key, required this.charge, required this.checkoutmethod, required this.onResponse, required this.publicKey, required this.secretKey});

  @override
  _BvnverificationState createState() => _BvnverificationState(charge, onResponse);
}

class _BvnverificationState extends BaseCheckoutMethodState<Bvnverification> {
  _BvnverificationState(this._charge, OnResponse<CheckoutResponse> onResponse)
      : super(onResponse, CheckoutMethod.bvn);

  final Charge _charge;

  String bvnimage = "";
  String reference = "";
  double score = 0;
  String enrollmentdata = "";
  String message = "";
  String? capturedImage;

  int stage = 0;

  @override
  Widget buildAnimatedChild() {
    // TODO: implement buildAnimatedChild
    return stage == 0?
        Newinputpage(charge: _charge, checkoutmethod: widget.checkoutmethod, publicKey: widget.publicKey, secretKey: widget.secretKey, onResponse: (response)
        {
          _charge.bvn = response["number"];
          bvnimage = response["bvnimage"];
          reference = response["reference"];
          stage = response["procced"];
          message = response["message"];
          setState(() {

          });
        }) : stage == 1?
        Newfacepage(charge: _charge, checkoutmethod: widget.checkoutmethod, bvnimage: bvnimage, reference: reference, publicKey: widget.publicKey, secretKey: widget.secretKey, onResponse: (response)
        {
          score = response["score"];
          enrollmentdata = response["enrollmentdata"];
          capturedImage = response["base64Image"];
          stage = 2;
          setState(() {

          });
        }):
        Scorepage(score: score, checkoutmethod: widget.checkoutmethod, message: message,onResponse: (res)
        {
            var response = CheckoutResponse(
              message: message,
              reference: reference,
              status: res["close"],
              method: widget.checkoutmethod,
              verify: score > 50,
              name: enrollmentdata,
              confidenceLevel: score,
              bvn: widget.charge.bvn,
              nin: widget.charge.nin,
              base64Image: capturedImage,
            );
            onResponse(response);
        })
    ;
  }

}
