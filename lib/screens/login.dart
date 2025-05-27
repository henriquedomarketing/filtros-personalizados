import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera_marketing_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

import '../models/company_model.dart';
import '../services/company_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _senhaController = TextEditingController();

  bool _keyboardVisible = false;

  late Future<String?> futureBannerUrl;

  @override
  void initState() {
    super.initState();
    futureBannerUrl = _loadBanner();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<String?> _loadBanner() async {
    try {
      final ref = FirebaseStorage.instance.ref().child(BANNER_FILENAME);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error loading banner: $e');
      return null;
    }
  }

  void onLogin(BuildContext context) async {
    // try {
    if (!_formKey.currentState!.validate()) {
      return;
    }
      CompanyModel? result = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(_loginController.text, _senhaController.text);
      if (result != null) {
        if (result.admin) {
          Navigator.of(context).pushNamed('/admin');
        } else {
          Navigator.of(context).pushNamed('/categories');
        }
      }
    // } catch (e) {
    //   print(e);
    //   throw e;
    // }
  }

  void onSupport() {}

  Widget buildBanner(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30.0),
          bottomRight: Radius.circular(30.0),
        ),
        child: Container(
            color: Colors.white,
            child: FutureBuilder<String?>(
              future: futureBannerUrl,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Icon(Icons.error)); // Placeholder for error or no banner
                } else {
                  return CachedNetworkImage(
                    imageUrl: snapshot.data!,
                    cacheKey: "banner800",
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                  );
                }
              },
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    // final loggedUser = Provider.of<AuthProvider>(context).loggedUser;
    // if (loggedUser != null) {
    //   Navigator.of(context).pushNamed("/categories");
    // }
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.indigo,
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  _keyboardVisible ? Container() : buildBanner(context),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextFormField(
                                  controller: _loginController,
                                  decoration: const InputDecoration(
                                    labelText: 'Login',
                                    fillColor: Colors.white,
                                    filled: true,
                                    errorStyle: TextStyle(color: Colors.orangeAccent),
                                    border: UnderlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Digite seu e-mail.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  controller: _senhaController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Senha',
                                    fillColor: Colors.white,
                                    filled: true,
                                    errorStyle: TextStyle(color: Colors.orangeAccent),
                                    border: UnderlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Digite sua senha.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24.0),
                                ElevatedButton(
                                  onPressed: () => onLogin(context),
                                  child:
                                      (authProvider.isLoading
                                          ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(),
                                          )
                                          : const Text('Entrar')),
                                ),
                                const SizedBox(height: 16.0),
                                TextButton(
                                  onPressed: onSupport,
                                  child: const Text(
                                    'SUPORTE',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                authProvider.error != null
                                    ? Container(
                                      color: Colors.red.withValues(alpha: 0.25),
                                      margin: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        authProvider.error!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                    : Container(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
