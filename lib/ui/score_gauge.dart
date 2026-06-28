import 'dart:math';
import 'package:flutter/material.dart';

class ScoreGauge extends StatelessWidget {
  final double score;

  const ScoreGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: _GaugePainter(score: score),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;

  _GaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final radius = min(size.width / 2.5, size.height * 0.7);
    final strokeWidth = 20.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw Red Range (0 - 50)
    paint.color = Colors.red;
    canvas.drawArc(rect, pi, pi * 0.5, false, paint);

    // Draw Orange Range (50 - 75)
    paint.color = Colors.orange;
    canvas.drawArc(rect, pi * 1.5, pi * 0.25, false, paint);

    // Draw Green Range (75 - 100)
    paint.color = Colors.green;
    canvas.drawArc(rect, pi * 1.75, pi * 0.25, false, paint);

    // Draw Needle
    final needlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final scoreAngle = pi + (score / 100) * pi;
    final needleLength = radius * 0.9;
    final needleTarget = Offset(
      center.dx + cos(scoreAngle) * needleLength,
      center.dy + sin(scoreAngle) * needleLength,
    );

    canvas.drawLine(center, needleTarget, Paint()..strokeWidth = 4..color = Colors.black);
    canvas.drawCircle(center, 8, needlePaint);
    
    // Draw score text under needle? Or already handled in Scorepage
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
