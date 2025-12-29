import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/drawing_state.dart';

class PropertiesPanel extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onExport;
  final double? width;

  const PropertiesPanel({
    super.key,
    required this.onSave,
    required this.onLoad,
    required this.onExport,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final drawingState = context.watch<DrawingState>();
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width ?? 260,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Stroke Width'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                        ),
                        child: Slider(
                          value: drawingState.strokeWidth,
                          min: 1,
                          max: 20,
                          onChanged: (value) =>
                              drawingState.setStrokeWidth(value),
                        ),
                      ),
                    ),
                    Text(
                      drawingState.strokeWidth.toStringAsFixed(0),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Stroke Color'),
                const SizedBox(height: 12),
                _buildColorGrid(
                  context,
                  selectedColor: drawingState.strokeColor,
                  onColorSelected: (color) =>
                      drawingState.setStrokeColor(color),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Fill Color'),
                const SizedBox(height: 12),
                _buildColorGrid(
                  context,
                  selectedColor: drawingState.fillColor,
                  onColorSelected: (color) => drawingState.setFillColor(color),
                  allowTransparent: true,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Canvas Settings'),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: drawingState.showGrid,
                  onChanged: (_) => drawingState.toggleGrid(),
                  title: const Text('Show Grid'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  icon: LucideIcons.save,
                  label: 'Save Project',
                  onPressed: onSave,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  icon: LucideIcons.download,
                  label: 'Export Image',
                  onPressed: onExport,
                  isSecondary: true,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  icon: LucideIcons.folderOpen,
                  label: 'Open Project',
                  onPressed: onLoad,
                  isSecondary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildColorGrid(
    BuildContext context, {
    required Color selectedColor,
    required Function(Color) onColorSelected,
    bool allowTransparent = false,
  }) {
    final List<Color> colors = [
      if (allowTransparent) Colors.transparent,
      Colors.black,
      Colors.white,
      const Color(0xFFEF4444), // Red 500
      const Color(0xFFF97316), // Orange 500
      const Color(0xFFF59E0B), // Amber 500
      const Color(0xFF10B981), // Emerald 500
      const Color(0xFF3B82F6), // Blue 500
      const Color(0xFF6366F1), // Indigo 500
      const Color(0xFF8B5CF6), // Violet 500
      const Color(0xFFD946EF), // Fuchsia 500
      const Color(0xFF64748B), // Slate 500
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = selectedColor == color;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color == Colors.transparent ? null : color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: color == Colors.transparent
                ? Stack(
                    children: [
                      if (!isSelected)
                        const Center(
                          child: Icon(
                            LucideIcons.ban,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (isSelected)
                        Center(
                          child: Icon(
                            LucideIcons.check,
                            size: 16,
                            color: _getContrastColor(color),
                          ),
                        ),
                    ],
                  )
                : isSelected
                ? Icon(
                    LucideIcons.check,
                    size: 16,
                    color: _getContrastColor(color),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _getContrastColor(Color color) {
    if (color == Colors.transparent) return Colors.black;
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? theme.colorScheme.surface
              : theme.colorScheme.primary,
          foregroundColor: isSecondary
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSecondary
                ? BorderSide(color: theme.dividerColor.withOpacity(0.1))
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
