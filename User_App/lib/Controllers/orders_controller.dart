import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:resqbox_user/Models/order_details_model.dart';
import 'package:resqbox_user/Models/orders_model.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Services/apis.dart';
import 'package:resqbox_user/Services/dynamic_response.dart';
import 'package:resqbox_user/Utils/custom_loader.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/toast.dart';

class OrdersController extends ChangeNotifier {
  bool isMyOrdersLoading = false;
  bool isMyOrdersByIdLoading = false;
  OrdersModel? ordersData;
  OrdersDetailsModel? ordersDetailsData;

  Future<void> myOrdersApi(int? type) async {
    isMyOrdersLoading = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.myOrdersApi}/?type=$type";
      debugPrint("orders URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("orders data: $response");
      if (response != null && response["status"] == 1) {
        isMyOrdersLoading = false;
        ordersData = OrdersModel.fromJson(response);
        notifyListeners();
      } else {
        isMyOrdersLoading = false;
        ordersData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching orders data: $e");
      isMyOrdersLoading = false;
      notifyListeners();
    }
  }

  Future<bool> myOrdersByIdApi(int? orderId) async {
    isMyOrdersByIdLoading = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.myOrdersByIdApi}/$orderId";
      debugPrint("ordersById URL: $url");

      final response = await ApiService().getRequest(url);
      debugPrint("ordersById data: $response");

      if (response != null && response["status"] == 1) {
        ordersDetailsData = OrdersDetailsModel.fromJson(response);
        return true;
      } else {
        ordersDetailsData = null;
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error fetching ordersById data: $e");
      ordersDetailsData = null;
      return false;
    } finally {
      isMyOrdersByIdLoading = false;
      notifyListeners();
    }
  }

  /// Update order status and timestamps from socket data
  void updateOrderStatusFromSocket(Map<String, dynamic> data) {
    try {
      if (ordersDetailsData != null && ordersDetailsData!.order != null) {
        final incomingOrderId = data['orderId'];
        final currentOrderId = ordersDetailsData!.order!.orderId;

        // Only update if it's the current order being viewed
        if (incomingOrderId != null && incomingOrderId == currentOrderId) {
          debugPrint("🔄 Updating current order status from socket: $data");

          if (data['status'] != null) {
            ordersDetailsData!.order!.status = data['status'];
          }

          // Update timestamps if they are present in the socket data
          if (data['orderedAt'] != null) {
            ordersDetailsData!.order!.orderedAt =
                DateTime.tryParse(data['orderedAt'].toString());
          }
          if (data['acceptedAt'] != null) {
            ordersDetailsData!.order!.acceptedAt =
                DateTime.tryParse(data['acceptedAt'].toString());
          }
          if (data['preparedAt'] != null) {
            ordersDetailsData!.order!.preparedAt =
                DateTime.tryParse(data['preparedAt'].toString());
          }
          if (data['pickedAt'] != null) {
            ordersDetailsData!.order!.pickedAt =
                DateTime.tryParse(data['pickedAt'].toString());
          }
          if (data['cancelledAt'] != null) {
            ordersDetailsData!.order!.cancelledAt =
                DateTime.tryParse(data['cancelledAt'].toString());
          }
          if (data['pickupStartTime'] != null) {
            ordersDetailsData!.order!.pickupStartTime =
                data['pickupStartTime'].toString();
          }
          if (data['pickupEndTime'] != null) {
            ordersDetailsData!.order!.pickupEndTime =
                data['pickupEndTime'].toString();
          }
          if (data['updatedAt'] != null) {
            ordersDetailsData!.order!.updatedAt =
                DateTime.tryParse(data['updatedAt'].toString());
          }

          notifyListeners();
        } else {
          debugPrint(
              "ℹ️ Received status update for order $incomingOrderId, but viewing $currentOrderId. Skipping UI update.");
        }
      }
    } catch (e) {
      debugPrint("❌ Error updating order status from socket: $e");
    }
  }

  Future<void> submitRatingApi(Map<String, dynamic> body) async {
    Loaders.showLoadingDialog();
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.submitRatingApi}";
      debugPrint("ordersById URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("ordersById data: $response");
      if (response != null && response["status"] == 1) {
        Loaders.hideLoadingDialog();
        customToast(message: response["message"]);
        NavigateTo().nextPage(child: const BottomNavigation(initialIndex: 1));
        notifyListeners();
      } else {
        Loaders.hideLoadingDialog();
        customToast(message: response["message"]);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching ordersById data: $e");
      Loaders.hideLoadingDialog();
      notifyListeners();
      Loaders.hideLoadingDialog();
      notifyListeners();
    }
  }

  Future<void> downloadUploadedFiles(String url) async {
    try {
      // Show loading indicator
      Loaders.showLoadingDialog();

      print("Checking storage permission...");
      var status = await Permission.mediaLibrary.status;

      if (!status.isGranted) {
        print("Storage permission not granted. Requesting...");
        await Permission.mediaLibrary.request();
      }
      status = await Permission.mediaLibrary.status;
      if (status.isGranted) {
        print("Storage permission granted.");
        Directory dir =
            Directory('/storage/emulated/0/Download/'); // for Android
        if (!await dir.exists()) {
          print(
              "Download directory does not exist. Using external storage directory.");
          dir = await getExternalStorageDirectory() ?? Directory.systemTemp;
        } else {
          print("Download directory exists: ${dir.path}");
        }

        String generateFileName(String originalName) {
          // Extract file extension
          String extension = originalName.split('.').last;
          // Generate unique identifier
          String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
          // Return unique filename with the same extension
          String fileName = "uploadedInvoice_$uniqueId.$extension";
          print("Generated filename: $fileName");
          return fileName;
        }

        // Start downloading the file
        print("Starting download from: $url");
        FileDownloader.downloadFile(
          url: url.trim(),
          name: "uploadedInvoice_${DateTime.now().millisecondsSinceEpoch}.docx",
          downloadDestination: DownloadDestinations.publicDownloads,
          notificationType: NotificationType.all,
          onDownloadRequestIdReceived: (downloadId) {
            print('Download ID: $downloadId');
          },
          onProgress: (fileName, progress) {
            print('Downloading $fileName: $progress%');
          },
          onDownloadCompleted: (path) {
            print('Download completed at: $path');
            Loaders.hideLoadingDialog();
            customToast(message: "Invoice downloaded to Downloads");
          },
          onDownloadError: (error) {
            print('Download error: $error');
            Loaders.hideLoadingDialog();
            customToast(message: "Download failed");
          },
        );
      } else {
        print("Storage permission denied.");
        Loaders.hideLoadingDialog();
        customToast(
            message:
                "Storage permission denied. Please allow storage access to download files.");
      }
    } catch (e, s) {
      print('Exception caught: $e');
      print('Stack trace: $s');
      Loaders.hideLoadingDialog();
      customToast(message: "Download failed: ${e.toString()}");
    }
  }
}
