import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/DocumentsController.dart';

import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:intl/intl.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsController>().getFoodCertificates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Documents",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),

      // BOTTOM BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16.0),
        child: CustomRectBtn(
          width: double.infinity,
          onTap: () {
            _showUploadDialog(context);
          },
          height: 49,
          borderRadius: 8,
          leading: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_upload_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Upload New",
                  style: AppTextStyles.size16SemiBold.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          color: Color(0xff00D341),
          borderColor: Color(0xff00D341),
          textColor: Colors.white,
        ),
      ),

      body: SafeArea(
        child: Consumer<DocumentsController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: Color(0xff00D341)),
              );
            }

            if (controller.foodCertificates.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No certificates found",
                      style: AppTextStyles.size16Medium.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Upload your first certificate",
                      style: AppTextStyles.size14Regular.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.getFoodCertificates(),
              color: Color(0xff00D341),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.foodCertificates.length,
                itemBuilder: (context, index) {
                  final certificate = controller.foodCertificates[index];
                  return _buildCertificateCard(certificate);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCertificateCard(certificate) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final uploadedDate = dateFormat.format(certificate.addedAt);
    final expiryDate = dateFormat.format(certificate.expireDate);

    // Check if certificate is expired
    final isExpired = certificate.expireDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xffFFF5F5) : const Color(0xffEFFFF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CERTIFICATE IMAGE
          GestureDetector(
            onTap: () {
              _showImagePreview(context, certificate.image);
            },
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isExpired ? Colors.red : Color(0xff00D341),
                ),
                image: DecorationImage(
                  image: NetworkImage(certificate.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // TEXTS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Food Certificate", style: AppTextStyles.size16Medium),
                    if (isExpired) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Expired",
                          style: AppTextStyles.size10Medium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  "Uploaded on $uploadedDate",
                  style: AppTextStyles.size12Medium.copyWith(
                    color: Color(0xff4B5563),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Expires on $expiryDate",
                  style: AppTextStyles.size12Medium.copyWith(
                    color: isExpired ? Colors.red : Color(0xff00D341),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imageUrl),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    final controller = context.read<DocumentsController>();
    controller.clearSelections();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Consumer<DocumentsController>(
          builder: (context, controller, child) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    "Upload Food Certificate",
                    style: AppTextStyles.size18SemiBold,
                  ),
                  SizedBox(height: 20),

                  // IMAGE PICKER
                  GestureDetector(
                    onTap: () => controller.pickCertificateImage(),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xffF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xffD1D5DB)),
                        image: controller.selectedCertificateImage != null
                            ? DecorationImage(
                                image: FileImage(
                                  controller.selectedCertificateImage!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: controller.selectedCertificateImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Color(0xff9CA3AF),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Tap to select image",
                                  style: AppTextStyles.size14Regular.copyWith(
                                    color: Color(0xff6B7280),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                  SizedBox(height: 16),

                  // DATE PICKER
                  Text("Expiry Date", style: AppTextStyles.size14Medium),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 3650)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xff00D341),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        controller.setExpireDate(date);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xffF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xffD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Color(0xff6B7280),
                          ),
                          SizedBox(width: 12),
                          Text(
                            controller.selectedExpireDate != null
                                ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(controller.selectedExpireDate!)
                                : "Select expiry date",
                            style: AppTextStyles.size14Regular.copyWith(
                              color: controller.selectedExpireDate != null
                                  ? Colors.black
                                  : Color(0xff6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: CustomRectBtn(
                          onTap: () {
                            controller.clearSelections();
                            Navigator.pop(dialogContext);
                          },
                          width: double.infinity,
                          height: 45,
                          borderRadius: 8,
                          leading: Center(
                            child: Text(
                              "Cancel",
                              style: AppTextStyles.size14SemiBold.copyWith(
                                color: Color(0xff6B7280),
                              ),
                            ),
                          ),
                          color: Colors.white,
                          borderColor: Color(0xffD1D5DB),
                          textColor: Color(0xff6B7280),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CustomRectBtn(
                          onTap: controller.isUploading
                              ? () {}
                              : () async {
                                  final success = await controller
                                      .addFoodCertificate();
                                  if (success) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                          width: double.infinity,
                          height: 45,
                          borderRadius: 8,
                          leading: Center(
                            child: controller.isUploading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Submit",
                                    style: AppTextStyles.size14SemiBold
                                        .copyWith(color: Colors.white),
                                  ),
                          ),
                          color: Color(0xff00D341),
                          borderColor: Color(0xff00D341),
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
