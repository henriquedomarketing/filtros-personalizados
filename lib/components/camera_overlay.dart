import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CameraOverlay extends StatefulWidget {
  final CameraDescription camera;

  const CameraOverlay({super.key, required this.camera});

  @override
  _CameraOverlayState createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      final originalImage = img.decodeImage(File(image.path).readAsBytesSync());
      if (originalImage == null) return;

      final overlayImageBytes = await DefaultAssetBundle.of(context).load('assets/overlay.png');
      final overlayImage = img.decodeImage(overlayImageBytes.buffer.asUint8List());
      if (overlayImage == null) return;

      // Resize overlay to match camera image resolution
      final resizedOverlay = img.copyResize(overlayImage,
          width: originalImage.width, height: originalImage.height);

      // Composite the images
      final compositeImage = img.compositeImage(originalImage, resizedOverlay);

      // Save the composite image
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/composite_image.png';
      final newFile = File(filePath);
      newFile.writeAsBytesSync(img.encodePng(compositeImage));

      print('Composite image saved to: $filePath');

      if (mounted) {
      // Now you can use the filePath to display or share the image
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Image.file(File(filePath)),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close'))],
            );
          },
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              CameraPreview(_controller),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    'assets/overlay.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: MediaQuery.of(context).size.width / 2 - 30,
                child: FloatingActionButton(
                  onPressed: _takePicture,
                  child: Icon(Icons.camera),
                ),
              ),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
