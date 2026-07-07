import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Controllers/socket_controller.dart';
import 'package:resqbox_user/Models/support_chat_model.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/textformfield.dart';
import 'package:resqbox_user/Utils/toast.dart';
import 'package:resqbox_user/Utils/custom_loader.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  State<HelpAndSupport> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;
  File? _selectedImage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final socketController =
          Provider.of<SocketController>(context, listen: false);
      socketController.initializeSocketConnection();
      await Provider.of<AccountController>(context, listen: false)
          .getSupportMessages();
      // Scroll to bottom after messages are loaded
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    // Disconnect socket when screen is closed
    final socketController =
        Provider.of<SocketController>(context, listen: false);
    socketController.disconnectSocket();

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountController>(
        builder: (context, accountController, child) {
      // Scroll to bottom when new messages are added
      final messageCount =
          accountController.supportChatData?.messages?.length ?? 0;
      if (messageCount > _previousMessageCount) {
        _previousMessageCount = messageCount;
        _scrollToBottom();
      }

      return Scaffold(
        backgroundColor: const Color(0XFFF6F6F6),
        appBar: CustomAppBar(
          title: "Help & Support",
          titleFontSize: 0.022,
          backgroundColor: AppColors.tWhiteColor,
          backTap: () => Navigator.of(context).pop(),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      CustomPadding(
                        top: .03,
                        child: Center(
                          child: CustomTap(
                            onTap: () {
                              // Handle chat with agent
                            },
                            child: const CustomText(
                              text: "Chat with ResQBox Food Agent",
                              fontSize: 0.018,
                              fontWeight: FontWeight.w500,
                              color: Color(0XFF0D1C12),
                              // decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const CustomSizedBox(height: .02),
                      // Main Agent Avatar
                      Container(
                        padding: EdgeInsets.all(Sizes.width * 0.018),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0XFFCBECD5)),
                        child: Container(
                          height: Sizes.height * 0.08,
                          width: Sizes.height * 0.08,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                            border: Border.all(
                              color: AppColors.green,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: CustomText(
                              text: "R",
                              fontSize: 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const CustomSizedBox(height: .03),
                      // Chat Messages
                      accountController.isSupport
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : accountController.supportChatData?.messages ==
                                      null ||
                                  accountController
                                      .supportChatData!.messages!.isEmpty
                              ? const CustomPadding(
                                  horizontal: .04,
                                  child: CustomText(
                                    text:
                                        "No messages yet. Start the conversation!",
                                    fontSize: 0.016,
                                    color: Color(0XFF4D9966),
                                  ),
                                )
                              : CustomPadding(
                                  horizontal: .04,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ...accountController
                                          .supportChatData!.messages!
                                          .map((message) => _buildMessageBubble(
                                              message, accountController))
                                          .toList(),
                                      // Add spacing at the bottom
                                      const CustomSizedBox(height: .02),
                                    ],
                                  ),
                                ),
                      // Show Closed Ticket Message
                      accountController.isSupport
                          ? SizedBox.shrink()
                          : (accountController.supportChatData?.roomStatus
                                      ?.toUpperCase() ==
                                  'CLOSED')
                              ? Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: Sizes.width * 0.04,
                                    vertical: Sizes.height * 0.02,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: Sizes.height * 0.015,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 232, 242, 232),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.tPrimaryColor),
                                  ),
                                  child: const Center(
                                    child: CustomText(
                                      text: "Your ticket is closed",
                                      fontSize: 0.016,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.tPrimaryColor,
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(),
                      // CustomSizedBox(height: .03),
                      // // Suggested Topics

                      // CustomSizedBox(height: .02),
                    ],
                  ),
                ),
              ),
              // Message Input Field
              Container(
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
                  boxShadow: [
                    BoxShadow(
                      color: Color(0XFFE0E0E0),
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _messageController,
                        builder: (context, value, child) {
                          if (value.text.isNotEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              CustomPadding(
                                horizontal: .0,
                                child: Wrap(
                                  spacing: Sizes.width * 0.04,
                                  runSpacing: Sizes.height * 0.015,
                                  children: [
                                    _buildTopicButton(
                                      "Order Issues",
                                      isSelected: true,
                                    ),
                                    _buildTopicButton(
                                      "Refund",
                                      isSelected: true,
                                    ),
                                    _buildTopicButton(
                                      "Pickup Time",
                                      isSelected: true,
                                    ),
                                    _buildTopicButton(
                                      "General Help",
                                      isSelected: true,
                                    ),
                                  ],
                                ),
                              ),
                              const CustomSizedBox(height: .02),
                            ],
                          );
                        }),
                    Row(
                      children: [
                        Expanded(
                          child: _selectedImage != null
                              ? _buildImagePreview()
                              : CustomTextFormField(
                                  controller: _messageController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  hintText: "  Type your message...",
                                  hintColor: const Color(0XFF4D9966),
                                  hintFontSize: .016,
                                  fillColor: const Color(0XFFE8F2EB),
                                  borderRaduise: 25,
                                  minLines: 1,
                                  maxLines: 5,
                                  textInputType: TextInputType.multiline,
                                  customBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: BorderSide.none,
                                  ),
                                  customSuffix: CustomTap(
                                    onTap: () =>
                                        _showImagePickerOptions(context),
                                    child: CustomPadding(
                                      horizontal: .01,
                                      vertical: .007,
                                      child: CustomImage(
                                        image: AppImages.accountMedia,
                                        height: .035,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const CustomSizedBox(width: .02),
                        Consumer<AccountController>(
                          builder: (context, accountController, child) {
                            return GestureDetector(
                              onTap: () async {
                                debugPrint("📤 Send button tapped");

                                if (_selectedImage != null) {
                                  // Send image
                                  await _sendImageMessage(accountController);
                                } else {
                                  // Send text message
                                  final messageText =
                                      _messageController.text.trim();
                                  debugPrint("📤 Message text: $messageText");

                                  if (messageText.isNotEmpty) {
                                    // Clear the text field immediately
                                    _messageController.clear();

                                    debugPrint(
                                        "📤 Calling sendSupportMessageApi");
                                    // Send via API
                                    await accountController
                                        .sendSupportMessageApi(
                                      body: {
                                        'message': messageText,
                                      },
                                    );

                                    // Scroll to bottom after sending
                                    _scrollToBottom();

                                    // Also emit via socket if connected
                                    final socketController =
                                        Provider.of<SocketController>(context,
                                            listen: false);
                                    if (socketController.isConnected) {
                                      debugPrint("📤 Emitting socket message");
                                      socketController
                                          .emitEvent('support-message', {
                                        'message': messageText,
                                      });
                                    } else {
                                      debugPrint("⚠️ Socket not connected");
                                    }
                                  } else {
                                    debugPrint("⚠️ Message is empty");
                                  }
                                }
                              },
                              child: Icon(
                                Icons.send,
                                size: Sizes.height * 0.03,
                                color: accountController.isLoadingSupportMessage
                                    ? AppColors.hintTclr
                                    : AppColors.tPrimaryColor,
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tWhiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: Sizes.width * 0.04,
              right: Sizes.width * 0.04,
              top: Sizes.height * 0.03,
              bottom: Sizes.height * 0.03,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: "Choose an option",
                  fontSize: 0.02,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: Sizes.height * 0.015),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.camera_alt),
                  title: const CustomText(text: "Take Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                // const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.photo_library),
                  title: const CustomText(text: "Choose from Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (source == ImageSource.camera) {
        var status = await Permission.camera.status;
        if (status.isPermanentlyDenied) {
          customToast(
              message:
                  "Camera permission is permanently denied. Please enable it in app settings.");
          try {
            await openAppSettings();
          } catch (e) {
            debugPrint("Error opening app settings: $e");
          }
          return;
        }
        if (status.isDenied) {
          status = await Permission.camera.request();
          if (status.isDenied) {
            customToast(
                message: "Camera permission is required to take photos");
            return;
          }
        }
      } else {
        PermissionStatus status = PermissionStatus.granted;
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            // On Android 13+, image_picker uses the Photo Picker which requires NO manifest permission.
            // We skip manual permission requests here to comply with Play Store policies.
            status = PermissionStatus.granted;
          } else {
            status = await Permission.storage.status;
            if (status.isDenied) {
              status = await Permission.storage.request();
            }
          }
        } else {
          // iOS handling for photo library
          status = await Permission.photos.status;
          if (status.isDenied) {
            status = await Permission.photos.request();
          }
        }

        if (status.isPermanentlyDenied) {
          customToast(
              message:
                  "Gallery permission is permanently denied. Please enable it in app settings.");
          try {
            await openAppSettings();
          } catch (e) {
            debugPrint("Error opening app settings: $e");
          }
          return;
        }

        if (status.isDenied) {
          customToast(message: "Gallery permission is required");
          return;
        }
      }

      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission') ||
          e.toString().contains('MissingPluginException')) {
        customToast(
            message:
                "Permission denied. Please enable camera/gallery permission in app settings.");
        try {
          await openAppSettings();
        } catch (settingsError) {
          debugPrint("Error opening app settings: $settingsError");
        }
      } else {
        customToast(message: "Failed to pick image. Please try again.");
      }
    }
  }

  Widget _buildImagePreview() {
    return Container(
      height: Sizes.height * 0.15,
      decoration: BoxDecoration(
        color: const Color(0XFFE8F2EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendImageMessage(AccountController accountController) async {
    if (_selectedImage == null) return;

    try {
      // Show loading
      Loaders.showLoadingDialog();

      // Upload image first
      final uploadedUrl = await accountController.uploadImage(_selectedImage!,
          folderName: "chat");
      Loaders.hideLoadingDialog();

      if (uploadedUrl != null) {
        // Clear the selected image
        setState(() {
          _selectedImage = null;
        });

        debugPrint("📤 Image uploaded, URL: $uploadedUrl");
        debugPrint("📤 Calling sendSupportMessageApi with image");

        // Send message with image URL
        await accountController.sendSupportMessageApi(
          body: {
            'image': uploadedUrl,
          },
        );

        // Scroll to bottom after sending
        _scrollToBottom();
      } else {
        customToast(message: "Failed to upload image. Please try again.");
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      debugPrint("❌ Error sending image message: $e");
      customToast(message: "Failed to send image. Please try again.");
    }
  }

  Widget _buildMessageBubble(
      Message message, AccountController accountController) {
    final isUser = message.senderRole?.toUpperCase() == "USER";
    final userProfilePicture =
        accountController.userDetailsData?.user?.profilePicture;
    final userName = accountController.userDetailsData?.user?.name ?? "You";

    return Padding(
      padding: EdgeInsets.only(bottom: Sizes.height * 0.02),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Agent Avatar (Left side)
            CustomPadding(
              top: .025,
              child: Container(
                height: Sizes.height * 0.045,
                width: Sizes.height * 0.045,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.green,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Center(
                    child: CustomText(
                      text: "R",
                      fontSize: 0.02,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  //  CustomNetworkImage(
                  //   url:
                  //       "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=60",
                  //   height: .1,
                  //   width: .1,
                  //   fit: BoxFit.cover,
                  // ),
                ),
              ),
            ),
            const CustomSizedBox(width: .02),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: isUser ? userName : "ResQBox Food",
                  fontSize: 0.017,
                  color: const Color(0XFF4D9966),
                  fontWeight: FontWeight.w400,
                ),
                const CustomSizedBox(height: .01),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Sizes.width * 0.04,
                    vertical: Sizes.height * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0XFFD7FFB3)
                        : const Color(0XFFE8F2EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: message.image != null &&
                          message.image.toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomNetworkImage(
                            url: message.image.toString(),
                            height: .3,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : message.message != null && message.message!.isNotEmpty
                          ? CustomText(
                              text: message.message ?? "",
                              fontSize: 0.018,
                              color: const Color(0XFF0D1C12),
                              textAlign: TextAlign.left,
                              fontWeight: FontWeight.w400,
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const CustomSizedBox(width: .02),
            // User Avatar (Right side)
            CustomPadding(
              top: .033,
              child: Container(
                height: Sizes.height * 0.06,
                width: Sizes.height * 0.06,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child:
                    userProfilePicture != null && userProfilePicture.isNotEmpty
                        ? ClipOval(
                            child: CustomNetworkImage(
                              url: userProfilePicture,
                              height: .1,
                              width: .1,
                              fit: BoxFit.cover,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: AppColors.green,
                            child: CustomText(
                              text: userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : "U",
                              fontSize: 0.02,
                              color: AppColors.tWhiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicButton(String text, {required bool isSelected}) {
    return CustomTap(
      onTap: () {
        // Set the topic text in the text field
        _messageController.text = text;
        // Clear any selected image to show the text field
        if (_selectedImage != null) {
          setState(() {
            _selectedImage = null;
          });
        }
        // Focus on the text field
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.width * 0.04,
          vertical: Sizes.height * 0.012,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0XFFE8F2EB) : const Color(0XFFE8F2EB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomText(
          text: text,
          fontSize: 0.017,
          fontWeight: FontWeight.w500,
          color: Color(0XFF0D1C12),
        ),
      ),
    );
  }
}
