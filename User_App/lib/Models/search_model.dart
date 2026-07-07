// To parse this JSON data, do
//
//     final searchModel = searchModelFromJson(jsonString);

import 'dart:convert';

import 'package:resqbox_user/Models/home_data_model.dart';

SearchModel searchModelFromJson(String str) =>
    SearchModel.fromJson(json.decode(str));

String searchModelToJson(SearchModel data) => json.encode(data.toJson());

class SearchModel {
  int? status;
  String? message;
  dynamic cuisineFilter;
  dynamic kitchenTypeFilter;
  dynamic foodtypeFilter;
  List<ActiveRestaurantData>? kitchens;
  List<Product>? menu;

  SearchModel({
    this.status,
    this.message,
    this.cuisineFilter,
    this.kitchenTypeFilter,
    this.foodtypeFilter,
    this.kitchens,
    this.menu,
  });

  factory SearchModel.fromJson(Map<String, dynamic> json) => SearchModel(
        status: json["status"],
        message: json["message"],
        cuisineFilter: json["cuisineFilter"],
        kitchenTypeFilter: json["kitchenTypeFilter"],
        foodtypeFilter: json["foodtypeFilter"],
        kitchens: json["kitchens"] == null
            ? []
            : List<ActiveRestaurantData>.from(
                json["kitchens"]!.map((x) => ActiveRestaurantData.fromJson(x))),
        menu: json["menu"] == null
            ? []
            : List<Product>.from(json["menu"]!.map((x) => Product.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "cuisineFilter": cuisineFilter,
        "kitchenTypeFilter": kitchenTypeFilter,
        "foodtypeFilter": foodtypeFilter,
        "kitchens": kitchens == null
            ? []
            : List<dynamic>.from(kitchens!.map((x) => x.toJson())),
      };
}
