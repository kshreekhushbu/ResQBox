// To parse this JSON data, do
//
//     final orderSuccessModel = orderSuccessModelFromJson(jsonString);

import 'dart:convert';

OrderSuccessModel orderSuccessModelFromJson(String str) =>
    OrderSuccessModel.fromJson(json.decode(str));

String orderSuccessModelToJson(OrderSuccessModel data) =>
    json.encode(data.toJson());

class OrderSuccessModel {
  int? status;
  String? message;
  String? clientSecret;
  OrderDetails? orderDetails;

  OrderSuccessModel({
    this.status,
    this.message,
    this.clientSecret,
    this.orderDetails,
  });

  factory OrderSuccessModel.fromJson(Map<String, dynamic> json) =>
      OrderSuccessModel(
        status: json["status"],
        message: json["message"],
        clientSecret: json["clientSecret"],
        orderDetails: json["orderDetails"] == null
            ? null
            : OrderDetails.fromJson(json["orderDetails"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "clientSecret": clientSecret,
        "orderDetails": orderDetails?.toJson(),
      };
}

class OrderDetails {
  int? orderId;
  String? orderDisplayId;
  String? pickupId;
  int? kitchenId;
  List<Item>? items;
  String? pickupStartTime;
  String? pickupEndTime;
  double? totalPaid;
  double? discount;
  DateTime? orderedAt;
  Timezone? timezone;

  OrderDetails({
    this.orderId,
    this.orderDisplayId,
    this.pickupId,
    this.kitchenId,
    this.items,
    this.pickupStartTime,
    this.pickupEndTime,
    this.totalPaid,
    this.discount,
    this.orderedAt,
    this.timezone,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) => OrderDetails(
        orderId: json["orderId"],
        orderDisplayId: json["orderDisplayId"],
        pickupId: json["pickupId"],
        kitchenId: json["kitchenId"],
        items: json["items"] == null
            ? []
            : List<Item>.from(json["items"]!.map((x) => Item.fromJson(x))),
        pickupStartTime: json["pickupStartTime"],
        pickupEndTime: json["pickupEndTime"],
        totalPaid: json["totalPaid"]?.toDouble(),
        discount: json["discount"]?.toDouble(),
        orderedAt: json["orderedAt"] == null
            ? null
            : DateTime.parse(json["orderedAt"]),
        timezone: json["timezone"] == null
            ? null
            : Timezone.fromJson(json["timezone"]),
      );

  Map<String, dynamic> toJson() => {
        "orderId": orderId,
        "orderDisplayId": orderDisplayId,
        "pickupId": pickupId,
        "kitchenId": kitchenId,
        "items": items == null
            ? []
            : List<dynamic>.from(items!.map((x) => x.toJson())),
        "pickupStartTime": pickupStartTime,
        "pickupEndTime": pickupEndTime,
        "totalPaid": totalPaid,
        "discount": discount,
        "orderedAt": orderedAt?.toIso8601String(),
        "timezone": timezone?.toJson()
      };
}

class Item {
  String? name;
  int? quantity;
  String? startTime;
  String? endTime;
  int? kitchenId;
  String? kitchenName;
  Address? address;

  Item({
    this.name,
    this.quantity,
    this.startTime,
    this.endTime,
    this.kitchenId,
    this.kitchenName,
    this.address,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        name: json["name"],
        quantity: json["quantity"],
        startTime: json["startTime"],
        endTime: json["endTime"],
        kitchenId: json["kitchenId"],
        kitchenName: json["kitchenName"],
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "quantity": quantity,
        "startTime": startTime,
        "endTime": endTime,
        "kitchenId": kitchenId,
        "kitchenName": kitchenName,
        "address": address?.toJson(),
      };
}

class Address {
  int? addressId;
  int? kitchenId;
  String? houseNo;
  String? street;
  String? pincode;
  String? state;
  String? city;
  String? country;
  String? landmark;
  double? latitude;
  double? longitude;

  Address({
    this.addressId,
    this.kitchenId,
    this.houseNo,
    this.street,
    this.pincode,
    this.state,
    this.city,
    this.country,
    this.landmark,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json["addressId"],
        kitchenId: json["kitchenId"],
        houseNo: json["houseNo"],
        street: json["street"],
        pincode: json["pincode"],
        state: json["state"],
        city: json["city"],
        country: json["country"],
        landmark: json["landmark"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "addressId": addressId,
        "kitchenId": kitchenId,
        "houseNo": houseNo,
        "street": street,
        "pincode": pincode,
        "state": state,
        "city": city,
        "country": country,
        "landmark": landmark,
        "latitude": latitude,
        "longitude": longitude,
      };
}

class Timezone {
  int? id;
  String? name;
  String? displayName;
  String? offset;

  Timezone({
    this.id,
    this.name,
    this.displayName,
    this.offset,
  });

  factory Timezone.fromJson(Map<String, dynamic> json) => Timezone(
        id: json["id"],
        name: json["name"],
        displayName: json["displayName"],
        offset: json["offset"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "displayName": displayName,
        "offset": offset,
      };
}
