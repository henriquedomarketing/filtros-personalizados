import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_marketing_app/components/camera_overlay.dart';
import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

enum CameraMode { front, back }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> cameras = [];

  late FilterModel filterModel = FilterModel();

  CameraDescription? backCamera;
  CameraDescription? frontCamera;

  CameraMode selectedCamera = CameraMode.front;
  // VideoPlayerController? _videoPlayerController;

  bool _isProcessingCapture = false;

  late Future<CameraController> _currentCameraFuture;

  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    loadCameras();
  }

  @override
  void dispose() {
    // _backCameraController?.dispose();
    // _frontCameraController?.dispose();
    // _videoPlayerController?.dispose();
    super.dispose();
  }

  void loadCameras() async {
    List<CameraDescription> localCameras = await availableCameras();
    setState(() {
      cameras = localCameras;
      frontCamera = localCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      backCamera = localCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      setSelectedCamera(CameraMode.back);
    });
  }

  bool hasBothCameras() {
    return backCamera != null && frontCamera != null;
  }

  void setSelectedCamera(CameraMode newMode) {
    final cameraDescription =
        newMode == CameraMode.front ? frontCamera : backCamera;
    setState(() {
      selectedCamera = newMode;
      _currentCameraFuture = loadController(cameraDescription!);
    });
  }

  Future<CameraController> loadController(CameraDescription camera) async {
    final controller = CameraController(camera, ResolutionPreset.high);
    await controller.initialize();
    return controller;
  }

  void onCameraFlip() {
    setSelectedCamera(
      selectedCamera == CameraMode.front ? CameraMode.back : CameraMode.front,
    );
  }

  void showImagePreview(String filePath) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Image.file(File(filePath)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fechar'),
              ),
            ],
          );
        },
      );
    }
  }

  void showVideoPreview(String filePath) {
    Future<VideoPlayerController> loadVideo() async {
      VideoPlayerController videoPlayerController = VideoPlayerController.file(File(filePath));
      videoPlayerController.initialize();
      return videoPlayerController;
    }
    final loadVideoFuture = loadVideo();
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return FutureBuilder<VideoPlayerController>(
            future: loadVideoFuture,
            builder: (context, snapshot) {
              // Decide content
              Widget content = const Center(child: CircularProgressIndicator());
              VideoPlayerController? controller = snapshot.connectionState == ConnectionState.done ? snapshot.data : null;
              if (snapshot.connectionState == ConnectionState.done && controller != null) {
                content = AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                );
              }
              return AlertDialog(
                content: content,
                actions: <Widget>[
                  IconButton(
                    onPressed: () {
                      controller?.play();
                    },
                    style: IconButton.styleFrom(backgroundColor: Colors.transparent),
                    icon: Icon(Icons.play_circle_fill, color: controller != null ? null : Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      controller?.pause();
                      controller?.dispose();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Fechar'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _takePicture(
    String assetPath,
    CameraController controller,
  ) async {
    try {
      setState(() {
        _isProcessingCapture = true;
      });
      final image = await controller.takePicture();

      if (assetPath == "") {
        showImagePreview(image.path);
        return;
      }

      final originalImage = img.decodeImage(File(image.path).readAsBytesSync());
      if (originalImage == null) return;

      final overlayImageBytes = await DefaultAssetBundle.of(context).load(assetPath);
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
      showImagePreview(filePath);

    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isProcessingCapture = false;
      });
    }
  }

  Future<void> _startVideoRecording(CameraController controller) async {
    if (controller.value.isRecordingVideo) {
      return;
    }
    try {
      await controller.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      print('Video recording started');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopVideoRecording(CameraController controller) async {
    if (!controller.value.isRecordingVideo) {
      return;
    }
    try {
      setState(() {
        _isProcessingCapture = true;
      });
      final file = await controller.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      print('Video recorded to ${file.path}');
      showVideoPreview(file.path);
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isProcessingCapture = false;
      });
    }
  }

  void _onTapCapture(CameraController controller) {
    if (_isRecording) {
      _stopVideoRecording(controller);
    } else {
      _takePicture(filterModel.filterAssetPath, controller);
    }
  }

  void onLeftAction() async {
    // Fire up gallery app on device
    // if (await Permission.manageExternalStorage.request().isGranted) {
    OpenFile.open("/storage/emulated/0/DCIM/Camera");
    // }
    // Action for left button - TBD: Open gallery
    print("Gallery button pressed");
  }

  Widget captureIcon(BuildContext context) {
    if (_isRecording) return Icon(Icons.stop, size: 40, color: Colors.red);
    if (_isProcessingCapture) return CircularProgressIndicator();
    return Icon(Icons.camera_alt, size: 40, color: Colors.white);
  }

  Widget buildBottomControl(
    BuildContext context,
    CameraController? controller,
  ) {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: onLeftAction,
            mini: true,
            child: const Icon(Icons.image),
          ),
          GestureDetector(
            onTap: () => _onTapCapture(controller!),
            onLongPress: () => _startVideoRecording(controller!),
            onLongPressUp: () => _stopVideoRecording(controller!),
            child: SizedBox(
              width: 80.0, // Center button width
              height: 80.0, // Center button height
              child: FloatingActionButton(
                onPressed: null, // onTap and onLongPress handle actions
                backgroundColor: _isRecording ? Colors.red : Colors.indigo,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.camera_alt,
                  size: 40,
                  color: _isRecording ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: onCameraFlip,
            mini: true,
            backgroundColor: hasBothCameras() ? null : Colors.grey,
            child: const Icon(Icons.cameraswitch_sharp),
          ),
        ],
      ),
    );
  }

  Widget buildFilterSelector(
    BuildContext context,
    CameraController? controller,
  ) {
    return Positioned(
      right: 0, // Adjust left position as needed
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height * 0.5, // 50% of screen height
        width: 70, // Adjust width as needed
        child: ListView.builder(
          itemCount: 5, // Initially 5 elements
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              // Add some spacing between buttons
              child: ElevatedButton(
                onPressed: () {
                  // Action for when the button is pressed
                  print('Item ${index + 1} pressed');
                  var filter = context.read<FilterModel>();
                  filter.changeFilter('assets/overlay${index + 1}.png');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.withValues(alpha: 0.9),
                  // Example item color
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero, // Remove default padding
                ).copyWith(
                  fixedSize: WidgetStateProperty.all(const Size(60, 60)),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget buildCameraOverlay(BuildContext context) {
  //   final selectedController = getCurrentController(selectedCamera);
  //   if (selectedController == null || !selectedController.value.isInitialized) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //   if (selectedCamera == CameraMode.back) {
  //     return CameraOverlay(
  //       cameraController: _backCameraController,
  //     );
  //   } else {
  //     return CameraOverlay(
  //       cameraController: _frontCameraController,
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => filterModel,
      child: FutureBuilder<CameraController>(
        future: _currentCameraFuture,
        builder: (context, snapshot) {
          Widget cameraPreview = const Center(
            child: CircularProgressIndicator(),
          );
          if (snapshot.connectionState == ConnectionState.done) {
            cameraPreview = CameraOverlay(
              key: ValueKey(selectedCamera),
              cameraController: snapshot.data,
            );
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              cameraPreview,
              buildBottomControl(context, snapshot.data),
              buildFilterSelector(context, snapshot.data),
            ],
          );
        },
      ),
    );
  }
}
