import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/company_model.dart';
import '../services/company_service.dart';

final JsonEncoder encoder = JsonEncoder.withIndent('  ');

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
      print("[ADMIN PROVIDER] fecthedCompanies:");
      print(encoder.convert(companies));
      _companies = companies;
      _error = null;
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      _companies.clear();
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> registerFilter(String name, String filePath, String category, CompanyModel company,
      {int order = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await CompanyService.createFilterForCompany(name, filePath, category, company);
      return null;
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}