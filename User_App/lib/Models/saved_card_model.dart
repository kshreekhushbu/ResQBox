// To parse this JSON data, do
//
//     final savedCardModel = savedCardModelFromJson(jsonString);

import 'dart:convert';

SavedCardModel savedCardModelFromJson(String str) =>
    SavedCardModel.fromJson(json.decode(str));

String savedCardModelToJson(SavedCardModel data) => json.encode(data.toJson());

class SavedCardModel {
  int? status;
  String? message;
  List<PaymentMethodData>? data;

  SavedCardModel({
    this.status,
    this.message,
    this.data,
  });

  factory SavedCardModel.fromJson(Map<String, dynamic> json) => SavedCardModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<PaymentMethodData>.from(
                json["data"]!.map((x) => PaymentMethodData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class PaymentMethodData {
  int? cardId;
  String? paymentMethodId;
  String? cardBrand;
  String? cardLast4;
  int? cardExpMonth;
  int? cardExpYear;
  dynamic cardHolderName;
  bool? isDefault;
  DateTime? createdAt;

  PaymentMethodData({
    this.cardId,
    this.paymentMethodId,
    this.cardBrand,
    this.cardLast4,
    this.cardExpMonth,
    this.cardExpYear,
    this.cardHolderName,
    this.isDefault,
    this.createdAt,
  });

  factory PaymentMethodData.fromJson(Map<String, dynamic> json) =>
      PaymentMethodData(
        cardId: json["cardId"],
        paymentMethodId: json["paymentMethodId"],
        cardBrand: json["cardBrand"],
        cardLast4: json["cardLast4"],
        cardExpMonth: json["cardExpMonth"],
        cardExpYear: json["cardExpYear"],
        cardHolderName: json["cardHolderName"],
        isDefault: json["isDefault"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
      );

  Map<String, dynamic> toJson() => {
        "cardId": cardId,
        "paymentMethodId": paymentMethodId,
        "cardBrand": cardBrand,
        "cardLast4": cardLast4,
        "cardExpMonth": cardExpMonth,
        "cardExpYear": cardExpYear,
        "cardHolderName": cardHolderName,
        "isDefault": isDefault,
        "createdAt": createdAt?.toIso8601String(),
      };
}
