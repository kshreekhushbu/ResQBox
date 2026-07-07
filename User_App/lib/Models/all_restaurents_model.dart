// To parse this JSON data, do
//
//     final allRestaurentsModel = allRestaurentsModelFromJson(jsonString);

import 'dart:convert';

import 'package:resqbox_user/Models/home_data_model.dart';

AllRestaurentsModel allRestaurentsModelFromJson(String str) =>
    AllRestaurentsModel.fromJson(json.decode(str));

String allRestaurentsModelToJson(AllRestaurentsModel data) =>
    json.encode(data.toJson());

class AllRestaurentsModel {
  int? status;
  String? message;
  List<int>? cuisineFilter;
  List<ActiveRestaurantData>? kitchens;

  AllRestaurentsModel({
    this.status,
    this.message,
    this.cuisineFilter,
    this.kitchens,
  });

  factory AllRestaurentsModel.fromJson(Map<String, dynamic> json) =>
      AllRestaurentsModel(
        status: json["status"],
        message: json["message"],
        cuisineFilter: json["cuisineFilter"] == null
            ? []
            : List<int>.from(json["cuisineFilter"]!.map((x) => x)),
        kitchens: json["kitchens"] == null
            ? []
            : List<ActiveRestaurantData>.from(
                json["kitchens"]!.map((x) => ActiveRestaurantData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "cuisineFilter": cuisineFilter == null
            ? []
            : List<dynamic>.from(cuisineFilter!.map((x) => x)),
        "kitchens": kitchens == null
            ? []
            : List<dynamic>.from(kitchens!.map((x) => x.toJson())),
      };
}
