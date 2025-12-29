import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/shape.dart';
import '../providers/drawing_state.dart';

/// Desktop toolbar (floating vertical sidebar)
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildToolButton(
                context,
                icon: LucideIcons.mousePointer2,
                label: 'Select',
                isSelected: drawingState.currentTool == ShapeType.select,
                onTap: () => drawingState.setTool(ShapeType.select),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(height: 20),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildToolButton(
                      context,
                      icon: LucideIcons.pencil,
                      label: 'Pencil',
                      isSelected: drawingState.currentTool == ShapeType.pencil,
                      onTap: () => drawingState.setTool(ShapeType.pencil),
                    ),
                    _buildToolButton(
                      context,
                      icon: LucideIcons.dot,
                      label: 'Point',
                      isSelected: drawingState.currentTool == ShapeType.point,
                      onTap: () => drawingState.setTool(ShapeType.point),
                    ),
                    _buildToolButton(
                      context,
                      icon: LucideIcons.minus,
                      label: 'Line',
                      isSelected: drawingState.currentTool == ShapeType.line,
                      onTap: () => drawingState.setTool(ShapeType.line),
                    ),
                    _buildToolButton(
                      context,
                      icon: LucideIcons.square,
                      label: 'Square',
                      isSelected: drawingState.currentTool == ShapeType.square,
                      onTap: () => drawingState.setTool(ShapeType.square),
                    ),
                    _buildToolButton(
                      context,
                      icon: LucideIcons.rectangleHorizontal,
                      label: 'Rectangle',
                      isSelected:
                          drawingState.currentTool == ShapeType.rectangle,
                      onTap: () => drawingState.setTool(ShapeType.rectangle),
                    ),
                    _buildToolButton(
                      context,
                      icon: LucideIcons.circle,
                      label: 'Circle',
                      isSelected: drawingState.currentTool == ShapeType.circle,
                      onTap: () => drawingState.setTool(ShapeType.circle),
                    ),
                    _buildToolButton(
                      context,
                      icon: LucideIcons
                          .orbit, // Changed from circleDashed to orbit for Ellipse
                      label: 'Ellipse',
                      isSelected: drawingState.currentTool == ShapeType.ellipse,
                      onTap: () => drawingState.setTool(ShapeType.ellipse),
                    ),
                    _buildToolButton(
                      context,
                      icon: LucideIcons.paintBucket,
                      label: 'Fill',
                      isSelected:
                          drawingState.currentTool == ShapeType.paintBucket,
                      onTap: () => drawingState.setTool(ShapeType.paintBucket),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(height: 20),
              ),
              _buildToolButton(
                context,
                icon: LucideIcons.trash2,
                label: 'Clear',
                isSelected: false,
                onTap: onClear,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
            ],
          ),
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
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? (color ?? theme.colorScheme.primary).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? (color ?? theme.colorScheme.primary)
                  : (color ?? theme.colorScheme.onSurface.withOpacity(0.6)),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
