// To parse this JSON data, do
//
//     final supportChatModel = supportChatModelFromJson(jsonString);

import 'dart:convert';

SupportChatModel supportChatModelFromJson(String str) =>
    SupportChatModel.fromJson(json.decode(str));

String supportChatModelToJson(SupportChatModel data) =>
    json.encode(data.toJson());

class SupportChatModel {
  int? status;
  String? message;
  int? roomId;
  String? roomStatus;
  List<Message>? messages;

  SupportChatModel({
    this.status,
    this.message,
    this.roomId,
    this.roomStatus,
    this.messages,
  });

  factory SupportChatModel.fromJson(Map<String, dynamic> json) =>
      SupportChatModel(
        status: json["status"],
        message: json["message"],
        roomId: json["roomId"],
        roomStatus: json["roomStatus"],
        messages: json["messages"] == null
            ? []
            : List<Message>.from(
                json["messages"]!.map((x) => Message.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "roomId": roomId,
        "roomStatus": roomStatus,
        "messages": messages == null
            ? []
            : List<dynamic>.from(messages!.map((x) => x.toJson())),
      };
}

class Message {
  int? messageId;
  int? roomId;
  String? senderRole;
  int? senderId;
  dynamic adminId;
  String? message;
  dynamic image;
  int? isRead;
  DateTime? createdAt;

  Message({
    this.messageId,
    this.roomId,
    this.senderRole,
    this.senderId,
    this.adminId,
    this.message,
    this.image,
    this.isRead,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        messageId: json["messageId"],
        roomId: json["roomId"],
        senderRole: json["senderRole"],
        senderId: json["senderId"],
        adminId: json["adminId"],
        message: json["message"],
        image: json["image"],
        isRead: json["isRead"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
      );

  Map<String, dynamic> toJson() => {
        "messageId": messageId,
        "roomId": roomId,
        "senderRole": senderRole,
        "senderId": senderId,
        "adminId": adminId,
        "message": message,
        "image": image,
        "isRead": isRead,
        "createdAt": createdAt?.toIso8601String(),
      };
}
