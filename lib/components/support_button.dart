import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/config_provider.dart';

class SupportButton extends StatelessWidget {
  const SupportButton({super.key});

  Future<void> _launchURL(String url) async {
    print("trying to launch $url");
    if (!await launchUrl(Uri.parse(url))) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(builder: (context, configProvider, child) {
      return TextButton(
        onPressed: () => _launchURL(configProvider.config?.supportUrl ?? ""),
        child: const Text(
        'SUPORTE',
        style: TextStyle(color: Colors.white),
      ),);
    });
  }
}
