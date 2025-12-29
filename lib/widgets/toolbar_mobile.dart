import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/shape.dart';
import '../providers/drawing_state.dart';
import 'properties_panel.dart';

/// Mobile toolbar (floating bottom bar)
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildToolButton(
                  context,
                  icon: LucideIcons.mousePointer2,
                  isSelected: drawingState.currentTool == ShapeType.select,
                  onTap: () => drawingState.setTool(ShapeType.select),
                ),
                _buildToolButton(
                  context,
                  icon: LucideIcons.pencil,
                  isSelected: drawingState.currentTool == ShapeType.pencil,
                  onTap: () => drawingState.setTool(ShapeType.pencil),
                ),
                _buildToolButton(
                  context,
                  icon: LucideIcons.dot,
                  isSelected: drawingState.currentTool == ShapeType.point,
                  onTap: () => drawingState.setTool(ShapeType.point),
                ),
                _buildToolButton(
                  context,
                  icon: LucideIcons.minus,
                  isSelected: drawingState.currentTool == ShapeType.line,
                  onTap: () => drawingState.setTool(ShapeType.line),
                ),
                _buildToolButton(
                  context,
                  icon: LucideIcons.square,
                  isSelected: drawingState.currentTool == ShapeType.square,
                  onTap: () => drawingState.setTool(ShapeType.square),
                ),
                _buildToolButton(
                  context,
                  icon: LucideIcons.rectangleHorizontal,
                  isSelected: drawingState.currentTool == ShapeType.rectangle,
                  onTap: () => drawingState.setTool(ShapeType.rectangle),
                ),
                _buildToolButton(
                  context,
                  icon: LucideIcons.circle,
                  isSelected: drawingState.currentTool == ShapeType.circle,
                  onTap: () => drawingState.setTool(ShapeType.circle),
                ),
                _buildToolButton(
                  context,
                  icon: LucideIcons.orbit,
                  isSelected: drawingState.currentTool == ShapeType.ellipse,
                  onTap: () => drawingState.setTool(ShapeType.ellipse),
                ),
                _buildToolButton(
                  context,
                  icon: LucideIcons.paintBucket,
                  isSelected: drawingState.currentTool == ShapeType.paintBucket,
                  onTap: () => drawingState.setTool(ShapeType.paintBucket),
                ),
                const VerticalDivider(indent: 20, endIndent: 20),
                _buildToolButton(
                  context,
                  icon: LucideIcons.settings2,
                  isSelected: false,
                  onTap: () => _showPropertiesSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPropertiesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            PropertiesPanel(
              onSave: onSave,
              onLoad: onLoad,
              onExport: onExport,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.6),
        size: 24,
      ),
      style: IconButton.styleFrom(
        backgroundColor: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
