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

  /// Handle pan start (start drawing)
  void _handlePanStart(DragStartDetails details, DrawingState drawingState) {
    // Don't start drawing in Select mode
    if (drawingState.currentTool == ShapeType.select) {
      return;
    }

    final localPosition = details.localPosition;
    drawingState.startDrawing(localPosition);
  }

  /// Handle pan update (continue drawing)
  void _handlePanUpdate(DragUpdateDetails details, DrawingState drawingState) {
    // Don't draw in Select mode
    if (drawingState.currentTool == ShapeType.select) {
      return;
    }

    final localPosition = details.localPosition;
    drawingState.updateDrawing(localPosition);
  }

  /// Handle pan end (finish drawing)
  void _handlePanEnd(DragEndDetails details, DrawingState drawingState) {
    // Don't finish drawing in Select mode
    if (drawingState.currentTool == ShapeType.select) {
      return;
    }

    drawingState.finishDrawing();
  }
}
