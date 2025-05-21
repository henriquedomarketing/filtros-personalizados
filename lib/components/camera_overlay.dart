import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:open_file/open_file.dart';
// import 'package:permission_handler/permission_handler.dart';

class CameraOverlay extends StatefulWidget {
  final CameraDescription camera;

  const CameraOverlay({super.key, required this.camera});

  @override
  _CameraOverlayState createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay> {
  late CameraController _controller;
  VideoPlayerController? _videoPlayerController;

  late Future<void> _initializeControllerFuture;

  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture(String assetPath) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      final originalImage = img.decodeImage(File(image.path).readAsBytesSync());
      if (originalImage == null) return;

      final overlayImageBytes = await DefaultAssetBundle.of(
        context,
      ).load(assetPath);
      final overlayImage = img.decodeImage(
        overlayImageBytes.buffer.asUint8List(),
      );
      if (overlayImage == null) return;

      // Resize overlay to match camera image resolution
      final resizedOverlay = img.copyResize(
        overlayImage,
        width: originalImage.width,
        height: originalImage.height,
      );

      // Composite the images
      final compositeImage = img.compositeImage(originalImage, resizedOverlay);

      // Save the composite image
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/composite_image_$timestamp.png';
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller.value.isRecordingVideo) {
      // A recording is already Canceled.
      return;
    }
    try {
      await _initializeControllerFuture;
      await _controller.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      print('Video recording started');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return;
    }
    try {
      final file = await _controller.stopVideoRecording();
      setState(() {
        _videoPlayerController = VideoPlayerController.file(File(file.path))
          ..initialize().then((_) {
            _videoPlayerController?.play();
            setState(() {});
          });
        _isRecording = false;
      });
      print('Video recorded to ${file.path}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            if (_videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized) {
              return AlertDialog(
                content: AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      _videoPlayerController?.pause();
                      _videoPlayerController?.dispose();
                      _videoPlayerController = null;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ],
              );
            }
            return AlertDialog(
              content: Text("Video saved to ${file.path}"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print(e);
    }
  }

  void _onTapCapture() {
    final selectedFilter = Provider.of<FilterModel>(context, listen: false);
    if (_isRecording) {
      _stopVideoRecording();
    } else {
      _takePicture(selectedFilter.filterAssetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: AspectRatio(
                  aspectRatio: 1080 / 1920,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: SizedBox(
                      width: _controller.value.previewSize?.height ?? 1080,
                      // Swap width and height for portrait
                      height: _controller.value.previewSize?.width ?? 1920,
                      // Swap width and height for portrait
                      child: Stack(
                        children: [
                          CameraPreview(
                            _controller,
                            child: Positioned.fill(
                              child: CustomPaint(painter: ThirdsGridPainter()),
                            ),
                          ),

                          // Rule of thirds grid
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: ThirdsGridPainter())),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.5,
                  child: Consumer<FilterModel>(
                    builder: (context, filter, child) {
                      if (filter.filterAssetPath == "") {
                        return Container();
                      }
                      return Image.asset(filter.filterAssetPath, fit: BoxFit.contain);
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 0, // Added to align to the left
                right: 0, // Added to align to the right
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      onPressed: () async {
                        // Fire up gallery app on device
                        // if (await Permission.manageExternalStorage.request().isGranted) {
                        OpenFile.open("/storage/emulated/0/DCIM/Camera");
                        // }
                        // Action for left button - TBD: Open gallery
                        print("Gallery button pressed");
                      },
                      mini: true,
                      child: const Icon(Icons.image),
                    ),
                    GestureDetector(
                      onTap: _onTapCapture,
                      onLongPress: _startVideoRecording,
                      onLongPressUp: _stopVideoRecording,
                      child: SizedBox(
                        width: 80.0, // Center button width
                        height: 80.0, // Center button height
                        child: FloatingActionButton(
                          onPressed: null,
                          // onTap and onLongPress handle actions
                          backgroundColor:
                              _isRecording ? Colors.red : Colors.indigo,
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.camera_alt,
                            size: 40,
                            color: _isRecording ? Colors.black87 : Colors.white,
                          ), // Optionally increase icon size
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        // Action for right button
                        print("Right button pressed");
                      },
                      mini: true,
                      child: const Icon(Icons.add_a_photo),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class ThirdsGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..strokeWidth = 1;

    // Draw vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );

    // Draw horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
