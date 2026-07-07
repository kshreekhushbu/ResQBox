import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required Function(File file) onImageSelected,
  }) async {
    final picker = ImagePicker();

    void pickImage(ImageSource source) async {
      Navigator.pop(context); // close the bottom sheet
      final XFile? picked = await picker.pickImage(source: source);
      if (picked != null) {
        final file = File(picked.path);
        onImageSelected(file); // callback
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Select Image to Upload',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera),
                    title: const Text("Camera"),
                    onTap: () => pickImage(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text("Gallery"),
                    onTap: () => pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
