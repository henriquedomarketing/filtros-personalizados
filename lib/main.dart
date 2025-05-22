import 'package:flutter/material.dart';
import 'package:camera_marketing_app/screens/camera.dart';
import 'package:camera_marketing_app/screens/categories.dart';
import 'package:camera_marketing_app/screens/login.dart';
import 'package:camera_marketing_app/screens/admin_panel.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(const CameraMarketingApp());
}

class CameraMarketingApp extends StatelessWidget {
  const CameraMarketingApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: "/camera",
      routes: {
        "/": (context) => const LoginScreen(),
        "/categories": (context) => const CategoriesScreen(),
        "/camera": (context) => const CameraScreen(),
        "/admin": (context) => const AdminPanelScreen(),
      },
    );
  }
}
