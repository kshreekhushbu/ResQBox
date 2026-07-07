import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/SupportController.dart';
import 'package:resqboxvendor/Models/ChatMessage.dart';
import 'package:resqboxvendor/Services/global_socket_service.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_sizedbox.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  State<HelpAndSupport> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SupportController? _supportController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalSocketService().initialize(context);

      _supportController = context.read<SupportController>();
      _supportController!.fetchChatMessages().then((_) {
        _scrollToBottom();
      });

      _supportController!.initializeSocketListener();

      _supportController!.addListener(_onMessagesUpdated);
    });
  }

  @override
  void dispose() {
    _supportController?.removeListener(_onMessagesUpdated);
    _supportController?.removeSocketListener();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessagesUpdated() {
    if (mounted) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImage == null) {
      return;
    }

    final message = _messageController.text.trim();
    // Use a local variable to hold the image, then clear state
    final imageToSend = _selectedImage;

    // Clear input immediately for better UX
    _messageController.clear();
    setState(() {
      _selectedImage = null;
    });

    final supportController = context.read<SupportController>();
    final success = await supportController.sendMessage(
      message,
      imageFile: imageToSend,
    );

    if (success) {
      // If the room was closed, fetching again will update the roomStatus and messages list
      if (supportController.roomStatus == 'CLOSED') {
        await supportController.fetchChatMessages();
      }
      _scrollToBottom();
    }
  }

  String _formatTime(String dateTimeStr) {
    try {
      // Parse as UTC and convert to local time
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
      } else if (difference.inDays < 7) {
        return DateFormat('EEE HH:mm').format(dateTime);
      } else {
        return DateFormat('MMM dd, HH:mm').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  File? _selectedImage;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF6F6F6),
      appBar: CustomAppBar(
        title: "Help & Support",
        titleFontSize: 0.022,
        backTap: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    "Chat with ResQBox Agent",
                    style: AppTextStyles.size16Medium.copyWith(
                      color: const Color(0xff0D1C12),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffE8F2EB),
                        width: 4,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.green, width: 2),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          "RQ",
                          style: AppTextStyles.size16Medium.copyWith(
                            color: AppColors.green,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: Consumer<SupportController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.mainAppColr,
                      ),
                    );
                  }

                  if (controller.messages.isEmpty &&
                      controller.roomStatus != 'CLOSED') {
                    return const SizedBox.shrink(); // Empty state is just blank space now, header is top
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await controller.fetchChatMessages();
                      _scrollToBottom();
                    },
                    color: AppColors.mainAppColr,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: Sizes.width * 0.04,
                        vertical: Sizes.height * 0.02,
                      ),
                      // Add 1 to count if room is closed to show the "Ticket Closed" widget
                      itemCount:
                          controller.messages.length +
                          (controller.roomStatus == 'CLOSED' ? 1 : 0),
                      itemBuilder: (context, index) {
                        // If we are at the last index and room is closed, show the closed widget
                        if (controller.roomStatus == 'CLOSED' &&
                            index == controller.messages.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20.0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                child: Text(
                                  "Support Request Is Closed",
                                  style: AppTextStyles.size16Medium.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final message = controller.messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  );
                },
              ),
            ),

            // Image Preview
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: -5,
                          top: -5,
                          child: GestureDetector(
                            onTap: _removeSelectedImage,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Image selected",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _removeSelectedImage,
                    ),
                  ],
                ),
              ),

            // Message Input - Hide if CLOSED
            Consumer<SupportController>(
              builder: (context, controller, child) {
                // if (controller.roomStatus == 'CLOSED') {
                //   return const SizedBox.shrink();
                // }

                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Sizes.width * 0.04,
                    vertical: Sizes.height * 0.015,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.tWhiteColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _messageController,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            hintStyle: AppTextStyles.size14Regular.copyWith(
                              color: const Color(0xff4D9966),
                            ),
                            filled: true,
                            fillColor: const Color(0xffE8F2EB),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Sizes.width * 0.04,
                              vertical: Sizes.height * 0.012,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onFieldSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: controller.isSending ? null : _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: controller.isSending
                                ? Colors.grey[400]
                                : AppColors.mainAppColr,
                            shape: BoxShape.circle,
                          ),
                          child: controller.isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isKitchen = message.isFromKitchen;

    return Padding(
      padding: EdgeInsets.only(bottom: Sizes.height * 0.015),
      child: Row(
        mainAxisAlignment: isKitchen
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin avatar (left side)
          if (!isKitchen) ...[
            Container(
              height: Sizes.height * 0.04,
              width: Sizes.height * 0.04,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0XFFE8F2EB),
                border: Border.all(color: AppColors.green, width: 1.5),
              ),
              child: Center(
                child: Text(
                  'A',
                  style: AppTextStyles.size14SemiBold.copyWith(
                    color: AppColors.green,
                  ),
                ),
              ),
            ),
            CustomSizedBox(width: .02),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isKitchen
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  isKitchen ? "You" : "Admin",
                  style: AppTextStyles.size12Regular.copyWith(
                    color: const Color(0xff4D9966),
                  ),
                ),
                CustomSizedBox(height: .005),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Sizes.width * 0.04,
                    vertical: Sizes.height * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: isKitchen
                        ? const Color(0XFFD7FFB3)
                        : const Color(0XFFE8F2EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.image != null &&
                          message.image!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message
                                .image!, // Assuming full URL or handled by network image
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 150,
                                width: 200,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        message.message,
                        style: AppTextStyles.size14Regular.copyWith(
                          color: const Color(0xff0D1C12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.createdAt),
                        style: AppTextStyles.size10Regular.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Kitchen avatar (right side)
          if (isKitchen) ...[
            CustomSizedBox(width: .02),
            Container(
              height: Sizes.height * 0.04,
              width: Sizes.height * 0.04,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mainAppColr,
              ),
              child: Center(
                child: Text(
                  'K',
                  style: AppTextStyles.size14SemiBold.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
