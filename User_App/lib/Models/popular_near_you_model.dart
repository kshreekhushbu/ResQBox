// To parse this JSON data, do
//
//     final popularNearModel = popularNearModelFromJson(jsonString);

import 'dart:convert';

import 'package:resqbox_user/Models/home_data_model.dart';

PopularNearModel popularNearModelFromJson(String str) =>
    PopularNearModel.fromJson(json.decode(str));

String popularNearModelToJson(PopularNearModel data) =>
    json.encode(data.toJson());

class PopularNearModel {
  int? status;
  String? message;
  List<Product>? data;

  PopularNearModel({
    this.status,
    this.message,
    this.data,
  });

  factory PopularNearModel.fromJson(Map<String, dynamic> json) =>
      PopularNearModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Product>.from(json["data"]!.map((x) => Product.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}
