class PayoutInvoiceDetailsResponse {
  final int status;
  final String message;
  final PayoutInvoiceDetails? data;

  PayoutInvoiceDetailsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PayoutInvoiceDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PayoutInvoiceDetailsResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PayoutInvoiceDetails.fromJson(json['data'])
          : null,
    );
  }
}

class PayoutInvoiceDetails {
  final int payoutId;
  final String invoiceNumber;
  final String pdfUrl;
  final String periodStart;
  final String periodEnd;
  final InvoiceSummary summary;
  final List<InvoiceOrder> orders;

  PayoutInvoiceDetails({
    required this.payoutId,
    required this.invoiceNumber,
    required this.pdfUrl,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.orders,
  });

  factory PayoutInvoiceDetails.fromJson(Map<String, dynamic> json) {
    return PayoutInvoiceDetails(
      payoutId: json['payoutId'] ?? 0,
      invoiceNumber: json['invoiceNumber'] ?? '',
      pdfUrl: json['pdfUrl'] ?? '',
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

class InvoiceSummary {
  final num totalOrders;
  final num totalAmount;
  final num gstAmount;
  final num platformFeeDeducted;
  final num netPayout;
  final InvoiceBreakdown? breakdown;

  InvoiceSummary({
    required this.totalOrders,
    required this.totalAmount,
    required this.gstAmount,
    required this.platformFeeDeducted,
    required this.netPayout,
    this.breakdown,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      totalOrders: json['totalOrders'] ?? 0,
      totalAmount: json['totalAmount'] ?? 0,
      gstAmount: json['gstAmount'] ?? 0,
      platformFeeDeducted: json['platformFeeDeducted'] ?? 0,
      netPayout: json['netPayout'] ?? 0,
      breakdown: json['breakdown'] != null
          ? InvoiceBreakdown.fromJson(json['breakdown'])
          : null,
    );
  }
}

class InvoiceBreakdown {
  final BreakdownItem listedPrice;
  final BreakdownItem serviceFee;
  final BreakdownItem totalPayout;

  InvoiceBreakdown({
    required this.listedPrice,
    required this.serviceFee,
    required this.totalPayout,
  });

  factory InvoiceBreakdown.fromJson(Map<String, dynamic> json) {
    return InvoiceBreakdown(
      listedPrice: BreakdownItem.fromJson(json['listedPrice'] ?? {}),
      serviceFee: BreakdownItem.fromJson(json['serviceFee'] ?? {}),
      totalPayout: BreakdownItem.fromJson(json['totalPayout'] ?? {}),
    );
  }
}

class BreakdownItem {
  final num gst;
  final num netAmount;
  final num total;

  BreakdownItem({
    required this.gst,
    required this.netAmount,
    required this.total,
  });

  factory BreakdownItem.fromJson(Map<String, dynamic> json) {
    return BreakdownItem(
      gst: json['gst'] ?? 0,
      netAmount: json['netAmount'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class InvoiceOrder {
  final int orderId;
  final String orderDisplayId;
  final num totalAmount;
  final num platformFee;
  final num gstAmount;
  final num quantity;
  final String status;
  final String orderedAt;
  final List<InvoiceOrderItem> items;

  InvoiceOrder({
    required this.orderId,
    required this.orderDisplayId,
    required this.totalAmount,
    required this.platformFee,
    required this.gstAmount,
    required this.quantity,
    required this.status,
    required this.orderedAt,
    required this.items,
  });

  factory InvoiceOrder.fromJson(Map<String, dynamic> json) {
    return InvoiceOrder(
      orderId: json['orderId'] ?? 0,
      orderDisplayId: json['orderDisplayId'] ?? '',
      totalAmount: json['totalAmount'] ?? 0,
      platformFee: json['platformFee'] ?? 0,
      gstAmount: json['gstAmount'] ?? 0,
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? '',
      orderedAt: json['orderedAt'] ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceOrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class InvoiceOrderItem {
  final String name;
  final num quantity;
  final num price;

  InvoiceOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory InvoiceOrderItem.fromJson(Map<String, dynamic> json) {
    return InvoiceOrderItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
    );
  }
}
