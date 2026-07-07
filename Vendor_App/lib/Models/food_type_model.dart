class FoodType {
  int? id;
  String? name;
  String? image;
  int? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  FoodType({
    this.id,
    this.name,
    this.image,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory FoodType.fromJson(Map<String, dynamic> json) => FoodType(
    id: json["id"],
    name: json["name"],
    image: json["image"],
    isActive: json["isActive"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "image": image,
    "isActive": isActive,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodType && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class GetFoodTypes {
  int? status;
  List<FoodType>? foodTypes;

  GetFoodTypes({this.status, this.foodTypes});

  factory GetFoodTypes.fromJson(Map<String, dynamic> json) => GetFoodTypes(
    status: json["status"],
    foodTypes: json["foodTypes"] == null
        ? []
        : List<FoodType>.from(
            json["foodTypes"]!.map((x) => FoodType.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "foodTypes": foodTypes == null
        ? []
        : List<dynamic>.from(foodTypes!.map((x) => x.toJson())),
  };
}

class GetMenuTypes {
  int? status;
  List<FoodType>? menuTypes;

  GetMenuTypes({this.status, this.menuTypes});

  factory GetMenuTypes.fromJson(Map<String, dynamic> json) => GetMenuTypes(
    status: json["status"],
    menuTypes: json["menuTypes"] == null
        ? []
        : List<FoodType>.from(
            json["menuTypes"]!.map((x) => FoodType.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "menuTypes": menuTypes == null
        ? []
        : List<dynamic>.from(menuTypes!.map((x) => x.toJson())),
  };
}
