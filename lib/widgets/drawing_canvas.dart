import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/shape.dart';
import '../painters/canvas_painter.dart';
import '../providers/drawing_state.dart';

/// Main drawing canvas widget
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final FocusNode _focusNode = FocusNode();

  // Drag state for move/resize operations
  bool _isDragging = false;
  int? _activeHandleIndex; // null = dragging shape body, 0-3 = corner handles
  Offset? _dragStartOffset;
  Rect? _originalShapeBounds;

  // Hit detection radius for corner handles (increased for better usability)
  static const double _handleHitRadius = 35.0;

  @override
  void initState() {
    super.initState();
    // Request focus to receive keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = context.watch<DrawingState>();

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _handleKeyEvent(event, drawingState),
      child: GestureDetector(
        onTapDown: (details) => _handleTap(details, drawingState),
        onPanStart: (details) => _handlePanStart(details, drawingState),
        onPanUpdate: (details) => _handlePanUpdate(details, drawingState),
        onPanEnd: (details) => _handlePanEnd(details, drawingState),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: CustomPaint(
            painter: CanvasPainter(
              shapes: drawingState.shapes,
              previewShape: drawingState.previewShape,
              selectedShape: drawingState.selectedShape,
              activeHandleIndex: _activeHandleIndex,
              isDragging: _isDragging,
              cursorPosition: _dragStartOffset,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  /// Handle keyboard events (shortcuts)
  KeyEventResult _handleKeyEvent(KeyEvent event, DrawingState drawingState) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Check for Ctrl key combinations
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

    if (isCtrlPressed) {
      // Ctrl+Z: Undo
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        drawingState.undo();
        return KeyEventResult.handled;
      }
      // Ctrl+Y: Redo
      if (event.logicalKey == LogicalKeyboardKey.keyY) {
        drawingState.redo();
        return KeyEventResult.handled;
      }
      // Ctrl+S: Save (handled by parent screen, but we can consume the event)
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        // This will be handled by the parent screen
        return KeyEventResult.handled;
      }
    }

    // Delete key: Delete selected shape
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      drawingState.deleteSelected();
      return KeyEventResult.handled;
    }

    // Escape: Deselect or cancel drawing
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      drawingState.deselectAll();
      drawingState.cancelDrawing();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle tap events (for selection)
  void _handleTap(TapDownDetails details, DrawingState drawingState) {
    // Only handle taps in Select mode
    if (drawingState.currentTool == ShapeType.select) {
      final localPosition = details.localPosition;
      drawingState.selectShapeAt(localPosition);
    }
  }

  /// Get the index of the corner handle at the given position
  /// Returns 0-3 for corners (topLeft, topRight, bottomLeft, bottomRight)
  /// Returns null if not hitting any handle
  int? _getHandleIndexAt(Offset position, Rect bounds) {
    final corners = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ];

    for (int i = 0; i < corners.length; i++) {
      if ((position - corners[i]).distance <= _handleHitRadius) {
        return i;
      }
    }

    return null;
  }

  /// Handle pan start (start drawing)
  void _handlePanStart(DragStartDetails details, DrawingState drawingState) {
    final localPosition = details.localPosition;

    // Handle selection mode with dragging
    if (drawingState.currentTool == ShapeType.select) {
      if (drawingState.selectedShape != null) {
        final bounds = drawingState.selectedShape!.getBounds();

        // Check if tap is on a corner handle
        final handleIndex = _getHandleIndexAt(localPosition, bounds);

        if (handleIndex != null) {
          // Starting resize operation
          setState(() {
            _isDragging = true;
            _activeHandleIndex = handleIndex;
            _dragStartOffset = localPosition;
            _originalShapeBounds = bounds;
          });
        } else if (bounds.contains(localPosition)) {
          // Starting move operation (dragging shape body)
          setState(() {
            _isDragging = true;
            _activeHandleIndex = null;
            _dragStartOffset = localPosition;
            _originalShapeBounds = bounds;
          });
        }
      }
      return;
    }

    // Normal drawing mode
    drawingState.startDrawing(localPosition);
  }

  /// Handle pan update (continue drawing)
  void _handlePanUpdate(DragUpdateDetails details, DrawingState drawingState) {
    final localPosition = details.localPosition;

    // Handle selection mode dragging
    if (drawingState.currentTool == ShapeType.select && _isDragging) {
      if (_activeHandleIndex != null) {
        // Resize operation
        drawingState.resizeSelectedShape(_activeHandleIndex!, localPosition);
      } else {
        // Move operation
        final delta = localPosition - _dragStartOffset!;
        drawingState.moveSelectedShape(delta);
        _dragStartOffset = localPosition; // Update for next delta
      }

      setState(() {}); // Update cursor position for overlay
      return;
    }

    // Normal drawing mode
    drawingState.updateDrawing(localPosition);
  }

  /// Handle pan end (finish drawing)
  void _handlePanEnd(DragEndDetails details, DrawingState drawingState) {
    // Handle selection mode drag end
    if (drawingState.currentTool == ShapeType.select && _isDragging) {
      // Save undo snapshot after move/resize completes
      drawingState.saveTransformSnapshot();

      setState(() {
        _isDragging = false;
        _activeHandleIndex = null;
        _dragStartOffset = null;
        _originalShapeBounds = null;
      });
      return;
    }

    // Normal drawing mode
    drawingState.finishDrawing();
  }
}
