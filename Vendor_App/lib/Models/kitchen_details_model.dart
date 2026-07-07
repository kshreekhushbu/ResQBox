class GetKitchenDetails {
  int? status;
  String? message;
  Kitchen? kitchen;

  GetKitchenDetails({this.status, this.message, this.kitchen});

  factory GetKitchenDetails.fromJson(Map<String, dynamic> json) =>
      GetKitchenDetails(
        status: json["status"],
        message: json["message"],
        kitchen: json["kitchen"] == null
            ? null
            : Kitchen.fromJson(json["kitchen"]),
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
  String? email;
  String? ownerName;
  String? contactNumber;
  String? openingTime;
  String? closingTime;
  String? description;
  String? status;
  int? isActive;
  String? rating;
  int? ratingCount;
  String? createdAt;
  String? deviceToken;
  Address? address;
  Kyc? kyc;
  Photos? photos;
  List<Item>? items;
  List<Review>? reviews;
  bool? stripeOnboardingCompleted;
  bool? stripeAccountConnected;
  String? stripeOnboardingUrl;
  String? stripeDashBoardUrl;
  int? notificationTime;
  int? timezoneId;
  List<FoodType>? foodtypes;

  Kitchen({
    this.kitchenId,
    this.kitchenName,
    this.email,
    this.ownerName,
    this.contactNumber,
    this.openingTime,
    this.closingTime,
    this.description,
    this.status,
    this.isActive,
    this.rating,
    this.ratingCount,
    this.createdAt,
    this.deviceToken,
    this.address,
    this.kyc,
    this.photos,
    this.items,
    this.reviews,
    this.stripeOnboardingCompleted,
    this.stripeAccountConnected,
    this.stripeOnboardingUrl,
    this.stripeDashBoardUrl,
    this.notificationTime,
    this.timezoneId,
    this.foodtypes,
  });

  factory Kitchen.fromJson(Map<String, dynamic> json) => Kitchen(
    kitchenId: json["kitchenId"],
    kitchenName: json["kitchenName"],
    email: json["email"],
    ownerName: json["ownerName"],
    contactNumber: json["contactNumber"],
    openingTime: json["openingTime"],
    closingTime: json["closingTime"],
    description: json["description"],
    status: json["status"],
    rating: json["rating"]?.toString(),
    isActive: json["isActive"],
    ratingCount: json["ratingCount"],
    createdAt: json["createdAt"],
    deviceToken: json["deviceToken"],
    address: json["address"] == null ? null : Address.fromJson(json["address"]),
    kyc: json["kyc"] == null ? null : Kyc.fromJson(json["kyc"]),
    photos: json["photos"] == null ? null : Photos.fromJson(json["photos"]),
    items: json["items"] == null
        ? []
        : List<Item>.from(json["items"]!.map((x) => Item.fromJson(x))),
    reviews: json["reviews"] == null
        ? []
        : List<Review>.from(json["reviews"]!.map((x) => Review.fromJson(x))),
    stripeOnboardingCompleted: json["stripeOnboardingCompleted"],
    stripeAccountConnected: json["stripeAccountConnected"],
    stripeOnboardingUrl: json["stripeOnboardingUrl"],
    stripeDashBoardUrl: json["stripeDashBoardUrl"],
    notificationTime: json["notificationTime"],
    timezoneId: json["timezoneId"],
    foodtypes: json["foodtypes"] == null
        ? []
        : List<FoodType>.from(
            json["foodtypes"]!.map((x) => FoodType.fromJson(x)),
          ),
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
    "isActive": isActive,
    "ratingCount": ratingCount,
    "createdAt": createdAt,
    "deviceToken": deviceToken,
    "address": address?.toJson(),
    "kyc": kyc?.toJson(),
    "photos": photos?.toJson(),
    "items": items == null
        ? []
        : List<dynamic>.from(items!.map((x) => x.toJson())),
    "reviews": reviews == null
        ? []
        : List<dynamic>.from(reviews!.map((x) => x.toJson())),
    "stripeOnboardingCompleted": stripeOnboardingCompleted,
    "stripeAccountConnected": stripeAccountConnected,
    "stripeOnboardingUrl": stripeOnboardingUrl,
    "stripeDashBoardUrl": stripeDashBoardUrl,
    "notificationTime": notificationTime,
    "timezoneId": timezoneId,
    "foodtypes": foodtypes == null
        ? []
        : List<dynamic>.from(foodtypes!.map((x) => x.toJson())),
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

class Item {
  int? id;
  String? name;
  String? quantity;
  int? price;
  String? description;
  bool? isVegetarian;
  dynamic isSpicy; // Can be string ("NORMAL", "MEDIUM", "EXTRA_SPICY") or bool
  String? rating;
  int? ratingCount;
  int? isActive;
  String? image;

  Item({
    this.id,
    this.name,
    this.quantity,
    this.price,
    this.description,
    this.isVegetarian,
    this.isSpicy,
    this.rating,
    this.ratingCount,
    this.isActive,
    this.image,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json["id"],
    name: json["name"],
    quantity: json["quantity"]?.toString(),
    price: json["price"],
    description: json["description"],
    isVegetarian: json["isVegetarian"],
    isSpicy: json["isSpicy"],
    rating: json["rating"]?.toString(),
    ratingCount: json["ratingCount"],
    isActive: json["isActive"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "quantity": quantity,
    "price": price,
    "description": description,
    "isVegetarian": isVegetarian,
    "isSpicy": isSpicy,
    "rating": rating,
    "ratingCount": ratingCount,
    "isActive": isActive,
    "image": image,
  };
}

class Kyc {
  String? abnNumber;
  String? acn;
  String? foodCertificateNumber;
  String? foodCertificateImage;
  String? expireDate;
  String? fssaiNumber;
  List<FoodCertificateImage>? foodCertificateImages;

  Kyc({
    this.abnNumber,
    this.acn,
    this.foodCertificateNumber,
    this.foodCertificateImage,
    this.expireDate,
    this.fssaiNumber,
    this.foodCertificateImages,
  });

  factory Kyc.fromJson(Map<String, dynamic> json) => Kyc(
    abnNumber: json["abnNumber"],
    acn: json["acn"],
    foodCertificateNumber: json["foodCertificateNumber"],
    foodCertificateImage: json["foodCertificateImage"],
    expireDate: json["expireDate"],
    fssaiNumber: json["fssaiNumber"],
    foodCertificateImages: json["foodCertificateImages"] == null
        ? []
        : List<FoodCertificateImage>.from(
            json["foodCertificateImages"]!.map(
              (x) => FoodCertificateImage.fromJson(x),
            ),
          ),
  );

  Map<String, dynamic> toJson() => {
    "abnNumber": abnNumber,
    "acn": acn,
    "foodCertificateNumber": foodCertificateNumber,
    "foodCertificateImage": foodCertificateImage,
    "expireDate": expireDate,
    "fssaiNumber": fssaiNumber,
    "foodCertificateImages": foodCertificateImages == null
        ? []
        : List<dynamic>.from(foodCertificateImages!.map((x) => x.toJson())),
  };
}

class Photos {
  List<String>? kitchenImages;
  String? kitchenProfilePhoto;
  String? chefProfilePhoto;

  Photos({this.kitchenImages, this.kitchenProfilePhoto, this.chefProfilePhoto});

  factory Photos.fromJson(Map<String, dynamic> json) => Photos(
    kitchenImages: json["kitchenImages"] == null
        ? []
        : List<String>.from(json["kitchenImages"]!.map((x) => x)),
    kitchenProfilePhoto: json["kitchenProfilePhoto"],
    chefProfilePhoto: json["chefProfilePhoto"],
  );

  Map<String, dynamic> toJson() => {
    "kitchenImages": kitchenImages == null
        ? []
        : List<dynamic>.from(kitchenImages!.map((x) => x)),
    "kitchenProfilePhoto": kitchenProfilePhoto,
    "chefProfilePhoto": chefProfilePhoto,
  };
}

class Review {
  int? id;
  int? orderId;
  String? rating;
  String? review;
  String? createdAt;
  ReviewUser? user;

  Review({
    this.id,
    this.orderId,
    this.rating,
    this.review,
    this.createdAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json["id"],
    orderId: json["orderId"],
    rating: json["rating"],
    review: json["review"],
    createdAt: json["createdAt"],
    user: json["user"] == null ? null : ReviewUser.fromJson(json["user"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "orderId": orderId,
    "rating": rating,
    "review": review,
    "createdAt": createdAt,
    "user": user?.toJson(),
  };
}

class ReviewUser {
  String? name;
  String? profilePicture;

  ReviewUser({this.name, this.profilePicture});

  factory ReviewUser.fromJson(Map<String, dynamic> json) =>
      ReviewUser(name: json["name"], profilePicture: json["profilePicture"]);

  Map<String, dynamic> toJson() => {
    "name": name,
    "profilePicture": profilePicture,
  };
}

class FoodType {
  int? id;
  String? name;
  String? image;
  int? isActive;

  FoodType({this.id, this.name, this.image, this.isActive});

  factory FoodType.fromJson(Map<String, dynamic> json) => FoodType(
    id: json["id"],
    name: json["name"],
    image: json["image"],
    isActive: json["isActive"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "image": image,
    "isActive": isActive,
  };
}

class FoodCertificateImage {
  String? image;
  String? expireDate;
  String? addedAt;

  FoodCertificateImage({this.image, this.expireDate, this.addedAt});

  factory FoodCertificateImage.fromJson(Map<String, dynamic> json) =>
      FoodCertificateImage(
        image: json["image"],
        expireDate: json["expireDate"],
        addedAt: json["addedAt"],
      );

  Map<String, dynamic> toJson() => {
    "image": image,
    "expireDate": expireDate,
    "addedAt": addedAt,
  };
}
