import 'package:flutter/material.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PAINEL ADMINISTRATIVO'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
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
                    child: Container(
                      color: Colors.blue, // Placeholder color
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
                    child: Container(
                      color: Colors.blue, // Placeholder color
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
            Container(
              height: 80, // Placeholder height
              color: Colors.blue, // Placeholder color
              child: Center(
                child: Text(
                  'UPLOAD BANNER 800X800',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'LINK SUPORT',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // You can use a TextField or a Button here depending on interaction
            TextFormField(
              initialValue: 'HTTP://LINKDOSUPORT.COM.BR',
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              readOnly: true, // Make it read-only if it's just a display
            ),
            // Or a Button:
            // ElevatedButton(
            //   onPressed: () {
            //     // TODO: Implement link action
            //   },
            //   child: Text('HTTP://LINKDOSUPORT.COM.BR'),
            // ),
          ],
        ),
      ),
    );
  }
}