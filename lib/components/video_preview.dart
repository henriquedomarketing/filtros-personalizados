import 'package:flutter/material.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../services/company_service.dart';
import '../utils.dart';

class VideoPreview extends StatefulWidget {
  final String videoPath;
  final String filterPath;

  const VideoPreview(
      {super.key, required this.videoPath, required this.filterPath});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late Future<String?> futureOutputVideoUrl;

  Future<VideoPlayerController?> futureVideoController = Future(() => null);

  bool saveLoading = false;
  bool alreadySaved = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      saveLoading = false;
      alreadySaved = false;
    });
    loadVideo();
  }

  @override
  void dispose() {
    super.dispose();
    futureVideoController.then((ctr) {
      ctr?.dispose();
    });
  }

  void loadVideo() async {
    setState(() {
      futureOutputVideoUrl = CompanyService.uploadAndProcessVideo(
          widget.videoPath, widget.filterPath);
    });
    futureOutputVideoUrl.then((url) => setState(() {
          futureVideoController = loadVideoController();
        }));
  }

  Future<VideoPlayerController?> loadVideoController() async {
    final url = await futureOutputVideoUrl;
    if (url == null) return null;
    final ctr = VideoPlayerController.networkUrl(Uri.parse(url));
    await ctr.initialize();
    return ctr;
  }

  void onPreviewSave() async {
    setState(() {
      saveLoading = true;
    });
    try {
      final url = await futureOutputVideoUrl;
      if (url == null) return;
      await CompanyService.downloadAndSaveVideo(url);
      final docsDir = await Utils.getSaveDirectory();
      openFileManager(
        androidConfig: AndroidConfig(
          folderType: AndroidFolderType.other,
          folderPath: docsDir!.path,
        ),
        iosConfig: IosConfig(folderPath: docsDir.path),
      );
      setState(() {
        alreadySaved = true;
      });
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
    } finally {
      setState(() {
        saveLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: futureOutputVideoUrl,
        builder: (context, videoOutputSnapshot) {
          return FutureBuilder(
              future: futureVideoController,
              builder: (context, videoControllerSnapshot) {
                Widget content =
                    const Center(child: CircularProgressIndicator());
                final controller = videoControllerSnapshot.data;
                final url = videoOutputSnapshot.connectionState != ConnectionState.done ? null : videoOutputSnapshot.data;
                if (videoOutputSnapshot.connectionState !=
                    ConnectionState.done) {
                  content = const Center(child: CircularProgressIndicator());
                } else if (videoControllerSnapshot.connectionState ==
                        ConnectionState.done &&
                    videoControllerSnapshot.data == null) {
                  content = const Center(
                    child: Text("Erro ao processar o vídeo"),
                  );
                } else if (videoControllerSnapshot.connectionState ==
                        ConnectionState.done &&
                    videoControllerSnapshot.data != null &&
                    videoOutputSnapshot.connectionState ==
                        ConnectionState.done) {
                  content = SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8, // Adjust width as needed
                    height: MediaQuery.of(context).size.height * 0.6, // Adjust height as needed
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: controller!.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  );
                }
                return PopScope(
                  canPop: false,
                  // Prevent back button from closing dialog directly
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return; // Already handled by Navigator.pop
                    controller?.pause();
                    controller?.dispose();
                    Navigator.of(context).pop();
                  },
                  child: AlertDialog(
                    content: content,
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          controller?.pause();
                          controller?.dispose();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Fechar'),
                      ),
                      SizedBox(width: 15),
                      url != null && !saveLoading ? TextButton(
                        onPressed: alreadySaved ? null : () => onPreviewSave(),
                        style: TextButton.styleFrom(
                          foregroundColor: alreadySaved
                              ? Theme.of(context).disabledColor
                              : Theme.of(context).primaryColor,
                        ),
                        child: const Text('SALVAR'),
                      ) : const SizedBox(
                          width: 40,
                          height: 5,
                          child: LinearProgressIndicator()
                      ),
                      url != null ? IconButton(
                        onPressed: () {
                          controller?.play();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                        icon: Icon(
                          Icons.play_circle_fill,
                        ),
                      ) : const SizedBox(
                          width: 40,
                          height: 5,
                          child: LinearProgressIndicator()
                      ),
                    ],
                  ),
                );
              });
        });
  }
}
