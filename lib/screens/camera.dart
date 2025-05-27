import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_marketing_app/components/camera_overlay.dart';
import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';

enum CameraMode { front, back }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> cameras = [];

  CameraDescription? backCamera;
  CameraDescription? frontCamera;

  CameraMode selectedCamera = CameraMode.front;

  bool _isProcessingCapture = false;

  Future<CameraController>? _currentCameraFuture;

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
    print("[loadCameras] cameras");
    print(localCameras);
    setState(() {
      cameras = localCameras;
      frontCamera = localCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      backCamera = localCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      setSelectedCamera(
        backCamera != null ? CameraMode.back : CameraMode.front,
      );
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
      if (cameraDescription != null) {
        _currentCameraFuture = loadController(cameraDescription);
      }
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

  void onPreviewShare(String filePath) {
    SharePlus.instance.share(ShareParams(
      text: "Confira!",
      files: [XFile(filePath)],
    ));
  }

  void onPreviewSave(String filePath) async {
    final success = await copyFileToSaveDirectory(filePath);
    if (success) {
      openFileManager(
        androidConfig: AndroidConfig(
          folderType: AndroidFolderType.other,
          folderPath: (await getSaveDirectory())!.path,
        ),
        iosConfig: IosConfig(folderPath: (await getSaveDirectory())!.path),
      );
    }
  }

  Future<void> onUploadImage(BuildContext context) async {
    if (getSelectedFilter() == null || getSelectedFilter()?.url == "") {
      showNoFilterMessage();
      return;
    }
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // You can now use the image file path
      print('Image selected: ${image.path}');
      final processedImagePath = await _processImage(
        image.path,
        getSelectedFilter()!.url,
      );
      showImagePreview(processedImagePath!);
    }
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
              SizedBox(width: 15),
              TextButton(
                onPressed: () => onPreviewSave(filePath),
                child: Text('SALVAR'),
              ),
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () => onPreviewShare(filePath),
              ),
            ],
          );
        },
      );
    }
  }

  void showVideoPreview(String filePath) {
    Future<VideoPlayerController> loadVideo() async {
      VideoPlayerController videoPlayerController = VideoPlayerController.file(
        File(filePath),
      );
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
              VideoPlayerController? controller =
              snapshot.connectionState == ConnectionState.done
                  ? snapshot.data
                  : null;
              if (snapshot.connectionState == ConnectionState.done &&
                  controller != null) {
                content = RotatedBox(
                  quarterTurns: 1, // Rotate 90 degrees clockwise
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    // Invert aspect ratio for portrait
                    child: VideoPlayer(controller),
                  ),
                );
              }
              return AlertDialog(
                content: content,
                actions: <Widget>[
                  IconButton(
                    onPressed: () {
                      controller?.play();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    icon: Icon(
                      Icons.play_circle_fill,
                      color: controller != null ? null : Colors.grey,
                    ),
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

  Future<String?> _processImage(String imagePath, String filterImageUrl) async {
    final originalImage = img.decodeImage(File(imagePath).readAsBytesSync());
    if (originalImage == null) return null;

    // Download the image from the URL
    final response = await http.get(Uri.parse(filterImageUrl));
    if (response.statusCode != 200) {
      print('Failed to download image: ${response.statusCode}');
      return null;
    }
    final overlayImageBytes = response.bodyBytes;
    // final overlayImageBytes = await DefaultAssetBundle.of(
    //   context,
    // ).load(filterImageUrl);
    final overlayImage = img.decodeImage(
      overlayImageBytes.buffer.asUint8List(),
    );
    if (overlayImage == null) return null;

    // Resize overlay to match camera image resolution
    final resizedOverlay = img.copyResize(
      overlayImage,
      width: originalImage.width,
      height: originalImage.height,
    );

    // Composite the images
    final compositeImage = img.compositeImage(originalImage, resizedOverlay);

    // Save the composite image
    final directory = await getSaveDirectory();
    if (directory == null) {
      return null;
    }
    final timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    final filePath = '${directory.path}/composite_image_$timestamp.png';
    final _newFile = File(filePath)
      ..writeAsBytesSync(img.encodePng(compositeImage));
    print(_newFile);
    return filePath;
  }

  Future<void> _takePicture(String filterPath,
      CameraController controller,) async {
    try {
      setState(() {
        _isProcessingCapture = true;
      });
      controller.setFlashMode(FlashMode.off);
      controller.setExposureMode(ExposureMode.auto);
      final image = await controller.takePicture();
      // controller.pausePreview();
      final processedImagePath = await _processImage(image.path, filterPath);

      if (processedImagePath != null) {
        print('Processed image saved to: $processedImagePath');
        showImagePreview(processedImagePath);
      }
    } catch (e) {
      print(e);
    } finally {
      // controller.resumePreview();
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
      await controller.prepareForVideoRecording();
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
    if (getSelectedFilter() == null) {
      showNoFilterMessage();
      return;
    }
    if (_isRecording) {
      _stopVideoRecording(controller);
    } else {
      _takePicture(getSelectedFilter()!.url, controller);
    }
  }

  void onLeftAction() async {
    final docsDir = await getSaveDirectory();
    // if (await Permission.storage.request().isGranted) {
    openFileManager(
      androidConfig: AndroidConfig(
        folderType: AndroidFolderType.other,
        folderPath: docsDir!.path,
      ),
      iosConfig: IosConfig(folderPath: docsDir.path),
    );
    // }
  }

  FilterModel? getSelectedFilter() {
    return Provider.of<AuthProvider>(context, listen: false).selectedFilter;
  }

  void onClearFilter() {
    Provider.of<AuthProvider>(context, listen: false).clearSelectedFilter();
  }

  void onFilterPressed(int index, FilterModel filter) {
    Provider.of<AuthProvider>(context, listen: false).setSelectedFilter(filter);
  }

  void showNoFilterMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Nenhum filtro selecionado"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget buildCaptureIcon(BuildContext context) {
    if (_isProcessingCapture)
      return CircularProgressIndicator(color: Colors.white);
    if (_isRecording) return Icon(Icons.stop, size: 40, color: Colors.black87);
    return Icon(Icons.camera_alt, size: 40, color: Colors.white);
  }

  Widget buildBottomControl(BuildContext context,
      CameraController? controller,) {
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
                child: buildCaptureIcon(context),
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: () => onUploadImage(context),
            mini: true,
            child: const Icon(Icons.add_photo_alternate),
          ),
        ],
      ),
    );
  }

  Widget buildFilterSelector(BuildContext context,
      CameraController? controller,) {
    var textStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );
    var buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo.withValues(alpha: 0.9),
      // Example item color
      shape: const CircleBorder(),
      padding: EdgeInsets.zero, // Remove default padding
    ).copyWith(fixedSize: WidgetStateProperty.all(const Size(60, 60)));
    return Positioned(
      right: 0, // Adjust left position as needed
      child: SizedBox(
        height:
        MediaQuery
            .of(context)
            .size
            .height * 0.5, // 50% of screen height
        width: 70, // Adjust width as needed
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ListView.builder(
              itemCount: authProvider.loggedUser!.filters.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () => onClearFilter(),
                      style: buttonStyle,
                      child: Text('X', style: textStyle),
                    ),
                  );
                }
                final FilterModel? filter = authProvider.loggedUser?.filters[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () => onFilterPressed(index - 1, filter!),
                    style: buttonStyle,
                    child: Text('${index}', style: textStyle),
                  ),
                );
              },
            );
          },
        )
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Center(
        child: FutureBuilder<CameraController>(
          future: _currentCameraFuture, // Use the nullable Future
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton(
                    onPressed: onCameraFlip,
                    mini: true,
                    backgroundColor: hasBothCameras() ? null : Colors.grey,
                    child: const Icon(Icons.cameraswitch_sharp),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: null,
      drawer: null,
      bottomNavigationBar: null,
    );
  }

  Future<bool> copyFileToSaveDirectory(String path) async {
    final directory = await getSaveDirectory();
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
  Future<Directory?> getSaveDirectory() async {
    final dirPath = "/storage/emulated/0/Download/cameramarketing";
    PermissionStatus status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    await Directory(dirPath).create(recursive: true);
    return Directory(dirPath);
  }
}
