// To parse this JSON data, do
//
//     final userDetailsModel = userDetailsModelFromJson(jsonString);

import 'dart:convert';

UserDetailsModel userDetailsModelFromJson(String str) =>
    UserDetailsModel.fromJson(json.decode(str));

String userDetailsModelToJson(UserDetailsModel data) =>
    json.encode(data.toJson());

class UserDetailsModel {
  int? status;
  String? message;
  User? user;
  String? co2Message;
  String? discountMessage;

  UserDetailsModel({
    this.status,
    this.message,
    this.user,
    this.co2Message,
    this.discountMessage,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) =>
      UserDetailsModel(
        status: json["status"],
        message: json["message"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        co2Message: json["co2Message"],
        discountMessage: json["discountMessage"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "user": user?.toJson(),
        "co2Message": co2Message,
        "discountMessage": discountMessage,
      };
}

class User {
  int? userId;
  String? name;
  String? lastName;
  String? phoneNumber;
  String? email;
  dynamic profilePicture;
  String? deviceToken;
  String? countryCode;

  User({
    this.userId,
    this.name,
    this.lastName,
    this.phoneNumber,
    this.email,
    this.profilePicture,
    this.deviceToken,
    this.countryCode,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json["userId"],
        name: json["name"],
        lastName: json["lastName"],
        phoneNumber: json["phoneNumber"],
        email: json["email"],
        profilePicture: json["profilePicture"],
        deviceToken: json["deviceToken"],
        countryCode: json["countryCode"],
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "name": name,
        "lastName": lastName,
        "phoneNumber": phoneNumber,
        "email": email,
        "profilePicture": profilePicture,
        "deviceToken": deviceToken,
        "countryCode": countryCode,
      };
}
