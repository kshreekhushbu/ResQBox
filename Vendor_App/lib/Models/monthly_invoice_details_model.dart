import 'package:resqboxvendor/Models/payout_invoice_details_model.dart';

class MonthlyInvoiceDetailsResponse {
  final int status;
  final String message;
  final MonthlyInvoiceDetails? data;

  MonthlyInvoiceDetailsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory MonthlyInvoiceDetailsResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyInvoiceDetailsResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? MonthlyInvoiceDetails.fromJson(json['data'])
          : null,
    );
  }
}

class MonthlyInvoiceDetails {
  final int invoiceId;
  final String invoiceNumber;
  final String pdfUrl;
  final int month;
  final int year;
  final String periodStart;
  final String periodEnd;
  final InvoiceSummary summary;
  final List<InvoiceOrder> orders;

  MonthlyInvoiceDetails({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.pdfUrl,
    required this.month,
    required this.year,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.orders,
  });

  factory MonthlyInvoiceDetails.fromJson(Map<String, dynamic> json) {
    return MonthlyInvoiceDetails(
      invoiceId: json['invoiceId'] ?? 0,
      invoiceNumber: json['invoiceNumber'] ?? '',
      pdfUrl: json['pdfUrl'] ?? '',
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      periodStart: json['periodStart'] ?? '',
      periodEnd: json['periodEnd'] ?? '',
      summary: InvoiceSummary.fromJson(json['summary'] ?? {}),
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((item) => InvoiceOrder.fromJson(item))
              .toList() ??
          [],
    );
  }
}
