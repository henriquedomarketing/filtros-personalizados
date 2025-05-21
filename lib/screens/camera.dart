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

enum CameraMode {
  front,
  back,
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> cameras = [];

  CameraDescription? backCamera;
  CameraDescription? frontCamera;

  CameraController? _backCameraController;
  CameraController? _frontCameraController;

  CameraMode selectedCamera = CameraMode.front;
  VideoPlayerController? _videoPlayerController;

  late Future<void> _initializeControllerFuture;

  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    loadCameras();
  }

  @override
  void dispose() {
    _backCameraController?.dispose();
    _frontCameraController?.dispose();
    _videoPlayerController?.dispose();
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
    final controller = newMode == CameraMode.front ? _frontCameraController : _backCameraController;
    setState(() {
      selectedCamera = newMode;
      if (controller == null) {
        if (newMode == CameraMode.front) {
          _frontCameraController = CameraController(frontCamera!, ResolutionPreset.high);
          _initializeControllerFuture = _frontCameraController!.initialize();
        } else {
          _backCameraController = CameraController(backCamera!, ResolutionPreset.high);
          _initializeControllerFuture = _backCameraController!.initialize();
        }
      }
    });
  }

  CameraController? getCurrentController(CameraMode mode) {
    if (mode == CameraMode.back) {
      return _backCameraController;
    } else {
      return _frontCameraController;
    }
  }

  void onCameraFlip() {
    setSelectedCamera(selectedCamera == CameraMode.front ? CameraMode.back : CameraMode.front);
  }

  Future<void> _takePicture(String assetPath) async {
    try {
      await _initializeControllerFuture;
      final image = await getCurrentController(selectedCamera)!.takePicture();

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
    if (getCurrentController(selectedCamera)!.value.isRecordingVideo) {
      // A recording is already Canceled.
      return;
    }
    try {
      await _initializeControllerFuture;
      await getCurrentController(selectedCamera)!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      print('Video recording started');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!getCurrentController(selectedCamera)!.value.isRecordingVideo) {
      return;
    }
    try {
      final file = await getCurrentController(selectedCamera)!.stopVideoRecording();
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

  void onLeftAction() async {
    // Fire up gallery app on device
    // if (await Permission.manageExternalStorage.request().isGranted) {
    OpenFile.open("/storage/emulated/0/DCIM/Camera");
    // }
    // Action for left button - TBD: Open gallery
    print("Gallery button pressed");
  }

  Widget buildBottomControl(BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 0, // Added to align to the left
      right: 0, // Added to align to the right
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: onLeftAction,
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
                backgroundColor: _isRecording ? Colors.red : Colors.indigo,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.camera_alt,
                  size: 40,
                  color: _isRecording ? Colors.black87 : Colors.white,
                ), // Optionally increase icon size
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

  Widget buildFilterSelector(BuildContext context) {
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
                  backgroundColor: Colors.indigo.withOpacity(0.9),
                  // Example item color
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero, // Remove default padding
                ).copyWith(
                  fixedSize: MaterialStateProperty.all(const Size(60, 60)),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FilterModel(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          FutureBuilder(
            key: ValueKey(selectedCamera),
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              final selectedController = getCurrentController(selectedCamera);
              if (selectedController == null ||
                  snapshot.connectionState != ConnectionState.done) {
                print("loading because _controller null ? ${selectedController == null} >> snapshot.connectionState? ${snapshot.connectionState}");
                return const Center(child: CircularProgressIndicator());
              }
              // Use a ValueKey with the selected camera's name to ensure CameraOverlay rebuilds when the camera changes.
              // This is crucial for updating the CameraPreview within CameraOverlay.
              return CameraOverlay(
                key: ValueKey(selectedCamera),
                cameraController: selectedController,
              );
            },
          ),
          buildBottomControl(context),
          buildFilterSelector(context),
        ],
      ),
    );
  }
}
