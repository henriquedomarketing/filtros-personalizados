import 'package:camera_marketing_app/services/config_service.dart';
import 'package:flutter/cupertino.dart';

import '../models/config_model.dart';

class ConfigProvider extends ChangeNotifier {
  ConfigModel? _config;
  bool _isLoading = false;
  String? _error;

  ConfigModel? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchConfig() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = await ConfigService.getSupportUrl();
      _config = ConfigModel(supportUrl: url);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSupportUrl(String url) async {
    await ConfigService.setSupportUrl(url);
    if (_config != null) {
      _config!.supportUrl = url;
    } else {
      _config = ConfigModel(supportUrl: url);
    }
    notifyListeners();
  }
}