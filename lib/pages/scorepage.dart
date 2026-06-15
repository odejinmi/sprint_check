import 'dart:async';

import 'package:flutter/material.dart';
import '../ui/score_gauge.dart';

import '../sprint_check_method_channel.dart';

class Scorepage extends StatefulWidget {
  final double score;
  final CheckoutMethod checkoutmethod;
  final String message;
  final Function (Map<String, dynamic>) onResponse;
  const Scorepage({super.key, required this.score, required this.checkoutmethod, required this.onResponse, required this.message});

  @override
  _ScorepageState createState() => _ScorepageState();
}

class _ScorepageState extends State<Scorepage> {

  int start = 8;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (start <= 0) {
        _timer!.cancel();
        widget.onResponse(
            { "close": true}
        );
      } else {
        start--;
      }
      setState(() {

      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Verification Score',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF181619),
              fontSize: 18,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              height: 1.78,
            ),
          ),
          ScoreGauge(score: widget.score),
          Text(
            '${widget.score.toInt()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF181619),
              fontSize: 20,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              height: 1.60,
            ),
          ),
          SizedBox(height: 20),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Your Score is ',
                  style: TextStyle(
                    color: const Color(0xFF7D7D7D),
                    fontSize: 18,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    height: 1.78,
                  ),
                ),
                TextSpan(
                  text: widget.score > 50 ? 'Good' : 'BAD',
                  style: TextStyle(
                    color: widget.score > 50 ? const Color(0xFF00B341) :  const Color(0xFFFF5257),
                    fontSize: 18,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    height: 1.78,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Verification ${widget.score > 50?"Successful":"Failed"}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              height: 1.78,
            ),
          ),
          Text(
            widget.score > 50? '$checmethod Verified': 'Invalid $checmethod Provided, \n ${widget.message} ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF7D7D7D),
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              height: 2.29,
            ),
          ),
          SizedBox(height: 50),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Closing in ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                    height: 2.46,
                  ),
                ),
                TextSpan(
                  text: '$start',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    height: 2.46,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          InkWell(
            onTap: () async {
              widget.onResponse(
                {
                  "close": widget.score > 50
                }
              );
              _timer?.cancel();
            },
            child: Container(
              width: double.infinity,
              height: 47,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: const Color(0xFF181619),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                widget.score > 50?'Home': 'Try again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get checmethod {
    switch (widget.checkoutmethod) {
      case CheckoutMethod.bvn:
        return "BVN";
      case CheckoutMethod.nin:
        return "NIN";
      case CheckoutMethod.facial:
        return "FACIAL";
      default:
        return "Selectable";
    }
  }
}
