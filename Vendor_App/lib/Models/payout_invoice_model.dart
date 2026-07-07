class PayoutInvoicesResponse {
  final int status;
  final String message;
  final int count;
  final List<PayoutInvoice> invoices;

  PayoutInvoicesResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.invoices,
  });

  factory PayoutInvoicesResponse.fromJson(Map<String, dynamic> json) {
    return PayoutInvoicesResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      invoices:
          (json['invoices'] as List<dynamic>?)
              ?.map((item) => PayoutInvoice.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'count': count,
      'invoices': invoices.map((item) => item.toJson()).toList(),
    };
  }
}

class PayoutInvoice {
  final int payoutId;
  final int kitchenId;
  final String periodStart;
  final String periodEnd;
  final String totalOrderAmount;
  final String platformFeeAmount;
  final String payoutAmount;
  final int ordersCount;
  final String stripeTransferId;
  final String createdAt;

  PayoutInvoice({
    required this.payoutId,
    required this.kitchenId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalOrderAmount,
    required this.platformFeeAmount,
    required this.payoutAmount,
    required this.ordersCount,
    required this.stripeTransferId,
    required this.createdAt,
  });

  factory PayoutInvoice.fromJson(Map<String, dynamic> json) {
    return PayoutInvoice(
      payoutId: json['payoutId'] ?? 0,
      kitchenId: json['kitchenId'] ?? 0,
      periodStart: json['periodStart'] ?? '',
      periodEnd: json['periodEnd'] ?? '',
      totalOrderAmount: json['totalOrderAmount']?.toString() ?? '0',
      platformFeeAmount: json['platformFeeAmount']?.toString() ?? '0',
      payoutAmount: json['payoutAmount']?.toString() ?? '0',
      ordersCount: json['ordersCount'] ?? 0,
      stripeTransferId: json['stripeTransferId'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payoutId': payoutId,
      'kitchenId': kitchenId,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'totalOrderAmount': totalOrderAmount,
      'platformFeeAmount': platformFeeAmount,
      'payoutAmount': payoutAmount,
      'ordersCount': ordersCount,
      'stripeTransferId': stripeTransferId,
      'createdAt': createdAt,
    };
  }
}
