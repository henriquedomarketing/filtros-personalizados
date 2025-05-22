import 'package:camera_marketing_app/models/filter_model.dart';

class CompanyModel {
  String name;
  String login;
  String password;
  List<FilterModel> filters;

  CompanyModel({
    required this.name,
    required this.login,
    required this.password,
    required this.filters,
  });
}
