import 'dart:math';
import 'package:flutter/material.dart';
import '../models/shape.dart';

/// State management for the drawing canvas
class DrawingState extends ChangeNotifier {
  // List of all drawn shapes
  final List<Shape> _shapes = [];

  // Stacks for undo/redo functionality (snapshots of the entire canvas)
  final List<List<Shape>> _undoStack = [];
  final List<List<Shape>> _redoStack = [];

  // Current tool being used
  ShapeType _currentTool = ShapeType.line;

  // Current colors and stroke width
  Color _strokeColor = Colors.black;
  Color _fillColor = Colors.transparent;
  double _strokeWidth = 3.0;

  // Shape being drawn (preview)
  Shape? _previewShape;

  // Currently selected shape
  Shape? _selectedShape;

  // Grid visibility
  bool _showGrid = true;

  // Getters
  List<Shape> get shapes => List.unmodifiable(_shapes);
  List<Shape> get redoStack => List.unmodifiable(_redoStack);
  ShapeType get currentTool => _currentTool;
  Color get strokeColor => _strokeColor;
  Color get fillColor => _fillColor;
  double get strokeWidth => _strokeWidth;
  Shape? get previewShape => _previewShape;
  Shape? get selectedShape => _selectedShape;
  bool get showGrid => _showGrid;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasSelection => _selectedShape != null;

  // Setters
  void toggleGrid() {
    _showGrid = !_showGrid;
    notifyListeners();
  }

  void setTool(ShapeType tool) {
    _currentTool = tool;
    // Deselect when switching tools (except to Select tool)
    if (tool != ShapeType.select) {
      deselectAll();
    }
    notifyListeners();
  }

  void setStrokeColor(Color color) {
    _strokeColor = color;
    notifyListeners();
  }

  void setFillColor(Color color) {
    _fillColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  /// Save current state to undo stack
  void _saveToUndoStack() {
    _undoStack.add(List.from(_shapes));
    _redoStack.clear();
  }

  /// Prepare for an action that will modify existing shapes (like move/resize)
  void prepareForAction() {
    _saveToUndoStack();
  }

  /// Start drawing a new shape
  void startDrawing(Offset point) {
    if (_currentTool == ShapeType.select ||
        _currentTool == ShapeType.paintBucket)
      return;

    final id =
        DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();

    _previewShape = _createShape(id: id, startPoint: point, endPoint: point);
    notifyListeners();
  }

  /// Update the shape being drawn
  void updateDrawing(Offset point) {
    if (_previewShape == null) return;

    final id = _previewShape!.id;

    // For pencil tool, accumulate points instead of replacing
    if (_currentTool == ShapeType.pencil && _previewShape is FreehandShape) {
      _previewShape = (_previewShape as FreehandShape).addPoint(point);
    } else {
      // For other shapes, update endpoint
      _previewShape = _createShape(
        id: id,
        startPoint: _previewShape!.startPoint,
        endPoint: point,
      );
    }
    notifyListeners();
  }

  /// Finish drawing and add the shape to the list
  void finishDrawing() {
    if (_previewShape != null) {
      _saveToUndoStack();
      _shapes.add(_previewShape!);
      _previewShape = null;
      notifyListeners();
    }
  }

  /// Cancel drawing
  void cancelDrawing() {
    _previewShape = null;
    notifyListeners();
  }

  /// Create a shape based on current tool and parameters
  Shape _createShape({
    required String id,
    required Offset startPoint,
    required Offset endPoint,
  }) {
    switch (_currentTool) {
      case ShapeType.pencil:
        return FreehandShape.start(
          id: id,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          startPoint: startPoint,
        );
      case ShapeType.point:
        return PointShape(
          id: id,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.line:
        return LineShape(
          id: id,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.circle:
        return CircleShape(
          id: id,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.ellipse:
        return EllipseShape(
          id: id,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.square:
        return SquareShape(
          id: id,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      case ShapeType.rectangle:
        return RectangleShape(
          id: id,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          startPoint: startPoint,
          endPoint: endPoint,
        );
      default:
        throw UnimplementedError('Shape type not implemented');
    }
  }

  /// Select a shape at the given point
  void selectShapeAt(Offset point) {
    deselectAll();

    // Search from top to bottom (reverse order)
    for (int i = _shapes.length - 1; i >= 0; i--) {
      if (_shapes[i].containsPoint(point)) {
        _shapes[i].isSelected = true;
        _selectedShape = _shapes[i];
        notifyListeners();
        return;
      }
    }
  }

  /// Fill a shape at the given point with the current fill color
  void fillShapeAt(Offset point) {
    // Search from top to bottom (reverse order) to find the topmost shape
    for (int i = _shapes.length - 1; i >= 0; i--) {
      final shape = _shapes[i];
      if (shape.containsPoint(point)) {
        // Only fill closed shapes, not lines or freehand drawings
        if (shape is CircleShape ||
            shape is SquareShape ||
            shape is RectangleShape ||
            shape is EllipseShape) {
          _saveToUndoStack();

          // Update the shape's fill color using copyWith
          _shapes[i] = shape.copyWith(fillColor: _fillColor);

          notifyListeners();
          return; // Only fill the topmost shape
        }
      }
    }
  }

  /// Deselect all shapes
  void deselectAll() {
    if (_selectedShape != null) {
      _selectedShape!.isSelected = false;
      _selectedShape = null;
      notifyListeners();
    }
  }

  /// Delete the selected shape
  void deleteSelected() {
    if (_selectedShape != null) {
      _saveToUndoStack();
      _shapes.removeWhere((s) => s.id == _selectedShape!.id);
      _selectedShape = null;
      notifyListeners();
    }
  }

  /// Move the selected shape by the given delta
  void moveSelectedShape(Offset delta) {
    if (_selectedShape == null) return;

    final index = _shapes.indexWhere((s) => s.id == _selectedShape!.id);
    if (index == -1) return;

    if (_selectedShape is FreehandShape) {
      // For freehand shapes, move all points
      final freehand = _selectedShape as FreehandShape;
      final movedPoints = freehand.points.map((p) => p + delta).toList();

      final newShape = FreehandShape(
        id: freehand.id,
        strokeColor: freehand.strokeColor,
        fillColor: freehand.fillColor,
        strokeWidth: freehand.strokeWidth,
        startPoint: freehand.startPoint + delta,
        endPoint: freehand.endPoint + delta,
        points: movedPoints,
      );
      newShape.isSelected = true;

      _shapes[index] = newShape;
      _selectedShape = newShape;
    } else {
      // For standard shapes, create new shape with moved points
      final newShape = _createShapeWithPoints(
        _selectedShape!,
        _selectedShape!.startPoint + delta,
        _selectedShape!.endPoint + delta,
      );
      newShape.isSelected = true;

      _shapes[index] = newShape;
      _selectedShape = newShape;
    }

    notifyListeners();
  }

  /// Resize the selected shape by dragging a corner handle
  /// handleIndex: 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight
  void resizeSelectedShape(int handleIndex, Offset newHandlePosition) {
    if (_selectedShape == null) return;

    final index = _shapes.indexWhere((s) => s.id == _selectedShape!.id);
    if (index == -1) return;

    final shape = _selectedShape!;
    Rect logicalBounds;

    if (shape is FreehandShape) {
      if (shape.points.isEmpty) return;
      double minX = shape.points[0].dx;
      double minY = shape.points[0].dy;
      double maxX = shape.points[0].dx;
      double maxY = shape.points[0].dy;

      for (final point in shape.points) {
        minX = min(minX, point.dx);
        minY = min(minY, point.dy);
        maxX = max(maxX, point.dx);
        maxY = max(maxY, point.dy);
      }
      logicalBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    } else if (shape is CircleShape) {
      // For Circle, logical bounds should be the square that contains it
      logicalBounds = Rect.fromCircle(
        center: shape.startPoint,
        radius: shape.radius,
      );
    } else if (shape is EllipseShape) {
      logicalBounds = shape.rect;
    } else if (shape is SquareShape) {
      logicalBounds = shape.rect;
    } else if (shape is RectangleShape) {
      logicalBounds = shape.rect;
    } else {
      logicalBounds = Rect.fromPoints(shape.startPoint, shape.endPoint);
    }

    // Determine anchor corner (opposite of dragged handle) - MUST stay fixed
    // Handles: 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight
    Offset anchorPoint;
    Offset oldHandlePosition;

    switch (handleIndex) {
      case 0: // dragging topLeft -> bottomRight stays fixed
        anchorPoint = logicalBounds.bottomRight;
        oldHandlePosition = logicalBounds.topLeft;
        break;
      case 1: // dragging topRight -> bottomLeft stays fixed
        anchorPoint = logicalBounds.bottomLeft;
        oldHandlePosition = logicalBounds.topRight;
        break;
      case 2: // dragging bottomLeft -> topRight stays fixed
        anchorPoint = logicalBounds.topRight;
        oldHandlePosition = logicalBounds.bottomLeft;
        break;
      case 3: // dragging bottomRight -> topLeft stays fixed
        anchorPoint = logicalBounds.topLeft;
        oldHandlePosition = logicalBounds.bottomRight;
        break;
      default:
        return;
    }

    // Calculate signed scale factors from fixed anchor point
    final oldWidth = oldHandlePosition.dx - anchorPoint.dx;
    final oldHeight = oldHandlePosition.dy - anchorPoint.dy;
    final newWidth = newHandlePosition.dx - anchorPoint.dx;
    final newHeight = newHandlePosition.dy - anchorPoint.dy;

    // Minimum size threshold to prevent shapes from collapsing to zero
    const double minSize = 5.0;

    // Check if old dimensions are too small (shape was collapsed)
    if (oldWidth.abs() < 0.1 || oldHeight.abs() < 0.1) {
      return; // Don't allow scaling from collapsed state
    }

    // Calculate scale factors
    double scaleX = newWidth / oldWidth;
    double scaleY = newHeight / oldHeight;

    // Enforce minimum size by limiting scale factors
    final oldWidthAbs = oldWidth.abs();
    final oldHeightAbs = oldHeight.abs();

    if (newWidth.abs() < minSize && oldWidthAbs > 0) {
      scaleX = (newWidth >= 0 ? minSize : -minSize) / oldWidth;
    }
    if (newHeight.abs() < minSize && oldHeightAbs > 0) {
      scaleY = (newHeight >= 0 ? minSize : -minSize) / oldHeight;
    }

    // For shapes that should maintain aspect ratio or specific properties
    if (shape is CircleShape || shape is SquareShape) {
      // Use the scale that changed more to maintain square/circle property
      double scale = (newWidth.abs() > newHeight.abs()) ? scaleX : scaleY;

      // Enforce minimum size for uniform scaling
      final minDimension = min(oldWidthAbs, oldHeightAbs);
      if (minDimension * scale.abs() < minSize) {
        scale = (scale >= 0 ? minSize : -minSize) / minDimension;
      }

      scaleX = scale;
      scaleY = scale;
    }

    // Avoid invalid scales
    if (scaleX.isInfinite ||
        scaleY.isInfinite ||
        scaleX.isNaN ||
        scaleY.isNaN ||
        scaleX == 0 ||
        scaleY == 0) {
      return;
    }

    if (shape is FreehandShape) {
      // Transform all points from fixed anchor
      final scaledPoints = shape.points.map((point) {
        final relativePos = point - anchorPoint;
        return anchorPoint +
            Offset(relativePos.dx * scaleX, relativePos.dy * scaleY);
      }).toList();

      final newShape = FreehandShape(
        id: shape.id,
        strokeColor: shape.strokeColor,
        fillColor: shape.fillColor,
        strokeWidth: shape.strokeWidth,
        startPoint: scaledPoints.first,
        endPoint: scaledPoints.last,
        points: scaledPoints,
      );
      newShape.isSelected = true;

      _shapes[index] = newShape;
      _selectedShape = newShape;
    } else {
      // Transform start and end points from fixed anchor
      final oldStart = shape.startPoint;
      final oldEnd = shape.endPoint;

      final newStart =
          anchorPoint +
          Offset(
            (oldStart.dx - anchorPoint.dx) * scaleX,
            (oldStart.dy - anchorPoint.dy) * scaleY,
          );
      final newEnd =
          anchorPoint +
          Offset(
            (oldEnd.dx - anchorPoint.dx) * scaleX,
            (oldEnd.dy - anchorPoint.dy) * scaleY,
          );

      final newShape = _createShapeWithPoints(shape, newStart, newEnd);
      newShape.isSelected = true;

      _shapes[index] = newShape;
      _selectedShape = newShape;
    }

    notifyListeners();
  }

  /// Create a new shape with updated points (helper for move/resize)
  Shape _createShapeWithPoints(Shape original, Offset newStart, Offset newEnd) {
    switch (original.type) {
      case ShapeType.point:
        return PointShape(
          id: original.id,
          strokeColor: original.strokeColor,
          fillColor: original.fillColor,
          strokeWidth: original.strokeWidth,
          startPoint: newStart,
          endPoint: newEnd,
        );
      case ShapeType.line:
        return LineShape(
          id: original.id,
          strokeColor: original.strokeColor,
          fillColor: original.fillColor,
          strokeWidth: original.strokeWidth,
          startPoint: newStart,
          endPoint: newEnd,
        );
      case ShapeType.circle:
        return CircleShape(
          id: original.id,
          strokeColor: original.strokeColor,
          fillColor: original.fillColor,
          strokeWidth: original.strokeWidth,
          startPoint: newStart,
          endPoint: newEnd,
        );
      case ShapeType.ellipse:
        return EllipseShape(
          id: original.id,
          strokeColor: original.strokeColor,
          fillColor: original.fillColor,
          strokeWidth: original.strokeWidth,
          startPoint: newStart,
          endPoint: newEnd,
        );
      case ShapeType.square:
        return SquareShape(
          id: original.id,
          strokeColor: original.strokeColor,
          fillColor: original.fillColor,
          strokeWidth: original.strokeWidth,
          startPoint: newStart,
          endPoint: newEnd,
        );
      case ShapeType.rectangle:
        return RectangleShape(
          id: original.id,
          strokeColor: original.strokeColor,
          fillColor: original.fillColor,
          strokeWidth: original.strokeWidth,
          startPoint: newStart,
          endPoint: newEnd,
        );
      default:
        throw UnimplementedError('Shape type not implemented');
    }
  }

  /// Save transform snapshot for undo (called after move/resize completes)
  void saveTransformSnapshot() {
    // Redo stack is already cleared by _saveToUndoStack called at start of transform
    notifyListeners();
  }

  /// Undo the last action
  void undo() {
    if (_undoStack.isNotEmpty) {
      // Save current state to redo stack before reverting
      _redoStack.add(List.from(_shapes));

      // Revert to last saved state
      final previousState = _undoStack.removeLast();
      _shapes.clear();
      _shapes.addAll(previousState);

      deselectAll();
      notifyListeners();
    }
  }

  /// Redo the last undone action
  void redo() {
    if (_redoStack.isNotEmpty) {
      // Save current state to undo stack before re-applying
      _undoStack.add(List.from(_shapes));

      // Re-apply last undone state
      final nextState = _redoStack.removeLast();
      _shapes.clear();
      _shapes.addAll(nextState);

      notifyListeners();
    }
  }

  /// Clear all shapes
  void clearAll() {
    if (_shapes.isNotEmpty) {
      _saveToUndoStack();
      _shapes.clear();
      deselectAll();
      notifyListeners();
    }
  }

  /// Load shapes from external source (for file loading)
  void loadShapes(List<Shape> newShapes) {
    _shapes.clear();
    _redoStack.clear();
    _shapes.addAll(newShapes);
    deselectAll();
    notifyListeners();
  }

  /// Add a shape directly (for file loading)
  void addShape(Shape shape) {
    _shapes.add(shape);
    notifyListeners();
  }
}
