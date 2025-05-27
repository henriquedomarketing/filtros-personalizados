import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/config_provider.dart';
import '../services/company_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {

  bool loadingBanner = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
  }

  void onCadastrarEmpresa(BuildContext context) {
    Navigator.of(context).pushNamed('/admin/company');
  }

  void onCadastrarFiltro(BuildContext context) {
    Navigator.of(context).pushNamed('/admin/filter');
  }

  Future<void> onUploadBanner(BuildContext context) async {
    if (loadingBanner) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null || !mounted) {
      return;
    }
    setState(() {
      loadingBanner = true;
    });
    print('Image path: ${image.path}');
    try {
      final result = await CompanyService.uploadBanner(image.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result
              ? 'Banner carregado com sucesso'
              : 'Erro ao carregar banner'),
        ),
      );
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
    } finally {
      setState(() {
        loadingBanner = false;
      });
    }
  }

  void onGoBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void onSupportChanged(String value, ConfigProvider configProvider) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      onSupportSaved(value, configProvider);
    });
  }

  void onSupportSaved(String value, ConfigProvider configProvider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Deseja salvar o link do suporte?"),
        action: SnackBarAction(
          label: "Salvar",
          onPressed: () async {
            await configProvider.setSupportUrl(value);
            print("Link do suporte salvo: $value");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text("Salvo com sucesso")),
              );
          },
        ),
      ));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PAINEL ADMINISTRATIVO'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => onGoBack(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ElevatedButton(
                      onPressed: () => onCadastrarEmpresa(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'CADASTRAR EMPRESA',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ElevatedButton(
                      onPressed: () => onCadastrarFiltro(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'CADASTRAR FILTROS',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ElevatedButton(
                onPressed: () => onUploadBanner(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: loadingBanner
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'UPLOAD BANNER 800x800',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'LINK SUPPORT',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Consumer<ConfigProvider>(
              builder: (context, configProvider, child) {
                return TextFormField(
                  initialValue: configProvider.config?.supportUrl ?? "",
                  onChanged: (value) => onSupportChanged(value, configProvider),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                );
              }
            )
          ],

        ),
      ),
    );
  }
}
