import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Enum for different drawing tools
enum ShapeType {
  select,
  pencil,
  point,
  line,
  circle,
  ellipse,
  square,
  rectangle,
}

/// Abstract base class for all drawable shapes
abstract class Shape {
  final String id;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final Offset startPoint;
  final Offset endPoint;
  bool isSelected;

  Shape({
    required this.id,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.startPoint,
    required this.endPoint,
    this.isSelected = false,
  });

  /// Draw the shape on the canvas
  void draw(Canvas canvas);

  /// Check if a point is inside the shape (for selection)
  bool containsPoint(Offset point);

  /// Get the bounding rectangle of the shape
  Rect getBounds();

  /// Serialize the shape to bytes
  Uint8List toBytes();

  /// Get the shape type
  ShapeType get type;

  /// Deserialize a shape from bytes
  static Shape? fromBytes(Uint8List bytes, int offset) {
    if (offset >= bytes.length) return null;

    final byteData = ByteData.sublistView(bytes, offset);
    final type = ShapeType.values[byteData.getUint8(0)];
    final strokeColor = Color(byteData.getUint32(1));
    final fillColor = Color(byteData.getUint32(5));
    final strokeWidth = byteData.getFloat32(9);
    final startX = byteData.getFloat64(13);
    final startY = byteData.getFloat64(21);
    final endX = byteData.getFloat64(29);
    final endY = byteData.getFloat64(37);

    final startPoint = Offset(startX, startY);
    final endPoint = Offset(endX, endY);
    final id =
        DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();

    switch (type) {
      case ShapeType.pencil:
        // Pencil shapes need special deserialization with point count
        return FreehandShape.fromBytesExtended(bytes, offset);
      case ShapeType.point:
        return PointShape(
          id: id,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.line:
        return LineShape(
          id: id,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.circle:
        return CircleShape(
          id: id,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.ellipse:
        return EllipseShape(
          id: id,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.square:
        return SquareShape(
          id: id,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.rectangle:
        return RectangleShape(
          id: id,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      default:
        return null;
    }
  }

  /// Common method to write shape data to bytes
  ByteData _createByteData() {
    final byteData = ByteData(45);
    byteData.setUint8(0, type.index);
    byteData.setUint32(1, strokeColor.value);
    byteData.setUint32(5, fillColor.value);
    byteData.setFloat32(9, strokeWidth);
    byteData.setFloat64(13, startPoint.dx);
    byteData.setFloat64(21, startPoint.dy);
    byteData.setFloat64(29, endPoint.dx);
    byteData.setFloat64(37, endPoint.dy);
    return byteData;
  }

  Uint8List toBytesCommon() {
    final byteData = _createByteData();
    return byteData.buffer.asUint8List();
  }
}

/// Point shape
class PointShape extends Shape {
  PointShape({
    required super.id,
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
    required super.startPoint,
    required super.endPoint,
  });

  @override
  ShapeType get type => ShapeType.point;

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;

    canvas.drawCircle(startPoint, strokeWidth * 2, paint);
  }

  @override
  bool containsPoint(Offset point) {
    final distance = (point - startPoint).distance;
    return distance <= strokeWidth * 2 + 5; // Add 5px tolerance
  }

  @override
  Rect getBounds() {
    final radius = strokeWidth * 2;
    return Rect.fromCircle(center: startPoint, radius: radius);
  }

  @override
  Uint8List toBytes() => toBytesCommon();
}

/// Line shape
class LineShape extends Shape {
  LineShape({
    required super.id,
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
    required super.startPoint,
    required super.endPoint,
  });

  @override
  ShapeType get type => ShapeType.line;

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool containsPoint(Offset point) {
    // Calculate distance from point to line segment
    final dx = endPoint.dx - startPoint.dx;
    final dy = endPoint.dy - startPoint.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return (point - startPoint).distance <= strokeWidth + 5;
    }

    var t =
        ((point.dx - startPoint.dx) * dx + (point.dy - startPoint.dy) * dy) /
        lengthSquared;
    t = t.clamp(0.0, 1.0);

    final projection = Offset(startPoint.dx + t * dx, startPoint.dy + t * dy);

    return (point - projection).distance <= strokeWidth + 5;
  }

  @override
  Rect getBounds() {
    return Rect.fromPoints(startPoint, endPoint).inflate(strokeWidth);
  }

  @override
  Uint8List toBytes() => toBytesCommon();
}

/// Circle shape
class CircleShape extends Shape {
  CircleShape({
    required super.id,
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
    required super.startPoint,
    required super.endPoint,
  });

  @override
  ShapeType get type => ShapeType.circle;

  double get radius => (endPoint - startPoint).distance;

  @override
  void draw(Canvas canvas) {
    // Draw fill
    if (fillColor.alpha > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPoint, radius, fillPaint);
    }

    // Draw stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(startPoint, radius, strokePaint);
  }

  @override
  bool containsPoint(Offset point) {
    final distance = (point - startPoint).distance;
    // Check if point is near the circle's perimeter or inside if filled
    if (fillColor.alpha > 0 && distance <= radius) {
      return true;
    }
    return (distance - radius).abs() <= strokeWidth + 5;
  }

  @override
  Rect getBounds() {
    return Rect.fromCircle(center: startPoint, radius: radius + strokeWidth);
  }

  @override
  Uint8List toBytes() => toBytesCommon();
}

/// Ellipse shape
class EllipseShape extends Shape {
  EllipseShape({
    required super.id,
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
    required super.startPoint,
    required super.endPoint,
  });

  @override
  ShapeType get type => ShapeType.ellipse;

  Rect get rect => Rect.fromPoints(startPoint, endPoint);

  @override
  void draw(Canvas canvas) {
    // Draw fill
    if (fillColor.alpha > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawOval(rect, fillPaint);
    }

    // Draw stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawOval(rect, strokePaint);
  }

  @override
  bool containsPoint(Offset point) {
    final center = rect.center;
    final rx = rect.width / 2;
    final ry = rect.height / 2;

    if (rx == 0 || ry == 0) return false;

    // Normalized point relative to ellipse center
    final nx = (point.dx - center.dx) / rx;
    final ny = (point.dy - center.dy) / ry;
    final distanceFromCenter = sqrt(nx * nx + ny * ny);

    // Check if point is inside ellipse (for filled) or near perimeter (for stroke)
    if (fillColor.alpha > 0 && distanceFromCenter <= 1.0) {
      return true;
    }
    return (distanceFromCenter - 1.0).abs() <= (strokeWidth + 5) / min(rx, ry);
  }

  @override
  Rect getBounds() {
    return rect.inflate(strokeWidth);
  }

  @override
  Uint8List toBytes() => toBytesCommon();
}

/// Square shape
class SquareShape extends Shape {
  SquareShape({
    required super.id,
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
    required super.startPoint,
    required super.endPoint,
  });

  @override
  ShapeType get type => ShapeType.square;

  Rect get rect {
    final side = max(
      (endPoint - startPoint).dx.abs(),
      (endPoint - startPoint).dy.abs(),
    );
    final dx = endPoint.dx >= startPoint.dx ? side : -side;
    final dy = endPoint.dy >= startPoint.dy ? side : -side;
    return Rect.fromPoints(startPoint, startPoint + Offset(dx, dy));
  }

  @override
  void draw(Canvas canvas) {
    // Draw fill
    if (fillColor.alpha > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
    }

    // Draw stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool containsPoint(Offset point) {
    final inflated = rect.inflate(strokeWidth + 5);
    if (!inflated.contains(point)) return false;

    if (fillColor.alpha > 0 && rect.contains(point)) {
      return true;
    }

    // Check if point is near the border
    final deflated = rect.deflate(strokeWidth + 5);
    return !deflated.contains(point);
  }

  @override
  Rect getBounds() {
    return rect.inflate(strokeWidth);
  }

  @override
  Uint8List toBytes() => toBytesCommon();
}

/// Rectangle shape
class RectangleShape extends Shape {
  RectangleShape({
    required super.id,
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
    required super.startPoint,
    required super.endPoint,
  });

  @override
  ShapeType get type => ShapeType.rectangle;

  Rect get rect => Rect.fromPoints(startPoint, endPoint);

  @override
  void draw(Canvas canvas) {
    // Draw fill
    if (fillColor.alpha > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
    }

    // Draw stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool containsPoint(Offset point) {
    final inflated = rect.inflate(strokeWidth + 5);
    if (!inflated.contains(point)) return false;

    if (fillColor.alpha > 0 && rect.contains(point)) {
      return true;
    }

    // Check if point is near the border
    final deflated = rect.deflate(strokeWidth + 5);
    return !deflated.contains(point);
  }

  @override
  Rect getBounds() {
    return rect.inflate(strokeWidth);
  }

  @override
  Uint8List toBytes() => toBytesCommon();
}

/// Freehand pencil shape
class FreehandShape extends Shape {
  final List<Offset> points;
  static const double _minDistanceThreshold = 2.5;

  FreehandShape({
    required super.id,
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
    required super.startPoint,
    required super.endPoint,
    required this.points,
  });

  /// Create freehand shape with single point
  factory FreehandShape.start({
    required String id,
    required Color strokeColor,
    required Color fillColor,
    required double strokeWidth,
    required Offset startPoint,
  }) {
    return FreehandShape(
      id: id,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      startPoint: startPoint,
      endPoint: startPoint,
      points: [startPoint],
    );
  }

  /// Add point with distance-based thinning
  FreehandShape addPoint(Offset point) {
    final List<Offset> newPoints = List.from(points);

    // Apply point thinning: only add if far enough from last point
    if (newPoints.isEmpty ||
        (point - newPoints.last).distance >= _minDistanceThreshold) {
      newPoints.add(point);
    }

    return FreehandShape(
      id: id,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      startPoint: startPoint,
      endPoint: point,
      points: newPoints,
    );
  }

  @override
  ShapeType get type => ShapeType.pencil;

  @override
  void draw(Canvas canvas) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      // Draw single point as circle
      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[0], strokeWidth / 2, paint);
      return;
    }

    // Create path connecting all points
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Draw with rounded caps and joins for smooth appearance
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool containsPoint(Offset point) {
    // Check if point is near any segment of the path
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Calculate distance from point to line segment
      final distance = _distanceToSegment(point, p1, p2);
      if (distance <= strokeWidth / 2 + 5) {
        return true;
      }
    }

    // Check first point if single point
    if (points.length == 1) {
      return (point - points[0]).distance <= strokeWidth / 2 + 5;
    }

    return false;
  }

  /// Calculate distance from point to line segment
  double _distanceToSegment(Offset point, Offset p1, Offset p2) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return (point - p1).distance;
    }

    var t = ((point.dx - p1.dx) * dx + (point.dy - p1.dy) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);

    final projectionX = p1.dx + t * dx;
    final projectionY = p1.dy + t * dy;
    final projection = Offset(projectionX, projectionY);

    return (point - projection).distance;
  }

  @override
  Rect getBounds() {
    if (points.isEmpty) {
      return Rect.fromPoints(startPoint, endPoint);
    }

    double minX = points[0].dx;
    double minY = points[0].dy;
    double maxX = points[0].dx;
    double maxY = points[0].dy;

    for (final point in points) {
      minX = min(minX, point.dx);
      minY = min(minY, point.dy);
      maxX = max(maxX, point.dx);
      maxY = max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(strokeWidth);
  }

  @override
  Uint8List toBytes() {
    // Header: type(1) + colors(8) + strokeWidth(4) + pointCount(4) = 17 bytes
    // Each point: 16 bytes (2 doubles)
    final headerSize = 17;
    final pointSize = 16;
    final totalSize = headerSize + (points.length * pointSize);

    final byteData = ByteData(totalSize);

    // Write header
    byteData.setUint8(0, type.index);
    byteData.setUint32(1, strokeColor.value);
    byteData.setUint32(5, fillColor.value);
    byteData.setFloat32(9, strokeWidth);
    byteData.setUint32(13, points.length);

    // Write all points
    int offset = headerSize;
    for (final point in points) {
      byteData.setFloat64(offset, point.dx);
      byteData.setFloat64(offset + 8, point.dy);
      offset += pointSize;
    }

    return byteData.buffer.asUint8List();
  }

  /// Deserialize freehand shape from bytes
  static FreehandShape? fromBytesExtended(Uint8List bytes, int startOffset) {
    if (startOffset >= bytes.length) return null;

    final byteData = ByteData.sublistView(bytes, startOffset);

    // Read header
    final strokeColor = Color(byteData.getUint32(1));
    final fillColor = Color(byteData.getUint32(5));
    final strokeWidth = byteData.getFloat32(9);
    final pointCount = byteData.getUint32(13);

    // Read all points
    final List<Offset> points = [];
    int offset = 17;
    for (int i = 0; i < pointCount; i++) {
      final x = byteData.getFloat64(offset);
      final y = byteData.getFloat64(offset + 8);
      points.add(Offset(x, y));
      offset += 16;
    }

    final id =
        DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();

    final startPoint = points.isNotEmpty ? points.first : Offset.zero;
    final endPoint = points.isNotEmpty ? points.last : Offset.zero;

    return FreehandShape(
      id: id,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      startPoint: startPoint,
      endPoint: endPoint,
      points: points,
    );
  }
}
