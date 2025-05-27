import 'package:camera_marketing_app/providers/admin_provider.dart';
import 'package:camera_marketing_app/screens/admin_company.dart';
import 'package:camera_marketing_app/screens/admin_filters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  FirebaseFirestore.instance.settings = FirebaseFirestore.instance.settings.copyWith(persistenceEnabled: false);
  runApp(const CameraMarketingApp());
}

class CameraMarketingApp extends StatelessWidget {
  const CameraMarketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<AdminProvider>(create: (_) => AdminProvider())
      ],
      child: MaterialApp(
        title: 'Camera Marketing',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        initialRoute: "/",
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case "/":
              return MaterialPageRoute(builder: (context) => const LoginScreen());
            case "/categories":
              return MaterialPageRoute(builder: (context) => const CategoriesScreen());
            case "/camera":
              final String? categoryName = (settings.arguments as Map<String, dynamic>)['categoryName'] as String?;
              return MaterialPageRoute(builder: (context) => CameraScreen(categoryName: categoryName ?? ""));
            case "/admin":
              return MaterialPageRoute(builder: (context) => const AdminPanelScreen());
            case "/admin/company":
              return MaterialPageRoute(builder: (context) => const AdminCompanyScreen());
            case "/admin/filter":
              return MaterialPageRoute(builder: (context) => const AdminFilterScreen());
            default:
              return MaterialPageRoute(builder: (context) => const LoginScreen());
          }
        },
      ),
    );
  }
}
