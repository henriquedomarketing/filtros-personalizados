import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyModel {
  String name;
  String login;
  String password;
  List<FilterModel> filters;

  bool admin;
  User? user;

  CompanyModel({
    required this.name,
    required this.login,
    required this.password,
    required this.filters,
    this.user,
    this.admin = false,
  });
  
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['name'],
      login: json['login'],
      password: json['password'],
      filters: (json['filters'] as List)
          .map((filterJson) => FilterModel.fromJson(filterJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'login': login,
      'password': password,
      'filters': filters.map((filter) => filter.toJson()).toList(),
    };
  }

}
