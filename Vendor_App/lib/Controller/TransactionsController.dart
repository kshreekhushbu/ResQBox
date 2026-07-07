import 'package:flutter/material.dart';
import 'package:resqboxvendor/Models/transaction_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class TransactionsController extends ChangeNotifier {
  // Transactions
  List<Transaction> transactions = [];
  bool isLoading = false;
  bool isDownloading = false;

  // Date filters
  DateTime? fromDate;
  DateTime? toDate;

  // Get All Transactions
  Future<void> getAllTransactions() async {
    try {
      isLoading = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      // Build URL with optional date filters
      String url = '${Api.baseUrl}${AppUrls.getAllTransactions}';
      List<String> queryParams = [];

      if (fromDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(fromDate!);
        queryParams.add('startDate=$formattedDate');
      }

      if (toDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(toDate!);
        queryParams.add('endDate=$formattedDate');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      debugPrint("📤 Get All Transactions URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get All Transactions Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final response = TransactionsResponse.fromJson(res);
        transactions = response.data;
        debugPrint("✅ Transactions loaded: ${transactions.length}");
      } else {
        customToast(message: res?['message'] ?? "Failed to load transactions");
        transactions = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting transactions: $e");
      customToast(message: "Failed to load transactions");
      transactions = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Set From Date
  void setFromDate(DateTime? date) {
    fromDate = date;
    notifyListeners();
    // Auto-fetch when date is set
    getAllTransactions();
  }

  // Set To Date
  void setToDate(DateTime? date) {
    toDate = date;
    notifyListeners();
    // Auto-fetch when date is set
    getAllTransactions();
  }

  // Download PDF
  Future<void> downloadPDF() async {
    try {
      isDownloading = true;
      notifyListeners();

      // Build URL with download parameter
      String url = '${Api.baseUrl}${AppUrls.getAllTransactions}?download=pdf';

      // Add date filters if present
      List<String> queryParams = ['download=pdf'];

      if (fromDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(fromDate!);
        queryParams.add('startDate=$formattedDate');
      }

      if (toDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(toDate!);
        queryParams.add('endDate=$formattedDate');
      }

      url =
          '${Api.baseUrl}${AppUrls.getAllTransactions}?${queryParams.join('&')}';

      debugPrint("📤 Download PDF URL: $url");

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp.pdf';

      await ApiService().downloadFile(url: url, fileName: fileName);

      customToast(message: "PDF downloaded successfully");
    } catch (e) {
      debugPrint("❌ Error downloading PDF: $e");
      customToast(message: "Failed to download PDF");
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  // Send Report to Mail
  bool isSendingMail = false;

  Future<void> displayShareSheet() async {
    try {
      isSendingMail = true;
      notifyListeners();

      // Build URL with download parameter (same as downloadPDF)
      String url = '${Api.baseUrl}${AppUrls.getAllTransactions}?download=pdf';
      List<String> queryParams = ['download=pdf'];

      if (fromDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(fromDate!);
        queryParams.add('startDate=$formattedDate');
      }

      if (toDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(toDate!);
        queryParams.add('endDate=$formattedDate');
      }

      url =
          '${Api.baseUrl}${AppUrls.getAllTransactions}?${queryParams.join('&')}';

      debugPrint("📤 Share Report URL: $url");

      // Generate filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp.pdf';

      // Download file to temp path
      final path = await ApiService().downloadFileOnly(
        url: url,
        fileName: fileName,
      );

      if (path != null) {
        // Share the file
        await Share.shareXFiles([XFile(path)], text: 'Transactions Report');
      }
    } catch (e) {
      debugPrint("❌ Error sharing report: $e");
      customToast(message: "Failed to share report");
    } finally {
      isSendingMail = false;
      notifyListeners();
    }
  }

  // Clear date filters (used when disposing screen)
  void clearFilters() {
    fromDate = null;
    toDate = null;
    transactions = [];
    // Don't call notifyListeners() or getAllTransactions()
    // as this may be called during dispose
  }
}
