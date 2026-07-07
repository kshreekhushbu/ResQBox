class MenuItem {
  int? id;
  int? kitchenId;
  String? name;
  int? categoryId;
  int? cuisineId;
  int? foodtypeId;
  String? quantity;
  double? price;
  double? discountPrice;
  double? discountPercentage;
  String? description;
  String? image;
  bool? isVegetarian;
  dynamic isSpicy;
  String? startTime;
  String? endTime;
  String? startTimeDate;
  String? endTimeDate;
  int? isActive;
  String? createdAt;
  String? updatedAt;
  String? rating;
  int? ratingCount;
  CategoryInfo? category;
  CuisineInfo? cuisine;
  FoodTypeInfo? foodtype;
  List<CategoryInfo>? categoryIds;
  List<FoodTypeInfo>? menuTypes;

  MenuItem({
    this.id,
    this.kitchenId,
    this.name,
    this.categoryId,
    this.cuisineId,
    this.foodtypeId,
    this.quantity,
    this.price,
    this.discountPrice,
    this.discountPercentage,
    this.description,
    this.image,
    this.isVegetarian,
    this.isSpicy,
    this.startTime,
    this.endTime,
    this.startTimeDate,
    this.endTimeDate,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.rating,
    this.ratingCount,
    this.category,
    this.cuisine,
    this.foodtype,
    this.categoryIds,
    this.menuTypes,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json["id"],
    kitchenId: json["kitchenId"],
    name: json["name"],
    categoryId: json["categoryId"],
    cuisineId: json["cuisineId"],
    foodtypeId: json["foodtypeId"],
    quantity: json["quantity"]?.toString(),
    price: json["price"]?.toDouble(),
    discountPrice: json["discountPrice"]?.toDouble(),
    discountPercentage: json["discountPercentage"]?.toDouble(),
    description: json["description"],
    image: json["image"],
    isVegetarian: json["isVegetarian"],
    isSpicy: json["isSpicy"],
    startTime: json["startTime"],
    endTime: json["endTime"],
    startTimeDate: json["startTimeDate"],
    endTimeDate: json["endTimeDate"],
    isActive: json["isActive"],
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
    rating: json["rating"],
    ratingCount: json["ratingCount"],
    category: json["category"] == null
        ? null
        : CategoryInfo.fromJson(json["category"]),
    cuisine: json["cuisine"] == null
        ? null
        : CuisineInfo.fromJson(json["cuisine"]),
    foodtype: json["foodtype"] == null
        ? null
        : FoodTypeInfo.fromJson(json["foodtype"]),
    categoryIds: json["categoryIds"] == null
        ? []
        : List<CategoryInfo>.from(
            json["categoryIds"]!.map((x) => CategoryInfo.fromJson(x)),
          ),
    menuTypes: json["foodtypeIds"] == null
        ? []
        : List<FoodTypeInfo>.from(
            json["foodtypeIds"]!.map((x) => FoodTypeInfo.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "kitchenId": kitchenId,
    "name": name,
    "categoryId": categoryId,
    "cuisineId": cuisineId,
    "foodtypeId": foodtypeId,
    "quantity": quantity,
    "price": price,
    "discountPrice": discountPrice,
    "discountPercentage": discountPercentage,
    "description": description,
    "image": image,
    "isVegetarian": isVegetarian,
    "isSpicy": isSpicy,
    "startTime": startTime,
    "endTime": endTime,
    "startTimeDate": startTimeDate,
    "endTimeDate": endTimeDate,
    "isActive": isActive,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "rating": rating,
    "ratingCount": ratingCount,
    "category": category?.toJson(),
    "cuisine": cuisine?.toJson(),
    "foodtype": foodtype?.toJson(),
    "categoryIds": categoryIds == null
        ? []
        : List<dynamic>.from(categoryIds!.map((x) => x.toJson())),
    "menuTypes": menuTypes == null
        ? []
        : List<dynamic>.from(menuTypes!.map((x) => x.toJson())),
  };
}

class CategoryInfo {
  int? id;
  String? name;

  CategoryInfo({this.id, this.name});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) =>
      CategoryInfo(id: json["id"], name: json["name"]);

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class CuisineInfo {
  int? id;
  String? name;

  CuisineInfo({this.id, this.name});

  factory CuisineInfo.fromJson(Map<String, dynamic> json) =>
      CuisineInfo(id: json["id"], name: json["name"]);

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class FoodTypeInfo {
  int? id;
  String? name;
  String? image;

  FoodTypeInfo({this.id, this.name, this.image});

  factory FoodTypeInfo.fromJson(Map<String, dynamic> json) =>
      FoodTypeInfo(id: json["id"], name: json["name"], image: json["image"]);

  Map<String, dynamic> toJson() => {"id": id, "name": name, "image": image};
}

class GetMenuItems {
  int? status;
  String? message;
  List<MenuItem>? menuItems;

  GetMenuItems({this.status, this.message, this.menuItems});

  factory GetMenuItems.fromJson(Map<String, dynamic> json) => GetMenuItems(
    status: json["status"],
    message: json["message"],
    menuItems: json["menuItems"] == null
        ? []
        : List<MenuItem>.from(
            json["menuItems"]!.map((x) => MenuItem.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "menuItems": menuItems == null
        ? []
        : List<dynamic>.from(menuItems!.map((x) => x.toJson())),
  };
}
