// To parse this JSON data, do
//
//     final categoryTabsModel = categoryTabsModelFromJson(jsonString);

import 'dart:convert';

CategoryTabsModel categoryTabsModelFromJson(String str) =>
    CategoryTabsModel.fromJson(json.decode(str));

String categoryTabsModelToJson(CategoryTabsModel data) =>
    json.encode(data.toJson());

class CategoryTabsModel {
  int? status;
  String? message;
  List<Category>? categories;

  CategoryTabsModel({
    this.status,
    this.message,
    this.categories,
  });

  factory CategoryTabsModel.fromJson(Map<String, dynamic> json) =>
      CategoryTabsModel(
        status: json["status"],
        message: json["message"],
        categories: json["categories"] == null
            ? []
            : List<Category>.from(
                json["categories"]!.map((x) => Category.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "categories": categories == null
            ? []
            : List<dynamic>.from(categories!.map((x) => x.toJson())),
      };
}

class Category {
  int? id;
  String? name;
  String? image;
  int? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  Category({
    this.id,
    this.name,
    this.image,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        image: json["image"],
        isActive: json["isActive"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "image": image,
        "isActive": isActive,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}
