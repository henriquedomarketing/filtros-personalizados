import 'package:camera_marketing_app/models/company_model.dart';
import 'package:camera_marketing_app/services/company_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  CompanyModel? _loggedUser;
  bool _isLoading = false;
  String? _error;

  CompanyModel? get loggedUser => _loggedUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<CompanyModel?> login(String login, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await CompanyService.login(login, password);
      _loggedUser = user;
      _error = null;
      return user;
    // } on FirebaseAuthException catch (e) {
    //   _loggedUser = null;
    //   _error = e.toString();
    //   return null;
    // } catch (e) {
    //   print(e);
    //   throw e;
    //   _loggedUser = null;
    //   _error = e.toString();
    //   return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logoutUser() {
    _loggedUser = null;
    notifyListeners();
  }
}