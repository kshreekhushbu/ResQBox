class MonthlyInvoiceResponse {
  final int status;
  final String message;
  final int count;
  final List<MonthlyInvoice> invoices;

  MonthlyInvoiceResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.invoices,
  });

  factory MonthlyInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyInvoiceResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      invoices:
          (json['invoices'] as List<dynamic>?)
              ?.map((item) => MonthlyInvoice.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class MonthlyInvoice {
  final int invoiceId;
  final int kitchenId;
  final String invoiceNumber;
  final int month;
  final int year;
  final String periodStart;
  final String periodEnd;
  final String totalOrderAmount;
  final String platformFeeAmount;
  final String netAmount;
  final int ordersCount;
  final String pdfUrl;
  final String createdAt;

  MonthlyInvoice({
    required this.invoiceId,
    required this.kitchenId,
    required this.invoiceNumber,
    required this.month,
    required this.year,
    required this.periodStart,
    required this.periodEnd,
    required this.totalOrderAmount,
    required this.platformFeeAmount,
    required this.netAmount,
    required this.ordersCount,
    required this.pdfUrl,
    required this.createdAt,
  });

  factory MonthlyInvoice.fromJson(Map<String, dynamic> json) {
    return MonthlyInvoice(
      invoiceId: json['invoiceId'] ?? 0,
      kitchenId: json['kitchenId'] ?? 0,
      invoiceNumber: json['invoiceNumber'] ?? '',
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      periodStart: json['periodStart'] ?? '',
      periodEnd: json['periodEnd'] ?? '',
      totalOrderAmount: json['totalOrderAmount']?.toString() ?? '0',
      platformFeeAmount: json['platformFeeAmount']?.toString() ?? '0',
      netAmount: json['netAmount']?.toString() ?? '0',
      ordersCount: json['ordersCount'] ?? 0,
      pdfUrl: json['pdfUrl'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
