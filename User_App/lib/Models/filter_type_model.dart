// To parse this JSON data, do
//
//     final filterTypeModel = filterTypeModelFromJson(jsonString);

import 'dart:convert';

FilterTypeModel filterTypeModelFromJson(String str) =>
    FilterTypeModel.fromJson(json.decode(str));

String filterTypeModelToJson(FilterTypeModel data) =>
    json.encode(data.toJson());

class FilterTypeModel {
  int? status;
  String? message;
  List<FoodType>? kitchenFoodType;
  List<FoodType>? menuFoodType;

  FilterTypeModel({
    this.status,
    this.message,
    this.kitchenFoodType,
    this.menuFoodType,
  });

  factory FilterTypeModel.fromJson(Map<String, dynamic> json) =>
      FilterTypeModel(
        status: json["status"],
        message: json["message"],
        kitchenFoodType: json["kitchenFoodType"] == null
            ? []
            : List<FoodType>.from(
                json["kitchenFoodType"]!.map((x) => FoodType.fromJson(x))),
        menuFoodType: json["menuFoodType"] == null
            ? []
            : List<FoodType>.from(
                json["menuFoodType"]!.map((x) => FoodType.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "kitchenFoodType": kitchenFoodType == null
            ? []
            : List<dynamic>.from(kitchenFoodType!.map((x) => x.toJson())),
        "menuFoodType": menuFoodType == null
            ? []
            : List<dynamic>.from(menuFoodType!.map((x) => x.toJson())),
      };
}

class FoodType {
  int? id;
  String? name;
  String? image;
  String? question;
  String? type;

  FoodType({
    this.id,
    this.name,
    this.image,
    this.question,
    this.type,
  });

  factory FoodType.fromJson(Map<String, dynamic> json) => FoodType(
        id: json["id"],
        name: json["name"],
        image: json["image"],
        question: json["question"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "image": image,
        "question": question,
        "type": type,
      };
}
