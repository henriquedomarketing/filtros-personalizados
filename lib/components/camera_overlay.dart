import 'package:camera/camera.dart';
import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:camera_marketing_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CameraOverlay extends StatefulWidget {
  final CameraController? cameraController;

  const CameraOverlay({super.key, this.cameraController});

  @override
  _CameraOverlayState createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay> {
  @override
  Widget build(BuildContext context) {
    if (widget.cameraController != null) {
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
                  width: widget.cameraController!.value.previewSize?.height ??
                      1080,
                  height:
                      widget.cameraController!.value.previewSize?.width ?? 1920,
                  child: Stack(
                    children: [
                      CameraPreview(widget.cameraController!),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: ThirdsGridPainter())),
          Positioned.fill(
            child: Opacity(
              opacity: 1,
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final FilterModel? filter = authProvider.selectedFilter;
                  if (filter == null || filter.url == "") {
                    return Container();
                  }
                  return Image.network(
                    // Use Image.network
                    key: ValueKey(filter
                        .url), // Add a key to force rebuild when filter changes
                    filter.url, // The URL of the image
                    fit: BoxFit
                        .fill, // How the image should be inscribed into the space allocated during layout
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Return the image if it's fully loaded
                      }
                      return const Center(
                        child:
                            CircularProgressIndicator(), // Show a progress indicator while loading
                      );
                    },
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return const Icon(Icons
                          .error); // Show an error icon if the image fails to load
                    },
                  );
                  // return CachedNetworkImage(
                  //   imageUrl: filter.url,
                  //   fit: BoxFit.fill,
                  //   cacheKey: filter.name,
                  //   placeholder: (context, url) => const Center(
                  //     child: SizedBox(
                  //       height: 50,
                  //       width: 50,
                  //       child: CircularProgressIndicator(),
                  //     ),
                  //   ),
                  //   errorWidget: (context, url, error) => const Icon(Icons.error),);
                },
              ),
            ),
          ),
        ],
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}

class ThirdsGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha((0.2 * 255).toInt())
      ..strokeWidth = 2
      ..filterQuality = FilterQuality.high;

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
