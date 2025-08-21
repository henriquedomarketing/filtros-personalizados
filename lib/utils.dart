import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class Utils {
  static Future<bool> copyFileToSaveDirectory(String path) async {
    final directory = await Utils.getSaveDirectory();
    final fileName = path.split('/').last;
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

  // Save image to gallery (works on both iOS and Android)
  static Future<bool> saveImageToGallery(String imagePath) async {
    try {
      if (Platform.isIOS) {
        // For iOS, save directly to photo gallery
        final result = await ImageGallerySaverPlus.saveFile(imagePath);
        print('Image saved to gallery: $result');
        return result['isSuccess'] == true;
      } else {
        // For Android, use the existing method
        return await copyFileToSaveDirectory(imagePath);
      }
    } catch (e) {
      print('Error saving image to gallery: $e');
      return false;
    }
  }

  // Get the directory to save the images
  static Future<Directory?> getSaveDirectory() async {
    if (Platform.isAndroid) {
      // Android: Use external storage
      final dirPath = "/storage/emulated/0/Download/cameramarketing";
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      await Directory(dirPath).create(recursive: true);
      return Directory(dirPath);
    } else if (Platform.isIOS) {
      // iOS: Use documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${documentsDir.path}/cameramarketing');
      await saveDir.create(recursive: true);
      return saveDir;
    }
    return null;
  }
}
