// To parse this JSON data, do
//
//     final kitchenViewModel = kitchenViewModelFromJson(jsonString);

import 'dart:convert';

KitchenViewModel kitchenViewModelFromJson(String str) =>
    KitchenViewModel.fromJson(json.decode(str));

String kitchenViewModelToJson(KitchenViewModel data) =>
    json.encode(data.toJson());

class KitchenViewModel {
  int? status;
  String? message;
  Kitchen? kitchen;

  KitchenViewModel({
    this.status,
    this.message,
    this.kitchen,
  });

  factory KitchenViewModel.fromJson(Map<String, dynamic> json) =>
      KitchenViewModel(
        status: json["status"],
        message: json["message"],
        kitchen:
            json["kitchen"] == null ? null : Kitchen.fromJson(json["kitchen"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "kitchen": kitchen?.toJson(),
      };
}

class Kitchen {
  int? kitchenId;
  String? kitchenName;
  String? rating;
  int? ratingCount;
  double? distanceKm;
  double? discountPercentage;
  int? totalItemsQuantity;
  String? email;
  String? ownerName;
  String? contactNumber;
  String? openingTime;
  String? closingTime;
  String? description;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? status;
  int? isActive;
  dynamic rejectReason;
  List<String>? cuisines;
  Address? address;
  Kyc? kyc;
  Photos? photos;
  List<Review>? reviews;

  Kitchen({
    this.kitchenId,
    this.kitchenName,
    this.rating,
    this.ratingCount,
    this.distanceKm,
    this.discountPercentage,
    this.totalItemsQuantity,
    this.email,
    this.ownerName,
    this.contactNumber,
    this.openingTime,
    this.closingTime,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.isActive,
    this.rejectReason,
    this.cuisines,
    this.address,
    this.kyc,
    this.photos,
    this.reviews,
  });

  factory Kitchen.fromJson(Map<String, dynamic> json) => Kitchen(
        kitchenId: json["kitchenId"],
        kitchenName: json["kitchenName"],
        rating: json["rating"],
        ratingCount: json["ratingCount"],
        distanceKm: json["distanceKm"]?.toDouble(),
        discountPercentage: json["discountPercentage"]?.toDouble(),
        totalItemsQuantity: json["totalItemsQuantity"],
        email: json["email"],
        ownerName: json["ownerName"],
        contactNumber: json["contactNumber"],
        openingTime: json["openingTime"],
        closingTime: json["closingTime"],
        description: json["description"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        status: json["status"],
        isActive: json["isActive"],
        rejectReason: json["rejectReason"],
        cuisines: json["cuisines"] == null
            ? []
            : List<String>.from(json["cuisines"]!.map((x) => x)),
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
        kyc: json["kyc"] == null ? null : Kyc.fromJson(json["kyc"]),
        photos: json["photos"] == null ? null : Photos.fromJson(json["photos"]),
        reviews: json["reviews"] == null
            ? []
            : List<Review>.from(
                json["reviews"]!.map((x) => Review.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "kitchenId": kitchenId,
        "kitchenName": kitchenName,
        "rating": rating,
        "ratingCount": ratingCount,
        "distanceKm": distanceKm,
        "discountPercentage": discountPercentage,
        "totalItemsQuantity": totalItemsQuantity,
        "email": email,
        "ownerName": ownerName,
        "contactNumber": contactNumber,
        "openingTime": openingTime,
        "closingTime": closingTime,
        "description": description,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "status": status,
        "isActive": isActive,
        "rejectReason": rejectReason,
        "cuisines":
            cuisines == null ? [] : List<dynamic>.from(cuisines!.map((x) => x)),
        "address": address?.toJson(),
        "kyc": kyc?.toJson(),
        "photos": photos?.toJson(),
        "reviews": reviews == null
            ? []
            : List<dynamic>.from(reviews!.map((x) => x.toJson())),
      };
}

class Review {
  int? id;
  String? rating;
  String? review;
  DateTime? createdAt;
  User? user;

  Review({
    this.id,
    this.rating,
    this.review,
    this.createdAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json["id"],
        rating: json["rating"],
        review: json["review"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "rating": rating,
        "review": review,
        "createdAt": createdAt?.toIso8601String(),
        "user": user?.toJson(),
      };
}

class User {
  String? name;
  String? profilePicture;

  User({
    this.name,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        name: json["name"],
        profilePicture: json["profilePicture"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "profilePicture": profilePicture,
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

class Kyc {
  String? abnNumber;
  String? acn;
  String? foodCertificateNumber;
  String? foodCertificateImage;
  DateTime? expireDate;
  dynamic fssaiNumber;

  Kyc({
    this.abnNumber,
    this.acn,
    this.foodCertificateNumber,
    this.foodCertificateImage,
    this.expireDate,
    this.fssaiNumber,
  });

  factory Kyc.fromJson(Map<String, dynamic> json) => Kyc(
        abnNumber: json["abnNumber"],
        acn: json["acn"],
        foodCertificateNumber: json["foodCertificateNumber"],
        foodCertificateImage: json["foodCertificateImage"],
        expireDate: json["expireDate"] == null
            ? null
            : DateTime.parse(json["expireDate"]),
        fssaiNumber: json["fssaiNumber"],
      );

  Map<String, dynamic> toJson() => {
        "abnNumber": abnNumber,
        "acn": acn,
        "foodCertificateNumber": foodCertificateNumber,
        "foodCertificateImage": foodCertificateImage,
        "expireDate": expireDate?.toIso8601String(),
        "fssaiNumber": fssaiNumber,
      };
}

class Photos {
  List<String>? kitchenImages;
  String? kitchenProfilePhoto;

  Photos({
    this.kitchenImages,
    this.kitchenProfilePhoto,
  });

  factory Photos.fromJson(Map<String, dynamic> json) => Photos(
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
