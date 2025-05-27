import 'dart:io';

import 'package:camera_marketing_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinbox/material.dart';
import '../models/company_model.dart';
import '../models/filter_model.dart';

class AdminFilterScreen extends StatefulWidget {
  const AdminFilterScreen({super.key});

  @override
  State<AdminFilterScreen> createState() => _AdminFilterScreenState();
}

class _AdminFilterScreenState extends State<AdminFilterScreen> {
  CompanyModel? selectedCompany;
  String? selectedCategory;
  final TextEditingController _newCategoryController = TextEditingController();
  String? selectedImage;

  int filterNumber = 0;

  @override
  void initState() {
    super.initState();
    // Call fetchCompanies when the widget is first initialized
    Provider.of<AdminProvider>(context, listen: false).fetchCompanies();
  }

  void onCadastrar() async {
    if (!mounted) return;
    if (selectedCompany == null ||
        (selectedCategory == null && _newCategoryController.text == "") ||
        selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos'),
        ),
      );
      return;
    }
    try {
      final name = "";
      final categoryName = selectedCategory ?? _newCategoryController.text;
      final error = await Provider.of<AdminProvider>(context, listen: false)
          .registerFilter(name, selectedImage!, categoryName, selectedCompany!, order: filterNumber);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar filtro'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filtro cadastrado com sucesso'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro desconhecido: ${e.toString()}"),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget buildCompanySelect(BuildContext context, AdminProvider adminProvider) {
    if (adminProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: selectedCompany?.name,
      items: adminProvider.companies
          .map((company) =>
              DropdownMenuItem(value: company.name, child: Text(company.name)))
          .toList(),
      onChanged: onSelectCompanyName,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget buildCategorySelect(
      BuildContext context, AdminProvider adminProvider) {
    if (adminProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (selectedCompany == null) {
      return const Text('Nenhuma empresa selecionada');
    }
    bool isAddingNew = _newCategoryController.text != "";
    var items = selectedCompany?.categories
        .map((categoryName) =>
            DropdownMenuItem(value: categoryName, child: Text(categoryName)))
        .toList();
    var selectedValue = isAddingNew ? "@@new" : selectedCategory;
    if (isAddingNew) {
      items?.insert(
          0,
          DropdownMenuItem(
              value: "@@new", child: Text(_newCategoryController.text)));
    }
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items,
      style: isAddingNew ? TextStyle(color: Colors.grey[700]) : null,
      onChanged: (value) {
        if (isAddingNew) return;
        onSelectCategoryName(value);
      },
      decoration: const InputDecoration(
        fillColor: Colors.grey,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget buildFilterImageSelector(
      BuildContext context, AdminProvider adminProvider) {
    if (!adminProvider.isLoading && selectedImage != null) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedImage = null;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Image.file(File(selectedImage!), fit: BoxFit.contain),
              ),
              Text("Toque para remover")
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onSelectImage,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file),
            SizedBox(height: 8.0),
            Text('Toque para Upload'),
          ],
        ),
      ),
    );
  }

  void onSelectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = image.path;
      });
    }
  }

  void onSelectCompanyName(String? value) {
    if (!mounted) return;
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final CompanyModel? company = value != null
        ? adminProvider.companies.firstWhere((company) => company.name == value)
        : null;
    setState(() {
      selectedCompany = company;
      selectedCategory = null;
    });
  }

  void onSelectCategoryName(String? value) {
    final FilterModel? filter = value != null
        ? selectedCompany?.filters.firstWhere((filter) => filter.name == value)
        : null;
    setState(() {
      selectedCategory = filter?.category ?? "";
    });
  }

  void onNewClear() {
    _newCategoryController.clear();
    setState(() {
      selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CADASTRAR FILTRO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text('NOME DA EMPRESA'),
                buildCompanySelect(context, adminProvider),
                const SizedBox(height: 16.0),
                const Text('CATEGORIA'),
                buildCategorySelect(context, adminProvider),
                const SizedBox(height: 16.0),
                const Text('NOVA CATEGORIA'),
                TextFormField(
                  controller: _newCategoryController,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.add),
                      suffix: IconButton(
                          onPressed: onNewClear, icon: Icon(Icons.clear))),
                ),
                const SizedBox(height: 16.0),
                const Text('NUMERO DO FILTRO'),
                SpinBox(
                  min: 1,
                  max: 100,
                  value: filterNumber.toDouble(),
                  onChanged: (value) => setState(() {
                    filterNumber = value.toInt();
                  }),
                ),
                const SizedBox(height: 16.0),
                const Text('UPLOAD FILTRO'),
                buildFilterImageSelector(context, adminProvider),
                const SizedBox(height: 24.0),
                adminProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: onCadastrar,
                        child: const Text('CADASTRAR'),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }
}
