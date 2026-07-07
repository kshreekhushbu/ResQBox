// To parse this JSON data, do
//
//     final wishlistModel = wishlistModelFromJson(jsonString);

import 'dart:convert';

import 'package:resqbox_user/Models/home_data_model.dart';

WishlistModel wishlistModelFromJson(String str) =>
    WishlistModel.fromJson(json.decode(str));

String wishlistModelToJson(WishlistModel data) => json.encode(data.toJson());

class WishlistModel {
  int? status;
  String? message;
  List<ActiveRestaurantData>? kitchens;

  WishlistModel({
    this.status,
    this.message,
    this.kitchens,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) => WishlistModel(
        status: json["status"],
        message: json["message"],
        kitchens: json["kitchens"] == null
            ? []
            : List<ActiveRestaurantData>.from(
                json["kitchens"]!.map((x) => ActiveRestaurantData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "kitchens": kitchens == null
            ? []
            : List<dynamic>.from(kitchens!.map((x) => x.toJson())),
      };
}
