import 'package:flutter/cupertino.dart';

class FilterModel {
  String name = "";
  String url = "";

  FilterModel({required this.name, required this.url});
  
  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      name: json['name'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}
