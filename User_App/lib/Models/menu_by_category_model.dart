// To parse this JSON data, do
//
//     final menuByCategoryModel = menuByCategoryModelFromJson(jsonString);

import 'dart:convert';

import 'package:resqbox_user/Models/home_data_model.dart';

MenuByCategoryModel menuByCategoryModelFromJson(String str) =>
    MenuByCategoryModel.fromJson(json.decode(str));

String menuByCategoryModelToJson(MenuByCategoryModel data) =>
    json.encode(data.toJson());

class MenuByCategoryModel {
  int? status;
  String? message;
  dynamic kitchenId;
  dynamic categoryId;
  dynamic foodtypeId;
  dynamic kitchenTypeId;
  List<Product>? menuItems;

  MenuByCategoryModel({
    this.status,
    this.message,
    this.kitchenId,
    this.categoryId,
    this.foodtypeId,
    this.kitchenTypeId,
    this.menuItems,
  });

  factory MenuByCategoryModel.fromJson(Map<String, dynamic> json) =>
      MenuByCategoryModel(
        status: json["status"],
        message: json["message"],
        kitchenId: json["kitchenId"],
        categoryId: json["categoryId"],
        foodtypeId: json["foodtypeId"],
        kitchenTypeId: json["kitchenTypeId"],
        menuItems: json["menuItems"] == null
            ? []
            : List<Product>.from(
                json["menuItems"]!.map((x) => Product.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "kitchenId": kitchenId,
        "categoryId": categoryId,
        "foodtypeId": foodtypeId,
        "kitchenTypeId": kitchenTypeId,
        "menuItems": menuItems == null
            ? []
            : List<dynamic>.from(menuItems!.map((x) => x.toJson())),
      };
}

class Category {
  int? id;
  String? name;
  String? image;

  Category({
    this.id,
    this.name,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "image": image,
      };
}

class Kitchen {
  int? kitchenId;
  String? kitchenName;

  Kitchen({
    this.kitchenId,
    this.kitchenName,
  });

  factory Kitchen.fromJson(Map<String, dynamic> json) => Kitchen(
        kitchenId: json["kitchenId"],
        kitchenName: json["kitchenName"],
      );

  Map<String, dynamic> toJson() => {
        "kitchenId": kitchenId,
        "kitchenName": kitchenName,
      };
}
