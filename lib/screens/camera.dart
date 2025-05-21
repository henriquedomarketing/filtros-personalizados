import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_marketing_app/components/camera_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    loadCameras();
  }

  void loadCameras() async {
    List<CameraDescription> localCameras = await availableCameras();
    setState(() {
      cameras = localCameras;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CameraOverlay(camera: cameras[0]);
  }
}
