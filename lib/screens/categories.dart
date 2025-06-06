import 'package:camera_marketing_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  void onGoBack(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logoutUser();
    Navigator.of(context).pop();
  }

  void onPressCategory(String categoryName) {
    Navigator.pushNamed(context, "/camera",
        arguments: {"categoryName": categoryName});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, authProvider, child) {
      print(authProvider.loggedUser?.categories);
      return Scaffold(
        backgroundColor: const Color(0xFF001362),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'CATEGORIAS',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => onGoBack(context),
          ),
        ),
        body: authProvider.loggedUser != null &&
                authProvider.loggedUser!.categories.isNotEmpty
            ? ListView.builder(
                itemCount: authProvider.loggedUser!.categories.length,
                itemBuilder: (BuildContext context, int index) {
                  final String categoryName =
                    authProvider.loggedUser!.categories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () => onPressCategory(categoryName),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                      ),
                      child: Text(categoryName),
                    ),
                  );
                },
              )
            : const Center(
                child: Text('Nenhuma categoria disponível.',
                    style: TextStyle(color: Colors.white))),
      );
    });
  }
}
