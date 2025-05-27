class ConfigModel {
  String supportUrl = "";

  ConfigModel({required this.supportUrl});

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      supportUrl: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': supportUrl,
    };
  }
}