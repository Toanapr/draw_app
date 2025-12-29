import 'dart:math';
import 'package:flutter/material.dart';
import '../models/shape.dart';

/// State management for the drawing canvas
class DrawingState extends ChangeNotifier {
  // List of all drawn shapes
  final List<Shape> _shapes = [];

  // Stack for redo functionality
  final List<Shape> _redoStack = [];

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

  // Getters
  List<Shape> get shapes => List.unmodifiable(_shapes);
  List<Shape> get redoStack => List.unmodifiable(_redoStack);
  ShapeType get currentTool => _currentTool;
  Color get strokeColor => _strokeColor;
  Color get fillColor => _fillColor;
  double get strokeWidth => _strokeWidth;
  Shape? get previewShape => _previewShape;
  Shape? get selectedShape => _selectedShape;

  bool get canUndo => _shapes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasSelection => _selectedShape != null;

  // Setters
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

  /// Start drawing a new shape
  void startDrawing(Offset point) {
    if (_currentTool == ShapeType.select) return;

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
      _shapes.add(_previewShape!);
      _previewShape = null;
      _redoStack.clear(); // Clear redo stack when new action is performed
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
      _shapes.remove(_selectedShape);
      _selectedShape = null;
      _redoStack.clear();
      notifyListeners();
    }
  }

  /// Undo the last action
  void undo() {
    if (_shapes.isNotEmpty) {
      final lastShape = _shapes.removeLast();
      _redoStack.add(lastShape);
      deselectAll();
      notifyListeners();
    }
  }

  /// Redo the last undone action
  void redo() {
    if (_redoStack.isNotEmpty) {
      final shape = _redoStack.removeLast();
      _shapes.add(shape);
      notifyListeners();
    }
  }

  /// Clear all shapes
  void clearAll() {
    if (_shapes.isNotEmpty) {
      _shapes.clear();
      _redoStack.clear();
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
