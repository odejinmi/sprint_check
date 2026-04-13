import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_detector_service.dart';

/// Custom painter that draws face detection overlays
class FacePainter extends CustomPainter {
  final List<FaceDetectionResult> results;
  final Size imageSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  FacePainter({
    required this.results,
    required this.imageSize,
    this.rotation = InputImageRotation.rotation0deg,
    this.isFrontCamera = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final face = result.face;
      final rect = face.boundingBox;

      // Transform coordinates
      double left = rect.left * scaleX;
      double top = rect.top * scaleY;
      double right = rect.right * scaleX;
      double bottom = rect.bottom * scaleY;

      if (isFrontCamera) {
        final temp = left;
        left = size.width - right;
        right = size.width - temp;
      }

      final faceRect = Rect.fromLTRB(left, top, right, bottom);

      // Draw bounding box
      final boxPaint = Paint()
        ..color = const Color(0xFF00D4FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(faceRect, const Radius.circular(8)),
        boxPaint,
      );

      // Draw corner accents
      _drawCornerAccents(canvas, faceRect);

      // Draw landmarks
      _drawLandmarks(canvas, face, scaleX, scaleY, size);

      // Draw contours
      _drawContours(canvas, face, scaleX, scaleY, size);

      // Draw info label
      _drawInfoLabel(canvas, faceRect, result, i);
    }
  }

  void _drawCornerAccents(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const len = 18.0;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + len), Offset(rect.left, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + len, rect.top), paint);

    // Top-right
    canvas.drawLine(Offset(rect.right - len, rect.top), Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + len), paint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - len), Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + len, rect.bottom), paint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right - len, rect.bottom), Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - len), paint);
  }

  void _drawLandmarks(Canvas canvas, Face face, double scaleX, double scaleY, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (final type in FaceLandmarkType.values) {
      final landmark = face.landmarks[type];
      if (landmark != null) {
        double x = landmark.position.x.toDouble() * scaleX;
        double y = landmark.position.y.toDouble() * scaleY;
        if (isFrontCamera) x = size.width - x;
        canvas.drawCircle(Offset(x, y), 3.0, paint);
      }
    }
  }

  void _drawContours(Canvas canvas, Face face, double scaleX, double scaleY, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final type in FaceContourType.values) {
      final contour = face.contours[type];
      if (contour != null && contour.points.length > 1) {
        final path = Path();
        for (int i = 0; i < contour.points.length; i++) {
          double x = contour.points[i].x.toDouble() * scaleX;
          double y = contour.points[i].y.toDouble() * scaleY;
          if (isFrontCamera) x = size.width - x;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawInfoLabel(Canvas canvas, Rect faceRect, FaceDetectionResult result, int index) {
    final labels = <String>[];
    labels.add('Face ${index + 1}');
    if (result.estimatedAge != null) labels.add('Age: ~${result.estimatedAge}');
    if (result.estimatedGender != null) labels.add(result.estimatedGender!);
    if (result.dominantExpression != null) {
      final emoji = _getExpressionEmoji(result.dominantExpression!);
      labels.add('$emoji ${result.dominantExpression}');
    }

    const fontSize = 12.0;
    const padding = 8.0;
    final lineHeight = fontSize + 4;
    final labelHeight = labels.length * lineHeight + padding * 2;
    double maxWidth = 0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final label in labels) {
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      maxWidth = max(maxWidth, textPainter.width);
    }
    maxWidth += padding * 2;

    // Position above the face box
    double labelTop = faceRect.top - labelHeight - 6;
    if (labelTop < 0) labelTop = faceRect.bottom + 6;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(faceRect.left, labelTop, maxWidth, labelHeight),
      const Radius.circular(8),
    );

    // Background
    final bgPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRRect(bgRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bgRect, borderPaint);

    // Text
    for (int i = 0; i < labels.length; i++) {
      final color = i == 0 ? const Color(0xFF00D4FF) : const Color(0xFFE0E0E0);
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(faceRect.left + padding, labelTop + padding + i * lineHeight),
      );
    }
  }

  String _getExpressionEmoji(String expression) {
    switch (expression.toLowerCase()) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'angry': return '😠';
      case 'surprised': return '😲';
      case 'neutral': return '😐';
      case 'disgusted': return '🤢';
      case 'fearful': return '😨';
      default: return '😐';
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.results != results;
  }
}