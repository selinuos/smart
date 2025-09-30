import 'package:flutter/material.dart';
import '../models/sample.dart';

class LiveCanvas extends StatelessWidget {
  final List<Sample> samples;
  LiveCanvas({required this.samples});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CanvasPainter(samples: samples),
      size: Size.infinite,
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Sample> samples;
  _CanvasPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (samples.isEmpty) {
      final p = Offset(size.width/2, size.height/2);
      canvas.drawCircle(p, 4, paint);
      return;
    }

    final path = Path();
    double cx = size.width/2;
    double cy = size.height/2;
    path.moveTo(cx, cy);
    for (int i=0;i<samples.length;i++) {
      cx += samples[i].ax * 6;
      cy += -samples[i].ay * 6;
      cx = cx.clamp(0.0, size.width);
      cy = cy.clamp(0.0, size.height);
      path.lineTo(cx, cy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}