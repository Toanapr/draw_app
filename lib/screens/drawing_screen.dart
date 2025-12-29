import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/drawing_state.dart';
import '../providers/theme_provider.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/toolbar_desktop.dart';
import '../widgets/toolbar_mobile.dart';
import '../widgets/properties_panel.dart';
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
        final isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        );
      },
    );
  }

  /// Build desktop layout (with floating sidebar and right panel)
  Widget _buildDesktopLayout() {
    final themeProvider = context.watch<ThemeProvider>();
    final drawingState = context.watch<DrawingState>();

    return Stack(
      children: [
        // Main Canvas Area
        Positioned.fill(
          child: Container(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[100]
                : const Color(0xFF020617), // Slate 950
            padding: const EdgeInsets.fromLTRB(100, 100, 300, 20),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: const DrawingCanvas(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Top Bar
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: _buildTopBar(themeProvider, drawingState),
        ),

        // Left Sidebar (Tools)
        Positioned(
          left: 20,
          top: 100,
          bottom: 20,
          child: ToolbarDesktop(
            onSave: _handleSave,
            onLoad: _handleLoad,
            onExport: _handleExport,
            onClear: _handleClear,
          ),
        ),

        // Right Panel (Properties)
        Positioned(
          right: 20,
          top: 100,
          bottom: 20,
          child: PropertiesPanel(
            onSave: _handleSave,
            onLoad: _handleLoad,
            onExport: _handleExport,
          ),
        ),
      ],
    );
  }

  /// Build mobile layout (with bottom bar)
  Widget _buildMobileLayout() {
    final themeProvider = context.watch<ThemeProvider>();
    final drawingState = context.watch<DrawingState>();

    return Stack(
      children: [
        // Canvas
        Positioned.fill(
          child: RepaintBoundary(key: _canvasKey, child: const DrawingCanvas()),
        ),

        // Top Actions
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: Column(
            children: [
              _buildFloatingAction(
                icon: themeProvider.themeIcon,
                onPressed: themeProvider.toggleTheme,
                tooltip: themeProvider.themeTooltip,
              ),
              const SizedBox(height: 12),
              _buildFloatingAction(
                icon: LucideIcons.undo2,
                onPressed: drawingState.canUndo ? drawingState.undo : null,
                tooltip: 'Undo',
              ),
              const SizedBox(height: 12),
              _buildFloatingAction(
                icon: LucideIcons.redo2,
                onPressed: drawingState.canRedo ? drawingState.redo : null,
                tooltip: 'Redo',
              ),
            ],
          ),
        ),

        // Bottom Toolbar
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: ToolbarMobile(
            onSave: _handleSave,
            onLoad: _handleLoad,
            onExport: _handleExport,
            onClear: _handleClear,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(ThemeProvider themeProvider, DrawingState drawingState) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.palette, size: 24),
          const SizedBox(width: 12),
          Text(
            'Simple Draw',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _buildActionBtn(
            icon: LucideIcons.undo2,
            onPressed: drawingState.canUndo ? drawingState.undo : null,
            tooltip: 'Undo',
          ),
          _buildActionBtn(
            icon: LucideIcons.redo2,
            onPressed: drawingState.canRedo ? drawingState.redo : null,
            tooltip: 'Redo',
          ),
          const VerticalDivider(indent: 15, endIndent: 15, width: 30),
          _buildActionBtn(
            icon: themeProvider.themeIcon,
            onPressed: themeProvider.toggleTheme,
            tooltip: themeProvider.themeTooltip,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _handleExport,
            icon: const Icon(LucideIcons.download, size: 16),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      splashRadius: 24,
    );
  }

  Widget _buildFloatingAction({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
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
