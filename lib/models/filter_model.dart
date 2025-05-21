import 'package:flutter/cupertino.dart';

class FilterModel extends ChangeNotifier {
  String filterAssetPath = "";

  void changeFilter(String newFilterAssetPath) {
    filterAssetPath = newFilterAssetPath;
    notifyListeners();
  }
}