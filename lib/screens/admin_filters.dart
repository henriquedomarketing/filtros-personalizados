import 'package:flutter/material.dart';

class AdminFilterScreen extends StatelessWidget {
  const AdminFilterScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('NOME DA EMPRESA'),
            DropdownButtonFormField<String>(
              items: const [
                // TODO: Add company names here
                DropdownMenuItem(value: 'Company 1', child: Text('Company 1')),
                DropdownMenuItem(value: 'Company 2', child: Text('Company 2')),
              ],
              onChanged: (value) {
                // TODO: Handle company selection
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('CATEGORIA'),
            DropdownButtonFormField<String>(
              items: const [
                // TODO: Add categories here
                DropdownMenuItem(value: 'Category 1', child: Text('Category 1')),
                DropdownMenuItem(value: 'Category 2', child: Text('Category 2')),
              ],
              onChanged: (value) {
                // TODO: Handle category selection
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('NOVA CATEGORIA'),
            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.add),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('NUMERO DO FILTRO'),
            DropdownButtonFormField<String>(
              items: const [
                // TODO: Add filter numbers here
                DropdownMenuItem(value: 'Filter 1', child: Text('Filter 1')),
                DropdownMenuItem(value: 'Filter 2', child: Text('Filter 2')),
              ],
              onChanged: (value) {
                // TODO: Handle filter number selection
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('UPLOAD FILTRO'),
            GestureDetector(
              onTap: () {
                // TODO: Handle file upload
              },
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
                    Text('Tap to Upload'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                // TODO: Handle cadastrar button press
              },
              child: const Text('CADASTRAR'),
            ),
          ],
        ),
      ),
    );
  }
}