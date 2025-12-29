import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shape.dart';
import '../providers/drawing_state.dart';
import 'color_picker_button.dart';

/// Desktop toolbar (vertical sidebar)
class ToolbarDesktop extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onExport;
  final VoidCallback onClear;

  const ToolbarDesktop({
    super.key,
    required this.onSave,
    required this.onLoad,
    required this.onExport,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final drawingState = context.watch<DrawingState>();

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Tool selection buttons
          _buildToolButton(
            context,
            icon: Icons.touch_app,
            label: 'Select',
            isSelected: drawingState.currentTool == ShapeType.select,
            onTap: () => drawingState.setTool(ShapeType.select),
          ),
          _buildToolButton(
            context,
            icon: Icons.brush,
            label: 'Pencil',
            isSelected: drawingState.currentTool == ShapeType.pencil,
            onTap: () => drawingState.setTool(ShapeType.pencil),
          ),
          _buildToolButton(
            context,
            icon: Icons.circle_outlined,
            label: 'Point',
            isSelected: drawingState.currentTool == ShapeType.point,
            onTap: () => drawingState.setTool(ShapeType.point),
          ),
          _buildToolButton(
            context,
            icon: Icons.show_chart,
            label: 'Line',
            isSelected: drawingState.currentTool == ShapeType.line,
            onTap: () => drawingState.setTool(ShapeType.line),
          ),
          _buildToolButton(
            context,
            icon: Icons.circle,
            label: 'Circle',
            isSelected: drawingState.currentTool == ShapeType.circle,
            onTap: () => drawingState.setTool(ShapeType.circle),
          ),
          _buildToolButton(
            context,
            icon: Icons.panorama_fish_eye,
            label: 'Ellipse',
            isSelected: drawingState.currentTool == ShapeType.ellipse,
            onTap: () => drawingState.setTool(ShapeType.ellipse),
          ),
          _buildToolButton(
            context,
            icon: Icons.crop_square,
            label: 'Square',
            isSelected: drawingState.currentTool == ShapeType.square,
            onTap: () => drawingState.setTool(ShapeType.square),
          ),
          _buildToolButton(
            context,
            icon: Icons.rectangle_outlined,
            label: 'Rectangle',
            isSelected: drawingState.currentTool == ShapeType.rectangle,
            onTap: () => drawingState.setTool(ShapeType.rectangle),
          ),

          const Divider(height: 24),

          // Color pickers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                ColorPickerButton(
                  currentColor: drawingState.strokeColor,
                  label: 'Stroke',
                  onColorChanged: (color) => drawingState.setStrokeColor(color),
                ),
                const SizedBox(height: 12),
                ColorPickerButton(
                  currentColor: drawingState.fillColor,
                  label: 'Fill',
                  onColorChanged: (color) => drawingState.setFillColor(color),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Stroke width slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text('Width', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  drawingState.strokeWidth.toStringAsFixed(1),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    value: drawingState.strokeWidth,
                    min: 1.0,
                    max: 20.0,
                    divisions: 38,
                    onChanged: (value) => drawingState.setStrokeWidth(value),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Action buttons
          _buildActionButton(
            context,
            icon: Icons.undo,
            label: 'Undo',
            enabled: drawingState.canUndo,
            onTap: drawingState.undo,
          ),
          _buildActionButton(
            context,
            icon: Icons.redo,
            label: 'Redo',
            enabled: drawingState.canRedo,
            onTap: drawingState.redo,
          ),
          _buildActionButton(
            context,
            icon: Icons.delete,
            label: 'Delete',
            enabled: drawingState.hasSelection,
            onTap: drawingState.deleteSelected,
          ),
          _buildActionButton(
            context,
            icon: Icons.clear_all,
            label: 'Clear',
            enabled: drawingState.shapes.isNotEmpty,
            onTap: () => _showClearConfirmation(context, onClear),
          ),

          const Divider(height: 24),

          // File operations
          _buildActionButton(
            context,
            icon: Icons.save,
            label: 'Save',
            enabled: drawingState.shapes.isNotEmpty,
            onTap: onSave,
          ),
          _buildActionButton(
            context,
            icon: Icons.folder_open,
            label: 'Load',
            onTap: onLoad,
          ),
          _buildActionButton(
            context,
            icon: Icons.image,
            label: 'Export',
            enabled: drawingState.shapes.isNotEmpty,
            onTap: onExport,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Tooltip(
        message: label,
        child: Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon),
          iconSize: 28,
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text(
          'Are you sure you want to clear all shapes? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
