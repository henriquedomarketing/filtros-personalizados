import 'package:camera_marketing_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _keyboardVisible = false;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void onLogin(BuildContext context) async {
    try {
      var result = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(_loginController.text, _senhaController.text);
      if (result != null) {
        Navigator.of(context).pushNamed('/categories');
      }
    } catch (e) {
      print(e);
    }
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
          child: Image.asset(
            'assets/banner800.jpg', // Replace 'banner800.jpg' with the actual asset path
            fit: BoxFit.fitWidth,
            width: double.infinity,
          ),
        ),
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
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextField(
                                controller: _loginController,
                                decoration: const InputDecoration(
                                  labelText: 'Login',
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              TextField(
                                controller: _senhaController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Senha',
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(),
                                ),
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
                            ],
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
