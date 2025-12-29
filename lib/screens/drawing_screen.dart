import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/drawing_state.dart';
import '../providers/theme_provider.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/toolbar_desktop.dart';
import '../widgets/toolbar_mobile.dart';
import '../utils/file_handler.dart';
import '../utils/image_exporter.dart';

/// Main drawing screen with responsive layout
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we should use desktop or mobile layout
        final isDesktop = constraints.maxWidth > 600;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  /// Build desktop layout (with sidebar)
  Widget _buildDesktopLayout() {
    final themeProvider = context.watch<ThemeProvider>();
    final drawingState = context.watch<DrawingState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw App'),
        actions: [
          // Undo
          IconButton(
            onPressed: drawingState.canUndo ? drawingState.undo : null,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo (Ctrl+Z)',
          ),
          // Redo
          IconButton(
            onPressed: drawingState.canRedo ? drawingState.redo : null,
            icon: const Icon(Icons.redo),
            tooltip: 'Redo (Ctrl+Y)',
          ),
          // Delete
          IconButton(
            onPressed: drawingState.hasSelection
                ? drawingState.deleteSelected
                : null,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete (Delete key)',
          ),
          const SizedBox(width: 8),
          // Theme toggle
          IconButton(
            onPressed: themeProvider.toggleTheme,
            icon: Icon(themeProvider.themeIcon),
            tooltip: themeProvider.themeTooltip,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Sidebar toolbar
          ToolbarDesktop(
            onSave: _handleSave,
            onLoad: _handleLoad,
            onExport: _handleExport,
            onClear: _handleClear,
          ),
          // Vertical divider
          const VerticalDivider(width: 1),
          // Drawing canvas
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: const DrawingCanvas(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build mobile layout (with bottom bar)
  Widget _buildMobileLayout() {
    final themeProvider = context.watch<ThemeProvider>();
    final drawingState = context.watch<DrawingState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw App'),
        actions: [
          // Undo
          IconButton(
            onPressed: drawingState.canUndo ? drawingState.undo : null,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
          ),
          // Redo
          IconButton(
            onPressed: drawingState.canRedo ? drawingState.redo : null,
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
          ),
          // Delete
          IconButton(
            onPressed: drawingState.hasSelection
                ? drawingState.deleteSelected
                : null,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
          // Theme toggle
          IconButton(
            onPressed: themeProvider.toggleTheme,
            icon: Icon(themeProvider.themeIcon),
            tooltip: themeProvider.themeTooltip,
          ),
        ],
      ),
      body: RepaintBoundary(key: _canvasKey, child: const DrawingCanvas()),
      bottomNavigationBar: ToolbarMobile(
        onSave: _handleSave,
        onLoad: _handleLoad,
        onExport: _handleExport,
        onClear: _handleClear,
      ),
    );
  }

  /// Handle save project
  Future<void> _handleSave() async {
    final drawingState = context.read<DrawingState>();
    final shapes = drawingState.shapes;

    if (shapes.isEmpty) {
      _showSnackBar('No shapes to save', Colors.orange);
      return;
    }

    final success = await FileHandler.saveProject(shapes);
    if (mounted) {
      _showSnackBar(
        success ? 'Project saved successfully' : 'Failed to save project',
        success ? Colors.green : Colors.red,
      );
    }
  }

  /// Handle load project
  Future<void> _handleLoad() async {
    final shapes = await FileHandler.loadProject();

    if (shapes == null) {
      // User canceled or error occurred
      return;
    }

    if (mounted) {
      final drawingState = context.read<DrawingState>();
      drawingState.loadShapes(shapes);
      _showSnackBar(
        'Project loaded successfully (${shapes.length} shapes)',
        Colors.green,
      );
    }
  }

  /// Handle export image
  Future<void> _handleExport() async {
    final drawingState = context.read<DrawingState>();
    if (drawingState.shapes.isEmpty) {
      _showSnackBar('No shapes to export', Colors.orange);
      return;
    }

    if (mounted) {
      await ImageExporter.showExportDialog(context, _canvasKey);
    }
  }

  /// Handle clear all
  void _handleClear() {
    final drawingState = context.read<DrawingState>();
    drawingState.clearAll();
    _showSnackBar('Canvas cleared', Colors.blue);
  }

  /// Show snackbar message
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
