import 'package:flutter/material.dart';
import '../models/shape.dart';

/// Custom painter for drawing shapes on the canvas
class CanvasPainter extends CustomPainter {
  final List<Shape> shapes;
  final Shape? previewShape;
  final Shape? selectedShape;

  CanvasPainter({required this.shapes, this.previewShape, this.selectedShape});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed shapes
    for (final shape in shapes) {
      shape.draw(canvas);

      // Draw selection indicators for selected shape
      if (shape.isSelected) {
        _drawSelectionIndicator(canvas, shape);
      }
    }

    // Draw preview shape with reduced opacity
    if (previewShape != null) {
      canvas.saveLayer(null, Paint()..color = Colors.white.withOpacity(0.7));
      previewShape!.draw(canvas);
      canvas.restore();
    }
  }

  /// Draw selection indicator around a shape
  void _drawSelectionIndicator(Canvas canvas, Shape shape) {
    final bounds = shape.getBounds();

    // Draw dashed border
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _drawDashedRect(canvas, bounds.inflate(4), paint);

    // Draw corner handles
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final handleSize = 6.0;
    final corners = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, handleSize, handlePaint);
      canvas.drawCircle(
        corner,
        handleSize,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  /// Draw a dashed rectangle
  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;

    // Top edge
    _drawDashedLine(
      canvas,
      rect.topLeft,
      rect.topRight,
      paint,
      dashWidth,
      dashSpace,
    );

    // Right edge
    _drawDashedLine(
      canvas,
      rect.topRight,
      rect.bottomRight,
      paint,
      dashWidth,
      dashSpace,
    );

    // Bottom edge
    _drawDashedLine(
      canvas,
      rect.bottomRight,
      rect.bottomLeft,
      paint,
      dashWidth,
      dashSpace,
    );

    // Left edge
    _drawDashedLine(
      canvas,
      rect.bottomLeft,
      rect.topLeft,
      paint,
      dashWidth,
      dashSpace,
    );
  }

  /// Draw a dashed line between two points
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final path = Path();
    final totalDistance = (end - start).distance;
    final dashCount = (totalDistance / (dashWidth + dashSpace)).floor();

    var currentDistance = 0.0;
    final dx = (end.dx - start.dx) / totalDistance;
    final dy = (end.dy - start.dy) / totalDistance;

    for (var i = 0; i < dashCount; i++) {
      final dashStart = Offset(
        start.dx + dx * currentDistance,
        start.dy + dy * currentDistance,
      );
      currentDistance += dashWidth;
      final dashEnd = Offset(
        start.dx + dx * currentDistance,
        start.dy + dy * currentDistance,
      );
      path.moveTo(dashStart.dx, dashStart.dy);
      path.lineTo(dashEnd.dx, dashEnd.dy);
      currentDistance += dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.shapes != shapes ||
        oldDelegate.previewShape != previewShape ||
        oldDelegate.selectedShape != selectedShape;
  }
}
