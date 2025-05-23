// Suggested code may be subject to a license. Learn more: ~LicenseLog:1320874755.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3485984413.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3428694682.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2553350967.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:817786057.
import 'package:camera_marketing_app/screens/admin_company.dart';
import 'package:camera_marketing_app/screens/admin_filters.dart';
import 'package:flutter/material.dart';
import 'package:camera_marketing_app/screens/camera.dart';
import 'package:camera_marketing_app/screens/categories.dart';
import 'package:camera_marketing_app/screens/login.dart';
import 'package:camera_marketing_app/screens/admin_panel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:camera_marketing_app/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CameraMarketingApp());
}

class CameraMarketingApp extends StatelessWidget {
  const CameraMarketingApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        initialRoute: "/",
        routes: {
          "/": (context) => const LoginScreen(),
          "/categories": (context) => const CategoriesScreen(),
          "/camera": (context) => const CameraScreen(),
          "/admin": (context) => const AdminPanelScreen(),
          "/admin/company": (context) => const AdminCompanyScreen(),
          "/admin/filter": (context) => const AdminFilterScreen(),
        },
      ),
    );
  }
}
