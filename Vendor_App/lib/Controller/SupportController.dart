import 'package:flutter/material.dart';
import 'package:resqboxvendor/Models/ChatMessage.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';

import 'package:resqboxvendor/Utils/toast.dart';

class SupportController extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  int? _roomId;
  String? _roomStatus; // Added roomStatus
  bool _isLoading = false;
  bool _isSending = false;

  List<ChatMessage> get messages => _messages;
  int? get roomId => _roomId;
  String? get roomStatus => _roomStatus; // Getter for roomStatus
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;

  void initializeSocketListener() {
    // Socket listener disabled for support messages as per requirement
    // relying on Push Notifications instead.
    debugPrint(
      "🔌 Socket listener disabled for support-message (using Push Notifications)",
    );
  }

  void removeSocketListener() {
    // No listener to remove
  }

  Future<void> fetchChatMessages() async {
    try {
      _isLoading = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getKitchenSupportChatMessages}';

      debugPrint("📤 Fetch Messages URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Fetch Messages Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        _roomId = res['roomId'];
        _roomStatus = res['roomStatus']; // Parse roomStatus

        if (res['messages'] != null && res['messages'] is List) {
          _messages = (res['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();

          debugPrint("✅ Fetched ${_messages.length} messages");
        } else {
          _messages = [];
        }
      } else {
        customToast(message: res?['message'] ?? "Failed to fetch messages");
        _messages = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching messages: $e");
      customToast(message: "Error fetching messages");
      _messages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadChatImage(dynamic imageFile) async {
    try {
      final url = '${Api.baseUrl}vendor/upload';

      final result = await ApiService().uploadImage(
        url: url,
        file: imageFile,
        folder: "chat",
        fieldName: "file",
      );

      if (result != null && result['fileName'] != null) {
        debugPrint("✅ Chat image uploaded: ${result['fileName']}");
        // Return full URL if available, otherwise filename
        return result['fileUrl'] ?? result['fileName'];
      } else {
        customToast(message: "Failed to upload image");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error uploading chat image: $e");
      customToast(message: "Failed to upload image");
      return null;
    }
  }

  Future<bool> sendMessage(String message, {dynamic imageFile}) async {
    try {
      _isSending = true;
      notifyListeners();

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadChatImage(imageFile);
        if (imageUrl == null) {
          // Failed to upload image, abort sending
          _isSending = false;
          notifyListeners();
          return false;
        }
      }

      final url = '${Api.baseUrl}${AppUrls.startKitchenSupportChat}';
      final payload = {
        "message": message.trim(),
        if (imageUrl != null) "image": imageUrl,
      };

      debugPrint("📤 Send Message URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);

      debugPrint("📥 Send Message Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        debugPrint("✅ Message sent successfully");

        if (res['data'] != null && res['data'] is Map<String, dynamic>) {
          try {
            final newMessage = ChatMessage.fromJson(res['data']);

            final exists = _messages.any(
              (msg) => msg.messageId == newMessage.messageId,
            );

            if (!exists) {
              _messages.add(newMessage);
              notifyListeners();
              debugPrint("✅ Message added to chat from API response");
            }
          } catch (e) {
            debugPrint("❌ Error parsing message from response: $e");
          }
        }

        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to send message");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error sending message: $e");
      customToast(message: "Error sending message");
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages = [];
    _roomId = null;
    removeSocketListener();
    notifyListeners();
  }

  @override
  void dispose() {
    removeSocketListener();
    super.dispose();
  }
}
