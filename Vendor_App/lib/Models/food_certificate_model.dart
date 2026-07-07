class FoodCertificatesResponse {
  final int status;
  final String message;
  final List<FoodCertificate> foodCertificateImages;

  FoodCertificatesResponse({
    required this.status,
    required this.message,
    required this.foodCertificateImages,
  });

  factory FoodCertificatesResponse.fromJson(Map<String, dynamic> json) {
    return FoodCertificatesResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      foodCertificateImages:
          (json['foodCertificateImages'] as List<dynamic>?)
              ?.map((item) => FoodCertificate.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'foodCertificateImages': foodCertificateImages
          .map((item) => item.toJson())
          .toList(),
    };
  }
}

class FoodCertificate {
  final String image;
  final DateTime expireDate;
  final DateTime addedAt;

  FoodCertificate({
    required this.image,
    required this.expireDate,
    required this.addedAt,
  });

  factory FoodCertificate.fromJson(Map<String, dynamic> json) {
    return FoodCertificate(
      image: json['image'] ?? '',
      expireDate: DateTime.parse(json['expireDate']),
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'expireDate': expireDate.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
    };
  }
}
