// To parse this JSON data, do
//
//     final homeDataModel = homeDataModelFromJson(jsonString);

import 'dart:convert';
import 'dart:ffi';

HomeDataModel homeDataModelFromJson(String str) =>
    HomeDataModel.fromJson(json.decode(str));

String homeDataModelToJson(HomeDataModel data) => json.encode(data.toJson());

class HomeDataModel {
  int? status;
  String? message;
  List<Category>? categories;
  List<Category>? cuisines;
  List<ActiveRestaurantData>? wishlistKitchens;
  List<Product>? popularProducts;
  List<Product>? topRatedProducts;
  List<ActiveRestaurantData>? activeRestaurants;
  String? co2Message;
  String? discountMessage;

  HomeDataModel({
    this.status,
    this.message,
    this.categories,
    this.cuisines,
    this.wishlistKitchens,
    this.popularProducts,
    this.topRatedProducts,
    this.activeRestaurants,
    this.co2Message,
    this.discountMessage,
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) => HomeDataModel(
        status: json["status"],
        message: json["message"],
        categories: json["categories"] == null
            ? []
            : List<Category>.from(
                json["categories"]!.map((x) => Category.fromJson(x))),
        cuisines: json["cuisines"] == null
            ? []
            : List<Category>.from(
                json["cuisines"]!.map((x) => Category.fromJson(x))),
        wishlistKitchens: json["wishlistKitchens"] == null
            ? []
            : List<ActiveRestaurantData>.from(json["wishlistKitchens"]!
                .map((x) => ActiveRestaurantData.fromJson(x))),
        popularProducts: json["popularProducts"] == null
            ? []
            : List<Product>.from(
                json["popularProducts"]!.map((x) => Product.fromJson(x))),
        topRatedProducts: json["topRatedProducts"] == null
            ? []
            : List<Product>.from(
                json["topRatedProducts"]!.map((x) => Product.fromJson(x))),
        activeRestaurants: json["activeRestaurants"] == null
            ? []
            : List<ActiveRestaurantData>.from(json["activeRestaurants"]!
                .map((x) => ActiveRestaurantData.fromJson(x))),
        co2Message: json["co2Message"],
        discountMessage: json["discountMessage"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "categories": categories == null
            ? []
            : List<dynamic>.from(categories!.map((x) => x.toJson())),
        "cuisines": cuisines == null
            ? []
            : List<dynamic>.from(cuisines!.map((x) => x.toJson())),
        "wishlistKitchens": wishlistKitchens == null
            ? []
            : List<dynamic>.from(wishlistKitchens!.map((x) => x.toJson())),
        "popularProducts": popularProducts == null
            ? []
            : List<dynamic>.from(popularProducts!.map((x) => x.toJson())),
        "topRatedProducts": topRatedProducts == null
            ? []
            : List<dynamic>.from(topRatedProducts!.map((x) => x.toJson())),
        "activeRestaurants": activeRestaurants == null
            ? []
            : List<dynamic>.from(activeRestaurants!.map((x) => x.toJson())),
        "co2Message": co2Message,
        "discountMessage": discountMessage,
      };
}

class ActiveRestaurantData {
  int? kitchenId;
  String? kitchenName;
  String? email;
  String? ownerName;
  String? contactNumber;
  String? openingTime;
  String? closingTime;
  String? description;
  String? status;
  String? rating;
  int? ratingCount;
  int? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? isWishlist;
  double? discountPercentage;
  int? totalItemsQuantity;
  Address? address;
  ActiveRestaurantPhotos? photos;
  double? distanceKm;
  List<String>? cuisines;

  ActiveRestaurantData({
    this.kitchenId,
    this.kitchenName,
    this.email,
    this.ownerName,
    this.contactNumber,
    this.openingTime,
    this.closingTime,
    this.description,
    this.status,
    this.rating,
    this.ratingCount,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.isWishlist,
    this.discountPercentage,
    this.totalItemsQuantity,
    this.address,
    this.photos,
    this.distanceKm,
    this.cuisines,
  });

  factory ActiveRestaurantData.fromJson(Map<String, dynamic> json) =>
      ActiveRestaurantData(
        kitchenId: json["kitchenId"],
        kitchenName: json["kitchenName"],
        email: json["email"],
        ownerName: json["ownerName"],
        contactNumber: json["contactNumber"],
        openingTime: json["openingTime"],
        closingTime: json["closingTime"],
        description: json["description"],
        status: json["status"],
        rating: json["rating"],
        ratingCount: json["ratingCount"],
        isActive: json["isActive"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        isWishlist: json["isWishlist"],
        discountPercentage: json["discountPercentage"]?.toDouble(),
        totalItemsQuantity: json["totalItemsQuantity"],
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
        photos: json["photos"] == null
            ? null
            : ActiveRestaurantPhotos.fromJson(json["photos"]),
        distanceKm: json["distanceKm"]?.toDouble(),
        cuisines: json["cuisines"] == null
            ? []
            : List<String>.from(json["cuisines"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "kitchenId": kitchenId,
        "kitchenName": kitchenName,
        "email": email,
        "ownerName": ownerName,
        "contactNumber": contactNumber,
        "openingTime": openingTime,
        "closingTime": closingTime,
        "description": description,
        "status": status,
        "rating": rating,
        "ratingCount": ratingCount,
        "isActive": isActive,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "isWishlist": isWishlist,
        "discountPercentage": discountPercentage,
        "totalItemsQuantity": totalItemsQuantity,
        "address": address?.toJson(),
        "photos": photos?.toJson(),
        "distanceKm": distanceKm,
        "cuisines":
            cuisines == null ? [] : List<dynamic>.from(cuisines!.map((x) => x)),
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

class ActiveRestaurantPhotos {
  List<String>? kitchenImages;
  String? kitchenProfilePhoto;

  ActiveRestaurantPhotos({
    this.kitchenImages,
    this.kitchenProfilePhoto,
  });

  factory ActiveRestaurantPhotos.fromJson(Map<String, dynamic> json) =>
      ActiveRestaurantPhotos(
        kitchenImages: json["kitchenImages"] == null
            ? []
            : List<String>.from(json["kitchenImages"]!.map((x) => x)),
        kitchenProfilePhoto: json["kitchenProfilePhoto"],
      );

  Map<String, dynamic> toJson() => {
        "kitchenImages": kitchenImages == null
            ? []
            : List<dynamic>.from(kitchenImages!.map((x) => x)),
        "kitchenProfilePhoto": kitchenProfilePhoto,
      };
}

class Category {
  int? id;
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

class Product {
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
  double? ratingCount;
  String? startTime;
  String? endTime;
  Restaurant? restaurant;
  List<Category>? categories;
  List<Category>? foodtypeIds;
  Category? foodtype;

  Product({
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
    this.foodtypeIds,
    this.foodtype,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
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
        ratingCount: json["ratingCount"]?.toDouble(),
        startTime: json["startTime"],
        endTime: json["endTime"],
        restaurant: json["restaurant"] == null
            ? null
            : Restaurant.fromJson(json["restaurant"]),
        categories: json["categories"] == null
            ? []
            : List<Category>.from(
                json["categories"]!.map((x) => Category.fromJson(x))),
        foodtypeIds: json["foodtypeIds"] == null
            ? []
            : List<Category>.from(
                json["foodtypeIds"]!.map((x) => Category.fromJson(x))),
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
        "foodtypeIds": foodtypeIds == null
            ? []
            : List<dynamic>.from(foodtypeIds!.map((x) => x.toJson())),
        "foodtype": foodtype?.toJson(),
      };
}

class Restaurant {
  int? kitchenId;
  String? kitchenName;
  String? rating;
  int? ratingCount;
  double? distanceKm;
  RestaurantPhotos? photos;

  Restaurant({
    this.kitchenId,
    this.kitchenName,
    this.rating,
    this.ratingCount,
    this.distanceKm,
    this.photos,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        kitchenId: json["kitchenId"],
        kitchenName: json["kitchenName"],
        rating: json["rating"],
        ratingCount: json["ratingCount"],
        distanceKm: json["distanceKm"]?.toDouble(),
        photos: json["photos"] == null
            ? null
            : RestaurantPhotos.fromJson(json["photos"]),
      );

  Map<String, dynamic> toJson() => {
        "kitchenId": kitchenId,
        "kitchenName": kitchenName,
        "rating": rating,
        "ratingCount": ratingCount,
        "distanceKm": distanceKm,
        "photos": photos?.toJson(),
      };
}

class RestaurantPhotos {
  String? kitchenProfilePhoto;

  RestaurantPhotos({
    this.kitchenProfilePhoto,
  });

  factory RestaurantPhotos.fromJson(Map<String, dynamic> json) =>
      RestaurantPhotos(
        kitchenProfilePhoto: json["kitchenProfilePhoto"],
      );

  Map<String, dynamic> toJson() => {
        "kitchenProfilePhoto": kitchenProfilePhoto,
      };
}
