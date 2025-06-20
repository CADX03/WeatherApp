import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Class to handle the sun path painter
class SunPathPainter extends CustomPainter {
  final TimeOfDay sunrise;
  final TimeOfDay sunset;
  final TimeOfDay currentTime;
  final BuildContext context;

  SunPathPainter(this.sunrise, this.sunset, this.currentTime, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final paintArc = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintSun = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final radius = size.width / 2 - 20;

    final arcRect = Rect.fromCircle(center: Offset(centerX, size.height), radius: radius);
    canvas.drawArc(arcRect, pi, pi, false, paintArc);

    final totalMinutes = _timeToMinutes(sunset) - _timeToMinutes(sunrise);
    final currentMinutes = _timeToMinutes(currentTime) - _timeToMinutes(sunrise);
    final percent = (currentMinutes / totalMinutes).clamp(0.0, 1.0);

    final sunAngle = pi + pi * percent;
    final sunX = centerX + radius * cos(sunAngle);
    final sunY = size.height + radius * sin(sunAngle);

    canvas.drawCircle(Offset(sunX, sunY), 10, paintSun);

    // Draw sunrise time (left end)
    _drawTimeLabel(canvas, Offset(centerX - radius, size.height), sunrise);

    // Draw sunset time (right end)
    _drawTimeLabel(canvas, Offset(centerX + radius, size.height), sunset);

  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  // Helper method to draw the time label
  void _drawTimeLabel(Canvas canvas, Offset position, TimeOfDay time) {
    final textSpan = TextSpan(
      text: time.format(context), // ✅ Use context here
      style: const TextStyle(color: Colors.white, fontSize: 15),
    );

    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final offset = Offset(position.dx - tp.width / 2, position.dy + 4);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}