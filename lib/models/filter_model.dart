class FilterModel {
  String name = "";
  String category = "";
  String url = "";

  FilterModel({required this.name, required this.url, required this.category});
  
  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      name: json['name'],
      category: json['category'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'url': url,
    };
  }
}
