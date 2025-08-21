import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_marketing_app/components/camera_overlay.dart';
import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:camera_marketing_app/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../components/video_preview.dart';
import '../providers/auth_provider.dart';
import '../utils.dart';

enum CameraMode { front, back }

class CameraScreen extends StatefulWidget {
  final String categoryName;
  const CameraScreen({super.key, required this.categoryName});

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
  bool _isLoadingUpload = false;
  bool _isLoading = false;
  bool _isRecording = false;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  List<CameraController> _toDispose = [];

  @override
  void initState() {
    super.initState();
    loadCameras();
  }

  @override
  void dispose() {
    // Ensure the current controller is disposed if it exists
    print("[CAMERA WIDGET] CALLING DISPOSE!!");
    _currentCameraFuture?.then((controller) {
      controller.dispose();
    });
    // Dispose all other controllers that were added to the list
    // This handles the case where controllers are swapped rapidly
    for (final controller in _toDispose) controller.dispose();
    super.dispose();
  }

  void loadCameras() async {
    setState(()=>_isLoading=true);
    List<CameraDescription> localCameras = await availableCameras();

    print("[loadCameras] cameras");
    print(localCameras);
    setState(() {
      cameras = localCameras;
      if(cameras.isNotEmpty){
        frontCamera = localCameras.firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.front,
              );
        backCamera = localCameras.firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.back,
              );
        setSelectedCamera(
                backCamera != null ? CameraMode.back : CameraMode.front,
              );
      }
     _isLoading=false;
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
        // After initializing, if this controller is not the one currently
        // assigned to _currentCameraFuture (due to rapid changes),
        // it should be disposed.
        _currentCameraFuture?.then((lastController) async {
          if (mounted &&
              _currentCameraFuture != null &&
              (await _currentCameraFuture) != lastController) {
            _toDispose.add(lastController);
          }
        });
      }
    });
  }

  Future<void> disposeCurrentController() async {
    final controller = await _currentCameraFuture;
    if (controller != null) {
      if (!_toDispose.contains(controller)) {
        _toDispose.add(controller);
      }
    }
  }

  Future<CameraController> loadController(CameraDescription camera) async {
    await disposeCurrentController();
    final controller = CameraController(camera, ResolutionPreset.high);
    await controller.initialize();
    final min = await controller.getMinZoomLevel();
    final max = await controller.getMaxZoomLevel();
    setState(() {
      _minZoomLevel = min;
      _maxZoomLevel = max;
      _currentZoomLevel = 1.0; // Reset zoom level
    });
    print("CAMERA MIN AND MAX ZOOM: $min - $max");
    await controller.setZoomLevel(_currentZoomLevel);
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
    final success = await Utils.copyFileToSaveDirectory(filePath);
    if (success) {
      await openFileManager(
        androidConfig: AndroidConfig(
          folderType: AndroidFolderType.other,
          folderPath: (await Utils.getSaveDirectory())!.path,
        ),
        iosConfig:
            IosConfig(folderPath: (await Utils.getSaveDirectory())!.path),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> onUploadImage(BuildContext context) async {
    setState(() {
      _isLoadingUpload = true;
    });
    if (getSelectedFilter() == null || getSelectedFilter()?.url == "") {
      showNoFilterMessage();
      setState(() {
        _isLoadingUpload = false;
      });
      return;
    }
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    try {
      if (image != null) {
        // You can now use the image file path
        print('Image selected: ${image.path}');
        final processedImagePath = await _processImage(
            image.path, getSelectedFilter()!.url,
            matchSourceSize: false);
        showImagePreview(processedImagePath!);
      }
    } finally {
      setState(() {
        _isLoadingUpload = false;
      });
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
    final filter = getSelectedFilter();
    if (mounted && filter != null) {
      showDialog(
        routeSettings: RouteSettings(
          // This ensures that when the dialog is popped, the controller is disposed
          // by checking if the current route is active.
          name: 'videoPreviewDialog',
        ),
        barrierDismissible: false, // Prevent dismissing by tapping outside
        context: context,
        builder: (BuildContext context) {
          return VideoPreview(videoPath: filePath, filterPath: filter.url);
        },
      ).then((_) =>
          print("Video preview dialog closed")); // Optional: for debugging
    }
  }

  Future<String?> _processImage(
    String imagePath,
    String filterImageUrl, {
    bool matchSourceSize = true,
  }) async {
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

    // Resize overlay to match camera image resolution if matchSourceSize is true
    final img.Image resizedOverlay;
    if (matchSourceSize) {
      resizedOverlay = img.copyResize(
        overlayImage,
        width: originalImage.width,
        height: originalImage.height,
      );
    } else {
      resizedOverlay = overlayImage;
    }

    // Composite the images
    final compositeImage = img.compositeImage(originalImage, resizedOverlay);

    // Save the composite image
    final directory = await Utils.getSaveDirectory();
    if (directory == null) {
      return null;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/composite_image_$timestamp.png';
    final _newFile = File(filePath)
      ..writeAsBytesSync(img.encodePng(compositeImage));
    print(_newFile);
    return filePath;
  }

  Future<void> _takePicture(
    String filterPath,
    CameraController controller,
  ) async {
    if (!await LocalStorageService.canTakeImage()) {
      showLimitReachedMessage();
      return;
    }
    try {
      setState(() {
        _isProcessingCapture = true;
      });
      controller.setFlashMode(FlashMode.off);
      controller.setExposureMode(ExposureMode.auto);
      final image = await controller.takePicture();
      // controller.pausePreview();
      final processedImagePath = await _processImage(image.path, filterPath);
      LocalStorageService.setImageTaken();

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
    if (getSelectedFilter() == null) {
      showNoFilterMessage();
      return;
    }
    if (!await LocalStorageService.canTakeVideo()) {
      showLimitReachedMessage();
      return;
    }
    try {
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording();
      LocalStorageService.setVideoTaken();
      setState(() {
        _isRecording = true;
      });
      print('Video recording started');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopVideoRecording(CameraController controller) async {
    print("STOP RECORDING! ${controller.value.isRecordingVideo}");
    if (!controller.value.isRecordingVideo) {
      return;
    }
    try {
      setState(() {
        _isProcessingCapture = true;
      });
      print('Video recording stopping');
      final file = await controller.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      print('Video recorded to ${file.path}');
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = file.path;
      final String newFileName = path.join(
          tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');
      final File tempFile = File(tempPath);
      final File newFile = tempFile.renameSync(newFileName);
      print('Video recorded to ${file.path} copied to ${newFile.path}');
      showVideoPreview(newFile.path);
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
    final docsDir = await Utils.getSaveDirectory();
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

  void onToggleZoom() async {
    if (_minZoomLevel >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Este nível de zoom não está disponível.\n"
              "Zoom mínimo disponível: ${_minZoomLevel.toStringAsFixed(1)}\n"
              "Zoom máximo disponível: ${_maxZoomLevel.toStringAsFixed(1)}"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final controller = await _currentCameraFuture;
    if (controller == null) return;

    double newZoomLevel;
    // Toggle between 1.0x and 0.5x (if available, otherwise use minZoomLevel)
    if (_currentZoomLevel >= 1.0) {
      newZoomLevel =
          _minZoomLevel < 0.6 ? 0.5 : _minZoomLevel; // Prefer 0.5x if possible
    } else {
      newZoomLevel = 1.0;
    }

    // Ensure the new zoom level is within the supported range
    newZoomLevel = newZoomLevel.clamp(_minZoomLevel, _maxZoomLevel);
    await controller.setZoomLevel(newZoomLevel);
    _currentZoomLevel = newZoomLevel;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text("Zoom alterado para ${_currentZoomLevel.toStringAsFixed(1)}x"),
        duration: const Duration(seconds: 1),
      ),
    );
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

  void showLimitReachedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Você atingiu o limite de uso dentro de 8 horas."),
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
            backgroundColor: const Color(0xFF0037c6),
            child: const Icon(Icons.image, color: Colors.white),
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
                backgroundColor:
                    _isRecording ? Colors.red : const Color(0xFF001362),
                child: buildCaptureIcon(context),
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: () => onUploadImage(context),
            mini: true,
            backgroundColor: const Color(0xFF0037c6),
            child: _isLoadingUpload
                ? SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(color: Colors.white))
                : const Icon(Icons.add_photo_alternate, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget buildFilterSelector(
    BuildContext context,
    CameraController? controller,
  ) {
    var textStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );
    var buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF001362).withAlpha((0.9 * 255).toInt()),
      // Example item color
      shape: const CircleBorder(),
      padding: EdgeInsets.zero, // Remove default padding
    ).copyWith(fixedSize: WidgetStateProperty.all(const Size(60, 60)));
    return Positioned(
      right: 0, // Adjust left position as needed
      child: SizedBox(
          height:
              MediaQuery.of(context).size.height * 0.5, // 50% of screen height
          width: 70, // Adjust width as needed
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final filterList = authProvider.loggedUser
                  ?.getFiltersByCategory(widget.categoryName);
              return ListView.builder(
                itemCount: filterList!.length + 1,
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
                  final FilterModel filter = filterList[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () => onFilterPressed(index - 1, filter),
                      style: buttonStyle,
                      child: Text('${index}', style: textStyle),
                    ),
                  );
                },
              );
            },
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Provider.of<AuthProvider>(context, listen: false).clearSelectedFilter();
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: null,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false)
                  .clearSelectedFilter();
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
            if(_isLoading){
              return Center(child: CircularProgressIndicator(),);
            }
            if(cameras.isEmpty) {
              return Center(child: Text('Câmera não disponível nesse dispositivo',style: TextStyle(color: Colors.white),),);
            }
            return Center(
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
                          backgroundColor: hasBothCameras()
                              ? const Color(0xFF0037c6)
                              : Colors.grey,
                          child: const Icon(Icons.cameraswitch_sharp,
                              color: Colors.white),
                        ),
                      ),
                      Positioned(
                          top: 10,
                          left: 10,
                          child: FloatingActionButton(
                            onPressed: onToggleZoom,
                            mini: true,
                            backgroundColor: _minZoomLevel >= 1
                                ? Colors.grey
                                : const Color(0xFF0037c6),
                            child: const Icon(Icons.camera,
                                color: Colors.white), // Example icon
                          )),
                    ],
                  );
                },
              ),
            );
          }
        ),
        floatingActionButton: null,
        drawer: null,
        bottomNavigationBar: null,
      ),
    );
  }
}
