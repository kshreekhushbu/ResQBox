import 'package:flutter/material.dart';
import 'package:resqboxvendor/Models/monthly_invoice_details_model.dart';
import 'package:resqboxvendor/Models/monthly_invoice_model.dart';
import 'package:resqboxvendor/Models/payout_invoice_details_model.dart';
import 'package:resqboxvendor/Models/payout_invoice_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoicesController extends ChangeNotifier {
  // Payout Invoices
  List<PayoutInvoice> payoutInvoices = [];
  bool isLoading = false;

  // Invoice Details
  PayoutInvoiceDetails? invoiceDetails;
  bool isDetailsLoading = false;
  bool isDownloadingPdf = false;

  // Monthly Invoices
  List<MonthlyInvoice> monthlyInvoices = [];
  bool isMonthlyInvoicesLoading = false;

  // Monthly Invoice Details
  MonthlyInvoiceDetails? monthlyInvoiceDetails;
  bool isMonthlyDetailsLoading = false;

  // Get Payout Invoices
  Future<void> getPayoutInvoices() async {
    try {
      isLoading = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getPayoutInvoices}';
      debugPrint("📤 Get Payout Invoices URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Payout Invoices Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final response = PayoutInvoicesResponse.fromJson(res);
        payoutInvoices = response.invoices;
        debugPrint("✅ Payout invoices loaded: ${payoutInvoices.length}");
      } else {
        customToast(message: res?['message'] ?? "Failed to load invoices");
        payoutInvoices = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting payout invoices: $e");
      customToast(message: "Failed to load invoices");
      payoutInvoices = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get Monthly Invoices
  Future<void> getMonthlyInvoices() async {
    try {
      isMonthlyInvoicesLoading = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getMonthlyInvoices}';
      debugPrint("📤 Get Monthly Invoices URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Monthly Invoices Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final response = MonthlyInvoiceResponse.fromJson(res);
        monthlyInvoices = response.invoices;
        debugPrint("✅ Monthly invoices loaded: ${monthlyInvoices.length}");
      } else {
        customToast(
          message: res?['message'] ?? "Failed to load monthly invoices",
        );
        monthlyInvoices = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting monthly invoices: $e");
      customToast(message: "Failed to load monthly invoices");
      monthlyInvoices = [];
    } finally {
      isMonthlyInvoicesLoading = false;
      notifyListeners();
    }
  }

  // Get Payout Invoice Details
  Future<void> getPayoutInvoiceDetails(int payoutId) async {
    try {
      isDetailsLoading = true;
      invoiceDetails = null; // Clear previous details
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getPayoutInvoiceDetails}/$payoutId';
      debugPrint("📤 Get Invoice Details URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Invoice Details Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final response = PayoutInvoiceDetailsResponse.fromJson(res);
        invoiceDetails = response.data;
        debugPrint(
          "✅ Invoice details loaded: ${invoiceDetails?.invoiceNumber}",
        );
      } else {
        customToast(
          message: res?['message'] ?? "Failed to load invoice details",
        );
      }
    } catch (e) {
      debugPrint("❌ Error getting invoice details: $e");
      customToast(message: "Failed to load invoice details");
    } finally {
      isDetailsLoading = false;
      notifyListeners();
    }
  }

  // Get Monthly Invoice Details
  Future<void> getMonthlyInvoiceDetails(int invoiceId) async {
    try {
      isMonthlyDetailsLoading = true;
      monthlyInvoiceDetails = null; // Clear previous details
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url =
          '${Api.baseUrl}${AppUrls.getMonthlyInvoiceDetails}/$invoiceId';
      debugPrint("📤 Get Monthly Invoice Details URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Monthly Invoice Details Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final response = MonthlyInvoiceDetailsResponse.fromJson(res);
        monthlyInvoiceDetails = response.data;
        debugPrint(
          "✅ Monthly Invoice details loaded: ${monthlyInvoiceDetails?.invoiceNumber}",
        );
      } else {
        customToast(
          message: res?['message'] ?? "Failed to load monthly invoice details",
        );
      }
    } catch (e) {
      debugPrint("❌ Error getting monthly invoice details: $e");
      customToast(message: "Failed to load monthly invoice details");
    } finally {
      isMonthlyDetailsLoading = false;
      notifyListeners();
    }
  }

  // Download Invoice PDF
  Future<void> downloadInvoice({bool isMonthly = false}) async {
    String? pdfUrl;
    if (isMonthly) {
      pdfUrl = monthlyInvoiceDetails?.pdfUrl;
    } else {
      pdfUrl = invoiceDetails?.pdfUrl;
    }

    if (pdfUrl == null || pdfUrl.isEmpty) {
      customToast(message: "PDF not available");
      return;
    }

    try {
      isDownloadingPdf = true;
      notifyListeners();

      notifyListeners();

      final url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        customToast(message: "Could not launch PDF URL");
      }
    } catch (e) {
      debugPrint("❌ Error launching PDF: $e");
      customToast(message: "Failed to download PDF");
    } finally {
      isDownloadingPdf = false;
      notifyListeners();
    }
  }

  // Clear invoices (used when disposing screen)
  void clearInvoices() {
    payoutInvoices = [];
    invoiceDetails = null;
    monthlyInvoices = [];
    monthlyInvoiceDetails = null;
  }
}
