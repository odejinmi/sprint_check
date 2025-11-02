import 'package:flutter/material.dart';
import 'package:sprint_check/pages/idcardpage.dart';

import '../models/charge.dart';
import '../models/checkout_response.dart';
import '../pages/idcardtype.dart';
import '../pages/selectcountry.dart';
import '../sprint_check_method_channel.dart';
import 'checkout/base_checkout.dart';

class Idcardverification extends StatefulWidget {
  final Charge charge;
  final CheckoutMethod checkoutmethod;
  final Function(CheckoutResponse) onResponse;
  const Idcardverification({super.key, required this.charge, required this.checkoutmethod, required this.onResponse});

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

    }) : Selectcountry(onResponse: (country) {

    });
  }
}
