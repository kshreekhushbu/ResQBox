class ChatMessage {
  final int messageId;
  final int roomId;
  final String senderRole;
  final int? senderId;
  final int? adminId;
  final String message;
  final String? image;
  final int isRead;
  final String createdAt;

  ChatMessage({
    required this.messageId,
    required this.roomId,
    required this.senderRole,
    this.senderId,
    this.adminId,
    required this.message,
    this.image,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? 0,
      roomId: json['roomId'] ?? 0,
      senderRole: json['senderRole'] ?? '',
      senderId: json['senderId'],
      adminId: json['adminId'],
      message: json['message'] ?? '',
      image: json['image'],
      isRead: json['isRead'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'roomId': roomId,
      'senderRole': senderRole,
      'senderId': senderId,
      'adminId': adminId,
      'message': message,
      'image': image,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  bool get isFromKitchen => senderRole == 'KITCHEN';
  bool get isFromAdmin => senderRole == 'ADMIN';
}
