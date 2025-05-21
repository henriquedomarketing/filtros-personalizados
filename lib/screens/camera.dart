import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_marketing_app/components/camera_overlay.dart';
import 'package:provider/provider.dart';

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
    return ChangeNotifierProvider(
      create: (context) => FilterModel(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CameraOverlay(camera: cameras[0]),
          Positioned(
            right: 0, // Adjust left position as needed
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
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
                        fixedSize: MaterialStateProperty.all(
                          const Size(60, 60),
                        ),
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
          ),
        ]
      ),
    );
  }
}
