// To parse this JSON data, do
//
//     final menuViewModel = menuViewModelFromJson(jsonString);

import 'dart:convert';

import 'package:resqbox_user/Models/home_data_model.dart';

MenuViewModel menuViewModelFromJson(String str) =>
    MenuViewModel.fromJson(json.decode(str));

String menuViewModelToJson(MenuViewModel data) => json.encode(data.toJson());

class MenuViewModel {
  int? status;
  String? message;
  Item? menuItem;
  List<Product>? recommendedItems;

  MenuViewModel({
    this.status,
    this.message,
    this.menuItem,
    this.recommendedItems,
  });

  factory MenuViewModel.fromJson(Map<String, dynamic> json) => MenuViewModel(
        status: json["status"],
        message: json["message"],
        menuItem:
            json["menuItem"] == null ? null : Item.fromJson(json["menuItem"]),
        recommendedItems: json["recommendedItems"] == null
            ? []
            : List<Product>.from(
                json["recommendedItems"]!.map((x) => Product.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "menuItem": menuItem?.toJson(),
        "recommendedItems": recommendedItems == null
            ? []
            : List<dynamic>.from(recommendedItems!.map((x) => x.toJson())),
      };
}

class Item {
  int? id;
  String? name;
  int? quantity;
  double? price;
  double? discountPrice;
  double? discountPercentage;
  String? description;
  String? image;
  bool? isVegetarian;
  String? isSpicy;
  String? rating;
  int? ratingCount;
  String? startTime;
  String? endTime;
  Restaurant? restaurant;
  List<Category>? categories;
  Kitchen? kitchen;
  Category? foodtype;

  Item({
    this.id,
    this.name,
    this.quantity,
    this.price,
    this.discountPrice,
    this.discountPercentage,
    this.description,
    this.image,
    this.isVegetarian,
    this.isSpicy,
    this.rating,
    this.ratingCount,
    this.startTime,
    this.endTime,
    this.restaurant,
    this.categories,
    this.kitchen,
    this.foodtype,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json["id"],
        name: json["name"],
        quantity: json["quantity"],
        price: json["price"]?.toDouble(),
        discountPrice: json["discountPrice"]?.toDouble(),
        discountPercentage: json["discountPercentage"]?.toDouble(),
        description: json["description"],
        image: json["image"],
        isVegetarian: json["isVegetarian"],
        isSpicy: json["isSpicy"],
        rating: json["rating"],
        ratingCount: json["ratingCount"],
        startTime: json["startTime"],
        endTime: json["endTime"],
        restaurant: json["restaurant"] == null
            ? null
            : Restaurant.fromJson(json["restaurant"]),
        categories: json["categories"] == null
            ? []
            : List<Category>.from(
                json["categories"]!.map((x) => Category.fromJson(x))),
        kitchen:
            json["kitchen"] == null ? null : Kitchen.fromJson(json["kitchen"]),
        foodtype: json["foodtype"] == null
            ? null
            : Category.fromJson(json["foodtype"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "quantity": quantity,
        "price": price,
        "discountPrice": discountPrice,
        "discountPercentage": discountPercentage,
        "description": description,
        "image": image,
        "isVegetarian": isVegetarian,
        "isSpicy": isSpicy,
        "rating": rating,
        "ratingCount": ratingCount,
        "startTime": startTime,
        "endTime": endTime,
        "restaurant": restaurant?.toJson(),
        "categories": categories == null
            ? []
            : List<dynamic>.from(categories!.map((x) => x.toJson())),
        "kitchen": kitchen?.toJson(),
        "foodtype": foodtype?.toJson()
      };
}

class Category {
  dynamic id;
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
  dynamic kitchenId;
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

class Restaurant {
  dynamic kitchenId;
  String? kitchenName;
  String? rating;
  int? ratingCount;
  double? distanceKm;
  Address? address;
  Photos? photos;

  Restaurant({
    this.kitchenId,
    this.kitchenName,
    this.rating,
    this.ratingCount,
    this.distanceKm,
    this.address,
    this.photos,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        kitchenId: json["kitchenId"],
        kitchenName: json["kitchenName"],
        rating: json["rating"],
        ratingCount: json["ratingCount"],
        distanceKm: json["distanceKm"]?.toDouble(),
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
        photos: json["photos"] == null ? null : Photos.fromJson(json["photos"]),
      );

  Map<String, dynamic> toJson() => {
        "kitchenId": kitchenId,
        "kitchenName": kitchenName,
        "rating": rating,
        "ratingCount": ratingCount,
        "distanceKm": distanceKm,
        "address": address?.toJson(),
        "photos": photos?.toJson(),
      };
}

class Address {
  String? houseNo;
  String? street;
  String? city;
  String? state;
  String? country;
  String? pincode;
  double? latitude;
  double? longitude;

  Address({
    this.houseNo,
    this.street,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        houseNo: json["houseNo"],
        street: json["street"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        pincode: json["pincode"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "houseNo": houseNo,
        "street": street,
        "city": city,
        "state": state,
        "country": country,
        "pincode": pincode,
        "latitude": latitude,
        "longitude": longitude,
      };
}

class Photos {
  String? kitchenProfilePhoto;
  List<String>? kitchenImages;

  Photos({
    this.kitchenProfilePhoto,
    this.kitchenImages,
  });

  factory Photos.fromJson(Map<String, dynamic> json) => Photos(
        kitchenProfilePhoto: json["kitchenProfilePhoto"],
        kitchenImages: json["kitchenImages"] == null
            ? []
            : List<String>.from(json["kitchenImages"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "kitchenProfilePhoto": kitchenProfilePhoto,
        "kitchenImages": kitchenImages == null
            ? []
            : List<dynamic>.from(kitchenImages!.map((x) => x)),
      };
}
