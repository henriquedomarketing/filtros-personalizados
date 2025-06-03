import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class Utils {
  static Future<bool> copyFileToSaveDirectory(String path) async {
    final directory = await Utils.getSaveDirectory();
    final fileName = path
        .split('/')
        .last;
    final newPath = '${directory!.path}$fileName';
    try {
      await File(path).copy(newPath);
      print('File copied to: $newPath');
      return true;
    } catch (e) {
      print('Error copying file: $e');
      return false;
    }
  }

  // Get the directory to save the images
  static Future<Directory?> getSaveDirectory() async {
    final dirPath = "/storage/emulated/0/Download/cameramarketing";
    PermissionStatus status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    await Directory(dirPath).create(recursive: true);
    return Directory(dirPath);
  }
}