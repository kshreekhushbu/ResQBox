// To parse this JSON data, do
//
//     final configDetailsModel = configDetailsModelFromJson(jsonString);

import 'dart:convert';

ConfigDetailsModel configDetailsModelFromJson(String str) =>
    ConfigDetailsModel.fromJson(json.decode(str));

String configDetailsModelToJson(ConfigDetailsModel data) =>
    json.encode(data.toJson());

class ConfigDetailsModel {
  int? status;
  String? message;
  List<Config>? config;

  ConfigDetailsModel({
    this.status,
    this.message,
    this.config,
  });

  factory ConfigDetailsModel.fromJson(Map<String, dynamic> json) =>
      ConfigDetailsModel(
        status: json["status"],
        message: json["message"],
        config: json["config"] == null
            ? []
            : List<Config>.from(json["config"]!.map((x) => Config.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "config": config == null
            ? []
            : List<dynamic>.from(config!.map((x) => x.toJson())),
      };
}

class Config {
  int? configId;
  String? configKey;
  String? configValue;

  Config({
    this.configId,
    this.configKey,
    this.configValue,
  });

  factory Config.fromJson(Map<String, dynamic> json) => Config(
        configId: json["configId"],
        configKey: json["configKey"],
        configValue: json["configValue"],
      );

  Map<String, dynamic> toJson() => {
        "configId": configId,
        "configKey": configKey,
        "configValue": configValue,
      };
}
