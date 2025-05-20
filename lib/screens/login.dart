// Suggested code may be subject to a license. Learn more: ~LicenseLog:1523417679.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:4194068001.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1009326834.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:598618060.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2297896750.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:977295858.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2309492578.
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Column(
        children: [
          Expanded(
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
          ),
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
                        onPressed: () {
                          // Handle login logic
                          print('Login: ${_loginController.text}');
                          print('Senha: ${_senhaController.text}');
                          Navigator.pushNamed(context, '/categories');
                        },
                        child: const Text('Entrar'),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () {
                          // Handle support logic
                          print('SUPORTE button pressed');
                        },
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
      ),
    );
  }
}
