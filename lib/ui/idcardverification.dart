import 'package:flutter/material.dart';
import 'package:sprint_check/pages/idcardpage.dart';

import '../models/charge.dart';
import '../models/checkout_response.dart';
import '../pages/idcardtype.dart';
import '../pages/newfacepage.dart';
import '../pages/scorepage.dart';
import '../pages/selectcountry.dart';
import '../sprint_check_method_channel.dart';
import 'checkout/base_checkout.dart';

class Idcardverification extends StatefulWidget {
  final Charge charge;
  final CheckoutMethod checkoutmethod;
  final Function(CheckoutResponse) onResponse;
  final String publicKey;
  final String secretKey;
  const Idcardverification({super.key, required this.charge, required this.checkoutmethod, required this.onResponse, required this.publicKey, required this.secretKey});

  @override
  _IdcardverificationState createState() => _IdcardverificationState(charge, onResponse);
}

class _IdcardverificationState extends BaseCheckoutMethodState<Idcardverification> {
  _IdcardverificationState(this._charge, OnResponse<CheckoutResponse> onResponse)
      : super(onResponse, CheckoutMethod.bvn);
  final Charge _charge;

  int stage = 0;
  Map<String, dynamic> country = {};
  Map<String, dynamic> idcard = {};

  String bvnimage = "";
  String reference = "";
  double score = 0;
  String enrollmentdata = "";
  String message = "";

  @override
  Widget buildAnimatedChild() {
    return stage == 0 ? Selectcountry(onResponse: (response) {
      country = response;
      stage = 1;
      setState(() {

      });
    }) : stage == 1 ? Idcardtype(onResponse: (response) {
        idcard = response;
        stage = 2;
        setState(() {

        });
    }) : stage == 2 ? Idcardpage(idcard: idcard, onResponse: (response) {
      bvnimage = response["bvnimage"];
      enrollmentdata = response["name"];
      message = response["message"];
      reference = DateTime.now().microsecondsSinceEpoch.toString();
      stage = 3;
      setState(() {

      });

    }) : stage == 3?
    Newfacepage(charge: _charge, checkoutmethod: widget.checkoutmethod, bvnimage: bvnimage, reference: reference, publicKey: widget.publicKey, secretKey: widget.secretKey, onResponse: (response)
    {
      score = response["score"];
      stage = 4;
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
        confidenceLevel: score,
        bvn: widget.charge.bvn,
        nin: widget.charge.nin,
      );
      onResponse(response);
    });
  }
}
