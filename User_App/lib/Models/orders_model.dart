// To parse this JSON data, do
//
//     final ordersModel = ordersModelFromJson(jsonString);

import 'dart:convert';

import 'package:resqbox_user/Models/order_details_model.dart';

OrdersModel ordersModelFromJson(String str) =>
    OrdersModel.fromJson(json.decode(str));

String ordersModelToJson(OrdersModel data) => json.encode(data.toJson());

class OrdersModel {
  int? status;
  String? message;
  List<OrdersData>? orders;

  OrdersModel({
    this.status,
    this.message,
    this.orders,
  });

  factory OrdersModel.fromJson(Map<String, dynamic> json) => OrdersModel(
        status: json["status"],
        message: json["message"],
        orders: json["orders"] == null
            ? []
            : List<OrdersData>.from(
                json["orders"]!.map((x) => OrdersData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "orders": orders == null
            ? []
            : List<dynamic>.from(orders!.map((x) => x.toJson())),
      };
}

class OrdersData {
  int? orderId;
  String? rating;
  String? orderDisplayId;
  String? title;
  List<Item>? items;
  String? restaurantName;
  String? kitchenImage;
  Address? address;
  double? amount;
  String? status;
  DateTime? orderedAt;
  OrderInvoice? orderInvoice;

  OrdersData({
    this.orderId,
    this.rating,
    this.orderDisplayId,
    this.title,
    this.items,
    this.restaurantName,
    this.kitchenImage,
    this.address,
    this.amount,
    this.status,
    this.orderedAt,
    this.orderInvoice,
  });

  factory OrdersData.fromJson(Map<String, dynamic> json) => OrdersData(
        orderId: json["orderId"],
        rating: json["rating"],
        orderDisplayId: json["orderDisplayId"] ?? '',
        title: json["title"],
        items: json["items"] == null
            ? []
            : List<Item>.from(json["items"]!.map((x) => Item.fromJson(x))),
        restaurantName: json["restaurantName"],
        kitchenImage: json["kitchenImage"],
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
        amount: json["amount"]?.toDouble(),
        status: json["status"],
        orderedAt: json["orderedAt"] == null
            ? null
            : DateTime.parse(json["orderedAt"]),
        orderInvoice: json["invoice"] == null
            ? null
            : OrderInvoice.fromJson(json["invoice"]),
      );

  Map<String, dynamic> toJson() => {
        "orderId": orderId,
        "rating": rating,
        "orderDisplayId": orderDisplayId,
        "title": title,
        "items": items == null
            ? []
            : List<dynamic>.from(items!.map((x) => x.toJson())),
        "restaurantName": restaurantName,
        "kitchenImage": kitchenImage,
        "address": address?.toJson(),
        "amount": amount,
        "status": status,
        "orderedAt": orderedAt?.toIso8601String(),
        "invoice": orderInvoice?.toJson(),
      };
}

class Address {
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

class Item {
  int? menuItemId;
  String? name;
  int? quantity;
  String? image;

  Item({
    this.menuItemId,
    this.name,
    this.quantity,
    this.image,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        menuItemId: json["menuItemId"],
        name: json["name"],
        quantity: json["quantity"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "menuItemId": menuItemId,
        "name": name,
        "quantity": quantity,
        "image": image,
      };
}
