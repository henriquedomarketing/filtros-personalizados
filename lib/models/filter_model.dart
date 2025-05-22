import 'package:flutter/cupertino.dart';

class FilterModel extends ChangeNotifier {
  String name = "";
  String filterAssetPath = "";

  FilterModel({required this.name, required this.filterAssetPath});

  void changeFilter(String newFilterAssetPath) {
    filterAssetPath = newFilterAssetPath;
    notifyListeners();
  }
}
