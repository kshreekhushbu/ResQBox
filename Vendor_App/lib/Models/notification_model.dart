class NotificationItem {
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

  NotificationItem({
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

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'],
        ownerId: json['ownerId'],
        ownerType: json['ownerType'],
        title: json['title'],
        message: json['message'],
        type: json['type'],
        isRead: json['isRead'],
        orderId: json['orderId'],
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt']),
        isAdminNotification: json['isAdminNotification'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'ownerType': ownerType,
    'title': title,
    'message': message,
    'orderId': orderId,
    'type': type,
    'isRead': isRead,
    'createdAt': createdAt?.toIso8601String(),
    'isAdminNotification': isAdminNotification,
  };
}

class GetNotificationsResponse {
  int? status;
  String? message;
  int? count;
  List<NotificationItem>? notifications;

  GetNotificationsResponse({
    this.status,
    this.message,
    this.count,
    this.notifications,
  });

  factory GetNotificationsResponse.fromJson(Map<String, dynamic> json) =>
      GetNotificationsResponse(
        status: json['status'],
        message: json['message'],
        count: json['count'],
        notifications: json['notifications'] == null
            ? []
            : List<NotificationItem>.from(
                json['notifications'].map((x) => NotificationItem.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'count': count,
    'notifications': notifications == null
        ? []
        : List<dynamic>.from(notifications!.map((x) => x.toJson())),
  };
}
