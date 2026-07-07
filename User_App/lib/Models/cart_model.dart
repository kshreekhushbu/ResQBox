// To parse this JSON data, do
//
//     final cartModel = cartModelFromJson(jsonString);

import 'dart:convert';

CartModel cartModelFromJson(String str) => CartModel.fromJson(json.decode(str));

String cartModelToJson(CartModel data) => json.encode(data.toJson());

class CartModel {
  int? status;
  List<CartItem>? cartItems;
  Kitchen? kitchen;
  PriceDetails? priceDetails;

  CartModel({
    this.status,
    this.cartItems,
    this.kitchen,
    this.priceDetails,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) => CartModel(
        status: json["status"],
        cartItems: json["cartItems"] == null
            ? []
            : List<CartItem>.from(
                json["cartItems"]!.map((x) => CartItem.fromJson(x))),
        kitchen:
            json["kitchen"] == null ? null : Kitchen.fromJson(json["kitchen"]),
        priceDetails: json["priceDetails"] == null
            ? null
            : PriceDetails.fromJson(json["priceDetails"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "cartItems": cartItems == null
            ? []
            : List<dynamic>.from(cartItems!.map((x) => x.toJson())),
        "kitchen": kitchen?.toJson(),
        "priceDetails": priceDetails?.toJson(),
      };
}

class CartItem {
  int? cartItemId;
  int? menuItemId;
  String? name;
  int? quantity;
  double? actualPrice;
  double? discountPrice;
  String? image;

  CartItem({
    this.cartItemId,
    this.menuItemId,
    this.name,
    this.quantity,
    this.actualPrice,
    this.discountPrice,
    this.image,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        cartItemId: json["cartItemId"],
        menuItemId: json["menuItemId"],
        name: json["name"],
        quantity: json["quantity"],
        actualPrice: json["actualPrice"]?.toDouble(),
        discountPrice: json["discountPrice"]?.toDouble(),
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "cartItemId": cartItemId,
        "menuItemId": menuItemId,
        "name": name,
        "quantity": quantity,
        "actualPrice": actualPrice,
        "discountPrice": discountPrice,
        "image": image,
      };
}

class Kitchen {
  int? kitchenId;
  String? kitchenName;
  String? kitchenProfilePhoto;
  Address? address;

  Kitchen({
    this.kitchenId,
    this.kitchenName,
    this.kitchenProfilePhoto,
    this.address,
  });

  factory Kitchen.fromJson(Map<String, dynamic> json) => Kitchen(
        kitchenId: json["kitchenId"],
        kitchenName: json["kitchenName"],
        kitchenProfilePhoto: json["kitchenProfilePhoto"],
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
      );

  Map<String, dynamic> toJson() => {
        "kitchenId": kitchenId,
        "kitchenName": kitchenName,
        "kitchenProfilePhoto": kitchenProfilePhoto,
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

class PriceDetails {
  int? totalItems;
  double? itemTotal;
  double? taxPercent;
  double? taxAmount;
  double? platformFee;
  double? totalAmount;

  PriceDetails({
    this.totalItems,
    this.itemTotal,
    this.taxPercent,
    this.taxAmount,
    this.platformFee,
    this.totalAmount,
  });

  factory PriceDetails.fromJson(Map<String, dynamic> json) => PriceDetails(
        totalItems: json["totalItems"],
        itemTotal: json["itemTotal"]?.toDouble(),
        taxPercent: json["taxPercent"]?.toDouble(),
        taxAmount: json["taxAmount"]?.toDouble(),
        platformFee: json["platformFee"]?.toDouble(),
        totalAmount: json["totalAmount"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "totalItems": totalItems,
        "itemTotal": itemTotal,
        "taxPercent": taxPercent,
        "taxAmount": taxAmount,
        "platformFee": platformFee,
        "totalAmount": totalAmount,
      };
}
