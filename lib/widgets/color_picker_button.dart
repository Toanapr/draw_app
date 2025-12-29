import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Color picker button widget
class ColorPickerButton extends StatelessWidget {
  final Color currentColor;
  final String label;
  final ValueChanged<Color> onColorChanged;
  final bool isCompact;

  const ColorPickerButton({
    super.key,
    required this.currentColor,
    required this.label,
    required this.onColorChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactButton(context);
    } else {
      return _buildFullButton(context);
    }
  }

  Widget _buildFullButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _showColorPicker(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 2,
              ),
            ),
            child: currentColor.alpha == 0
                ? const Icon(Icons.block, color: Colors.red)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactButton(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => _showColorPicker(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor, width: 2),
          ),
          child: currentColor.alpha == 0
              ? const Icon(Icons.block, color: Colors.red, size: 20)
              : null,
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    Color tempColor = currentColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(label),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: currentColor,
                  onColorChanged: (color) {
                    tempColor = color;
                  },
                  pickerAreaHeightPercent: 0.8,
                  enableAlpha: true,
                  displayThumbColor: true,
                  labelTypes: const [],
                ),
                const SizedBox(height: 16),
                // Add a "No Fill" button for fill color
                if (label.toLowerCase().contains('fill'))
                  ElevatedButton.icon(
                    onPressed: () {
                      tempColor = Colors.transparent;
                      Navigator.of(context).pop();
                      onColorChanged(tempColor);
                    },
                    icon: const Icon(Icons.block),
                    label: const Text('No Fill'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onColorChanged(tempColor);
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }
}
