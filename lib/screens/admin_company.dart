import 'package:camera_marketing_app/services/company_service.dart';
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

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void onCadastrar(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    print('Company Name: ${_companyNameController.text}');
    print('Login: ${_loginController.text}');
    print('Password: ${_passwordController.text}');
    final name = _companyNameController.text;
    final email = _loginController.text;
    final password = _passwordController.text;
    try {
      setState(() {
        isLoading = true;
      });
      final error = await CompanyService.adminRegisterCompany(email, password, name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Empresa cadastrada com sucesso!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (error == null) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
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

  String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Senha precisa ter no mínimo 6 caracteres';
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
                validator: (value) => validatePassword(value),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => onCadastrar(context),
                child: isLoading ? const CircularProgressIndicator() : const Text('CADASTRAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
