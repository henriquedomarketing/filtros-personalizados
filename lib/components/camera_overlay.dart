import 'package:camera/camera.dart';
import 'package:camera_marketing_app/models/filter_model.dart';
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
                  width: widget.cameraController!.value.previewSize?.height ?? 1080,
                  height: widget.cameraController!.value.previewSize?.width ?? 1920,
                  child: Stack(
                    children: [
                      CameraPreview(
                        widget.cameraController!,
                        child: Positioned.fill(
                          child: CustomPaint(painter: ThirdsGridPainter()),
                        ),
                      ),
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
                  if (filter.url == "") {
                    return Container();
                  }
                  return Image.asset(filter.url, fit: BoxFit.contain);
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
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
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
