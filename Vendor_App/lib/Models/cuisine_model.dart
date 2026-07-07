class Cuisine {
  int? id;
  String? name;
  int? isActive;
  String? image;
  DateTime? createdAt;
  DateTime? updatedAt;

  Cuisine({
    this.id,
    this.name,
    this.isActive,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) => Cuisine(
        id: json["id"],
        name: json["name"],
        isActive: json["isActive"],
        image: json["image"],
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
        "isActive": isActive,
        "image": image,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cuisine &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class GetCuisines {
  int? status;
  List<Cuisine>? cuisines;

  GetCuisines({
    this.status,
    this.cuisines,
  });

  factory GetCuisines.fromJson(Map<String, dynamic> json) => GetCuisines(
        status: json["status"],
        cuisines: json["cuisines"] == null
            ? []
            : List<Cuisine>.from(
                json["cuisines"]!.map((x) => Cuisine.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "cuisines": cuisines == null
            ? []
            : List<dynamic>.from(cuisines!.map((x) => x.toJson())),
      };
}

