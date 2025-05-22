import 'package:flutter/material.dart';

class AdminCompanyScreen extends StatefulWidget {
  const AdminCompanyScreen({Key? key}) : super(key: key);

  @override
  _AdminCompanyScreenState createState() => _AdminCompanyScreenState();
}

class _AdminCompanyScreenState extends State<AdminCompanyScreen> {

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void onCadastrar() {
    if (_formKey.currentState!.validate()) {
      // Process data from controllers
      print('Company Name: ${_companyNameController.text}');
      print('Login: ${_loginController.text}');
      print('Password: ${_passwordController.text}');
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo é obrigatório';
    }
    // Basic email format validation
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
      return 'Utilize um email válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CADASTRAR EMPRESA'),
        leading: BackButton(
          onPressed: () { // Using BackButton's onPressed to handle back navigation
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'NOME DA EMPRESA',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                controller: _companyNameController,
              ),
              const SizedBox(height: 16.0),
              Text(
                'LOGIN',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                controller: _loginController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => validateEmail(value),
              ),
              const SizedBox(height: 16.0),
              Text(
                'SENHA',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: onCadastrar,
                child: const Text('CADASTRAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
