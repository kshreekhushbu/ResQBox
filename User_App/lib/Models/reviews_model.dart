// To parse this JSON data, do
//
//     final reviewsModel = reviewsModelFromJson(jsonString);

import 'dart:convert';

ReviewsModel reviewsModelFromJson(String str) =>
    ReviewsModel.fromJson(json.decode(str));

String reviewsModelToJson(ReviewsModel data) => json.encode(data.toJson());

class ReviewsModel {
  int? status;
  String? message;
  Summary? summary;
  List<Review>? reviews;

  ReviewsModel({
    this.status,
    this.message,
    this.summary,
    this.reviews,
  });

  factory ReviewsModel.fromJson(Map<String, dynamic> json) => ReviewsModel(
        status: json["status"],
        message: json["message"],
        summary:
            json["summary"] == null ? null : Summary.fromJson(json["summary"]),
        reviews: json["reviews"] == null
            ? []
            : List<Review>.from(
                json["reviews"]!.map((x) => Review.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "summary": summary?.toJson(),
        "reviews": reviews == null
            ? []
            : List<dynamic>.from(reviews!.map((x) => x.toJson())),
      };
}

class Review {
  int? id;
  double? rating;
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
        rating: json["rating"]?.toDouble(),
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

class Summary {
  int? totalReviews;
  double? avgRating;

  Summary({
    this.totalReviews,
    this.avgRating,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        totalReviews: json["totalReviews"],
        avgRating: json["avgRating"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "totalReviews": totalReviews,
        "avgRating": avgRating,
      };
}
