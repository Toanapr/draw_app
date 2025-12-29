import 'package:flutter/material.dart';
import '../models/shape.dart';

/// Custom painter for drawing shapes on the canvas
class CanvasPainter extends CustomPainter {
  final List<Shape> shapes;
  final Shape? previewShape;
  final Shape? selectedShape;
  final int? activeHandleIndex;
  final bool isDragging;
  final Offset? cursorPosition;

  CanvasPainter({
    required this.shapes,
    this.previewShape,
    this.selectedShape,
    this.activeHandleIndex,
    this.isDragging = false,
    this.cursorPosition,
  });

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

    // Draw overlay information during drag operations
    if (isDragging && cursorPosition != null && selectedShape != null) {
      _drawDragOverlay(canvas, selectedShape!);
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

    // Corners: 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight
    final corners = [
      bounds.topLeft, // index 0
      bounds.topRight, // index 1
      bounds.bottomLeft, // index 2
      bounds.bottomRight, // index 3
    ];

    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      // Highlight active handle with larger size
      final isActive = activeHandleIndex == i;
      final handleSize = isActive ? 14.0 : 10.0;

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

  /// Draw overlay information during drag operations
  void _drawDragOverlay(Canvas canvas, Shape shape) {
    if (cursorPosition == null) return;

    final bounds = shape.getBounds();
    String overlayText;

    if (activeHandleIndex != null) {
      // Resizing - show width × height
      overlayText =
          '${bounds.width.toStringAsFixed(0)} × ${bounds.height.toStringAsFixed(0)}';
    } else {
      // Moving - show x, y position
      overlayText =
          '${bounds.center.dx.toStringAsFixed(0)}, ${bounds.center.dy.toStringAsFixed(0)}';
    }

    // Create text painter
    final textSpan = TextSpan(
      text: overlayText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position overlay 20px offset from cursor
    final overlayPosition = cursorPosition! + const Offset(20, 20);

    // Draw semi-transparent background
    final backgroundRect = Rect.fromLTWH(
      overlayPosition.dx - 4,
      overlayPosition.dy - 4,
      textPainter.width + 8,
      textPainter.height + 8,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
      backgroundPaint,
    );

    // Draw text
    textPainter.paint(canvas, overlayPosition);
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
        oldDelegate.selectedShape != selectedShape ||
        oldDelegate.activeHandleIndex != activeHandleIndex ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.cursorPosition != cursorPosition;
  }
}
