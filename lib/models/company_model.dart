import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyModel {
  String name;
  String? login;
  String? password;
  List<FilterModel> filters;

  bool admin;
  User? user;

  CompanyModel({
    required this.name,
    required this.filters,
    this.login,
    this.password,
    this.user,
    this.admin = false,
  });
  
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['name'],
      login: json.containsKey('login') ? json['login'] : null,
      password: json.containsKey('password') ? json['password'] : null,
      admin: json.containsKey('admin') ? json['admin'] : false,
      filters: (json['filters'] as List)
          .map((filterJson) => FilterModel.fromJson(filterJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'login': login ?? "",
      'password': password ?? "",
      'filters': filters.map((filter) => filter.toJson()).toList(),
      'admin': admin,
    };
  }

}
