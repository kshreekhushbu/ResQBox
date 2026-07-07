// To parse this JSON data, do
//
//     final activeRestaurentModel = activeRestaurentModelFromJson(jsonString);

import 'dart:convert';

import 'package:resqbox_user/Models/home_data_model.dart';

ActiveRestaurentModel activeRestaurentModelFromJson(String str) =>
    ActiveRestaurentModel.fromJson(json.decode(str));

String activeRestaurentModelToJson(ActiveRestaurentModel data) =>
    json.encode(data.toJson());

class ActiveRestaurentModel {
  int? status;
  String? message;
  List<ActiveRestaurantData>? data;

  ActiveRestaurentModel({
    this.status,
    this.message,
    this.data,
  });

  factory ActiveRestaurentModel.fromJson(Map<String, dynamic> json) =>
      ActiveRestaurentModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<ActiveRestaurantData>.from(
                json["data"]!.map((x) => ActiveRestaurantData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}
