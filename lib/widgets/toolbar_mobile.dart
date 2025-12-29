import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shape.dart';
import '../providers/drawing_state.dart';
import 'color_picker_button.dart';

/// Mobile toolbar (horizontal bottom bar)
class ToolbarMobile extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onExport;
  final VoidCallback onClear;

  const ToolbarMobile({
    super.key,
    required this.onSave,
    required this.onLoad,
    required this.onExport,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final drawingState = context.watch<DrawingState>();

    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // Tool selection in horizontal scroll
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
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
                      isSelected:
                          drawingState.currentTool == ShapeType.rectangle,
                      onTap: () => drawingState.setTool(ShapeType.rectangle),
                    ),
                  ],
                ),
              ),
            ),

            // Vertical divider
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),

            // Settings menu button
            IconButton(
              icon: const Icon(Icons.palette),
              tooltip: 'Colors & Width',
              onPressed: () => _showSettingsSheet(context, drawingState),
            ),

            // File menu button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More Options',
              onSelected: (value) {
                switch (value) {
                  case 'save':
                    onSave();
                    break;
                  case 'load':
                    onLoad();
                    break;
                  case 'export':
                    onExport();
                    break;
                  case 'clear':
                    _showClearConfirmation(context, onClear);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'save',
                  enabled: drawingState.shapes.isNotEmpty,
                  child: const Row(
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 12),
                      Text('Save Project'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'load',
                  child: Row(
                    children: [
                      Icon(Icons.folder_open),
                      SizedBox(width: 12),
                      Text('Load Project'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  enabled: drawingState.shapes.isNotEmpty,
                  child: const Row(
                    children: [
                      Icon(Icons.image),
                      SizedBox(width: 12),
                      Text('Export Image'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear',
                  enabled: drawingState.shapes.isNotEmpty,
                  child: const Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Clear All', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
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
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, DrawingState drawingState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Colors & Stroke Width',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ColorPickerButton(
                  currentColor: drawingState.strokeColor,
                  label: 'Stroke Color',
                  onColorChanged: (color) => drawingState.setStrokeColor(color),
                ),
                ColorPickerButton(
                  currentColor: drawingState.fillColor,
                  label: 'Fill Color',
                  onColorChanged: (color) => drawingState.setFillColor(color),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.line_weight),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: drawingState.strokeWidth,
                    min: 1.0,
                    max: 20.0,
                    divisions: 38,
                    label: drawingState.strokeWidth.toStringAsFixed(1),
                    onChanged: (value) => drawingState.setStrokeWidth(value),
                  ),
                ),
                Text(
                  drawingState.strokeWidth.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
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
