import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for exporting canvas as image
class ImageExporter {
  /// Request storage permission on Android
  static Future<bool> _requestStoragePermission() async {
    if (!io.Platform.isAndroid) {
      return true; // No permission needed on other platforms
    }

    try {
      // Check Android version
      final androidVersion = await _getAndroidVersion();
      debugPrint('Android API Level: $androidVersion');

      if (androidVersion >= 33) {
        // Android 13+ (API 33+) - Request READ_MEDIA_IMAGES
        debugPrint('Requesting photos permission for Android 13+');
        final status = await Permission.photos.request();
        debugPrint('Photos permission status: $status');
        return status.isGranted || status.isLimited;
      } else if (androidVersion >= 30) {
        // Android 11-12 (API 30-32) - Try storage permission first
        debugPrint('Requesting storage permission for Android 11-12');
        var status = await Permission.storage.request();
        debugPrint('Storage permission status: $status');

        if (status.isGranted) {
          return true;
        }

        // If denied, try MANAGE_EXTERNAL_STORAGE
        debugPrint('Trying manageExternalStorage permission');
        status = await Permission.manageExternalStorage.request();
        debugPrint('ManageExternalStorage status: $status');

        if (status.isPermanentlyDenied || status.isDenied) {
          // Open app settings if permanently denied
          await openAppSettings();
          return false;
        }

        return status.isGranted;
      } else {
        // Android 10 and below - Request WRITE_EXTERNAL_STORAGE
        debugPrint('Requesting storage permission for Android 10 and below');
        final status = await Permission.storage.request();
        debugPrint('Storage permission status: $status');
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Get Android version (API level)
  static Future<int> _getAndroidVersion() async {
    if (!io.Platform.isAndroid) {
      return 0;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint('Error getting Android version: $e');
      return 30; // Default to 30 if can't determine
    }
  }

  /// Export canvas to PNG or JPEG image
  static Future<bool> exportImage(
    GlobalKey canvasKey, {
    bool asPng = true,
  }) async {
    try {
      // Request permission first on Android
      if (io.Platform.isAndroid) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          debugPrint('Storage permission denied');
          return false;
        }
      }

      // Capture the canvas as image
      final bytes = await _captureCanvas(canvasKey);
      if (bytes == null) {
        debugPrint('Failed to capture canvas');
        return false;
      }

      String outputFile;
      final extension = asPng ? 'png' : 'jpg';

      if (io.Platform.isAndroid) {
        // On Android, save directly to Downloads folder
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          debugPrint('Cannot get external storage directory');
          return false;
        }

        // Navigate to Downloads folder (for Android 10+)
        final downloadsPath = '/storage/emulated/0/Download';
        final downloadsDir = io.Directory(downloadsPath);

        if (await downloadsDir.exists()) {
          final fileName =
              'drawing_${DateTime.now().millisecondsSinceEpoch}.$extension';
          outputFile = '$downloadsPath/$fileName';
          debugPrint('Saving to: $outputFile');
        } else {
          // Fallback to app's external directory
          final fileName =
              'drawing_${DateTime.now().millisecondsSinceEpoch}.$extension';
          outputFile = '${directory.path}/$fileName';
          debugPrint('Saving to app directory: $outputFile');
        }
      } else {
        // On desktop platforms, let user choose save location
        String? path = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Image',
          fileName:
              'drawing_${DateTime.now().millisecondsSinceEpoch}.$extension',
          type: FileType.any,
        );

        if (path == null) {
          // User canceled
          return false;
        }

        outputFile = path;
      }

      // Write to file
      await _writeFile(outputFile, bytes);

      return true;
    } catch (e) {
      debugPrint('Error exporting image: $e');
      return false;
    }
  }

  /// Capture the canvas widget as image bytes
  static Future<Uint8List?> _captureCanvas(GlobalKey canvasKey) async {
    try {
      // Find the RenderRepaintBoundary
      final RenderRepaintBoundary? boundary =
          canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('Could not find RenderRepaintBoundary');
        return null;
      }

      // Capture as image with device pixel ratio for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to bytes (PNG format)
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        debugPrint('Failed to convert image to bytes');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
      return null;
    }
  }

  /// Write bytes to file
  static Future<void> _writeFile(String path, Uint8List bytes) async {
    try {
      final file = io.File(path);
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('Error writing image file: $e');
      rethrow;
    }
  }

  /// Show export dialog to choose format
  static Future<bool?> showExportDialog(
    BuildContext context,
    GlobalKey canvasKey,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Image'),
        content: const Text('Choose image format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await exportImage(canvasKey, asPng: false);
              if (context.mounted) {
                _showResultSnackBar(context, success, 'JPEG');
              }
            },
            icon: const Icon(Icons.image),
            label: const Text('JPEG'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await exportImage(canvasKey, asPng: true);
              if (context.mounted) {
                _showResultSnackBar(context, success, 'PNG');
              }
            },
            icon: const Icon(Icons.image),
            label: const Text('PNG'),
          ),
        ],
      ),
    );
  }

  /// Show result snackbar
  static void _showResultSnackBar(
    BuildContext context,
    bool success,
    String format,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Image exported successfully as $format'
              : 'Failed to export image',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
