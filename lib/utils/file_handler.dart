import 'dart:io' as io;
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/shape.dart';

/// Utility class for saving and loading drawing projects
class FileHandler {
  // Magic number for file format identification: "MD" (MyDraw)
  static const int _magicNumber1 = 0x4D; // 'M'
  static const int _magicNumber2 = 0x44; // 'D'
  static const int _version = 1;

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

  /// Save project to a .mydraw file
  static Future<bool> saveProject(List<Shape> shapes) async {
    try {
      // Request permission first on Android
      if (io.Platform.isAndroid) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          debugPrint('Storage permission denied');
          return false;
        }
      }

      // Serialize shapes to binary
      final bytes = _serializeShapes(shapes);

      String outputFile;

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
              'drawing_${DateTime.now().millisecondsSinceEpoch}.mydraw';
          outputFile = '$downloadsPath/$fileName';
          debugPrint('Saving to: $outputFile');
        } else {
          // Fallback to app's external directory
          final fileName =
              'drawing_${DateTime.now().millisecondsSinceEpoch}.mydraw';
          outputFile = '${directory.path}/$fileName';
          debugPrint('Saving to app directory: $outputFile');
        }
      } else {
        // On desktop platforms, let user choose save location
        String? path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Drawing Project',
          fileName: 'drawing_${DateTime.now().millisecondsSinceEpoch}.mydraw',
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
      debugPrint('Error saving project: $e');
      return false;
    }
  }

  /// Load project from a .mydraw file
  static Future<List<Shape>?> loadProject() async {
    try {
      // Request permission first on Android
      if (io.Platform.isAndroid) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          debugPrint('Storage permission denied');
          return null;
        }
      }

      // Let user choose file to open
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Open Drawing Project',
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        // User canceled
        return null;
      }

      Uint8List? bytes;

      // Try to get bytes directly (works on web and some platforms)
      if (result.files.first.bytes != null) {
        bytes = result.files.first.bytes;
      } else if (result.files.first.path != null) {
        // Read from file path (desktop/mobile)
        final file = io.File(result.files.first.path!);
        bytes = await file.readAsBytes();
      }

      if (bytes == null) {
        debugPrint('Cannot read file: no bytes or path available');
        return null;
      }

      // Deserialize shapes from binary
      return _deserializeShapes(bytes);
    } catch (e) {
      debugPrint('Error loading project: $e');
      return null;
    }
  }

  /// Serialize shapes to binary format
  static Uint8List _serializeShapes(List<Shape> shapes) {
    // Calculate total size
    // Header: 2 bytes magic + 2 bytes version + 4 bytes count = 8 bytes
    // Each shape: 45 bytes (from shape.dart toBytes())
    final headerSize = 8;
    final shapeSize = 45;
    final totalSize = headerSize + (shapes.length * shapeSize);

    final byteData = ByteData(totalSize);
    var offset = 0;

    // Write header
    byteData.setUint8(offset++, _magicNumber1);
    byteData.setUint8(offset++, _magicNumber2);
    byteData.setUint16(offset, _version);
    offset += 2;
    byteData.setUint32(offset, shapes.length);
    offset += 4;

    // Write each shape
    for (final shape in shapes) {
      final shapeBytes = shape.toBytes();
      for (int i = 0; i < shapeBytes.length; i++) {
        byteData.setUint8(offset++, shapeBytes[i]);
      }
    }

    return byteData.buffer.asUint8List();
  }

  /// Deserialize shapes from binary format
  static List<Shape>? _deserializeShapes(Uint8List bytes) {
    try {
      final byteData = ByteData.sublistView(bytes);
      var offset = 0;

      // Read and verify header
      final magic1 = byteData.getUint8(offset++);
      final magic2 = byteData.getUint8(offset++);
      if (magic1 != _magicNumber1 || magic2 != _magicNumber2) {
        debugPrint('Invalid file format: magic numbers do not match');
        return null;
      }

      final version = byteData.getUint16(offset);
      offset += 2;
      if (version != _version) {
        debugPrint('Unsupported file version: $version');
        return null;
      }

      final count = byteData.getUint32(offset);
      offset += 4;

      // Read shapes
      final shapes = <Shape>[];
      for (int i = 0; i < count; i++) {
        final shape = Shape.fromBytes(bytes, offset);
        if (shape != null) {
          shapes.add(shape);
          offset += 45; // Each shape is 45 bytes
        } else {
          debugPrint('Failed to deserialize shape at index $i');
        }
      }

      return shapes;
    } catch (e) {
      debugPrint('Error deserializing shapes: $e');
      return null;
    }
  }

  /// Write bytes to file
  static Future<void> _writeFile(String path, Uint8List bytes) async {
    try {
      final file = io.File(path);
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('Error writing file: $e');
      rethrow;
    }
  }
}
