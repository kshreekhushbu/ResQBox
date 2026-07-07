// To parse this JSON data, do
//
//     final getNotificationsModel = getNotificationsModelFromJson(jsonString);

import 'dart:convert';

GetNotificationsModel getNotificationsModelFromJson(String str) =>
    GetNotificationsModel.fromJson(json.decode(str));

String getNotificationsModelToJson(GetNotificationsModel data) =>
    json.encode(data.toJson());

class GetNotificationsModel {
  int? status;
  String? message;
  int? count;
  List<NotificationData>? notifications;

  GetNotificationsModel({
    this.status,
    this.message,
    this.count,
    this.notifications,
  });

  factory GetNotificationsModel.fromJson(Map<String, dynamic> json) =>
      GetNotificationsModel(
        status: json["status"],
        message: json["message"],
        count: json["count"],
        notifications: json["notifications"] == null
            ? []
            : List<NotificationData>.from(json["notifications"]!
                .map((x) => NotificationData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "count": count,
        "notifications": notifications == null
            ? []
            : List<dynamic>.from(notifications!.map((x) => x.toJson())),
      };
}

class NotificationData {
  int? id;
  int? ownerId;
  String? ownerType;
  String? title;
  String? message;
  int? orderId;
  int? type;
  bool? isRead;
  DateTime? createdAt;
  bool? isAdminNotification;

  NotificationData({
    this.id,
    this.ownerId,
    this.ownerType,
    this.title,
    this.message,
    this.orderId,
    this.type,
    this.isRead,
    this.createdAt,
    this.isAdminNotification,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        id: json["id"],
        ownerId: json["ownerId"],
        ownerType: json["ownerType"],
        title: json["title"],
        message: json["message"],
        orderId: json["orderId"],
        type: json["type"],
        isRead: json["isRead"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        isAdminNotification: json["isAdminNotification"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "ownerId": ownerId,
        "ownerType": ownerType,
        "title": title,
        "message": message,
        "orderId": orderId,
        "type": type,
        "isRead": isRead,
        "createdAt": createdAt?.toIso8601String(),
        "isAdminNotification": isAdminNotification,
      };
}
