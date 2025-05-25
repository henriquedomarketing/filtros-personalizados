import 'package:flutter/foundation.dart';
import '../models/company_model.dart';
import '../services/company_service.dart';

class AdminProvider extends ChangeNotifier {
  List<CompanyModel> _companies = [];
  bool _isLoading = false;
  String? _error;

  List<CompanyModel> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCompanies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final companies = await CompanyService.fetchCompanies();
      _companies = companies;
      _error = null;
    } catch (e) {
      _companies.clear();
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}