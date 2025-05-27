import 'package:camera_marketing_app/models/filter_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyModel {
  String name;
  String? login;
  List<FilterModel> filters;

  bool admin;
  User? user;
  String? uid;

  CompanyModel({
    required this.name,
    required this.filters,
    this.login,
    this.user,
    this.admin = false,
    this.uid,
  });
  
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['name'],
      login: json.containsKey('login') ? json['login'] : null,
      admin: json.containsKey('admin') ? json['admin'] : false,
      uid: json.containsKey('uid') ? json['uid'] : null,
      filters: (json['filters'] as List)
          .map((filterJson) => FilterModel.fromJson(filterJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'login': login ?? "",
      'filters': filters.map((filter) => filter.toJson()).toList(),
      'admin': admin,
      'uid': uid,
    };
  }
}
