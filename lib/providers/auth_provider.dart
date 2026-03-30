import 'package:camera_marketing_app/models/company_model.dart';
import 'package:camera_marketing_app/services/company_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/filter_model.dart';
class AuthProvider with ChangeNotifier {
  CompanyModel? _loggedUser;
  bool _isLoading = false;
  String? _error;
  FilterModel? _selectedFilter;
  CompanyModel? get loggedUser => _loggedUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FilterModel? get selectedFilter => _selectedFilter;
  Future<void> loadUserFromFirebase() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    try {
      _isLoading = true;
      notifyListeners();
      final user = await CompanyService.usersDb
          .doc(firebaseUser.uid)
          .get()
          .then((s) => s.data() as CompanyModel);
      _loggedUser = user;
    } catch (e) {
      _loggedUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<CompanyModel?> login(String login, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await CompanyService.login(login, password);
      _loggedUser = user;
      _error = null;
      return user;
    } on FirebaseAuthException catch (e) {
      _loggedUser = null;
      _error = e.toString();
      return null;
    } catch (e) {
      _loggedUser = null;
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> logoutUser() async {
    await FirebaseAuth.instance.signOut();
    _loggedUser = null;
    notifyListeners();
  }
  void setSelectedFilter(FilterModel filter) {
    _selectedFilter = filter;
    notifyListeners();
  }
  void clearSelectedFilter() {
    _selectedFilter = null;
    notifyListeners();
  }
}
