class TransactionsResponse {
  final int status;
  final List<Transaction> data;

  TransactionsResponse({required this.status, required this.data});

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    return TransactionsResponse(
      status: json['status'] ?? 0,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => Transaction.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class Transaction {
  final int orderId;
  final int? orderNumber;
  final String customerName;
  final num amount;
  final String date;

  Transaction({
    required this.orderId,
    this.orderNumber,
    required this.customerName,
    required this.amount,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      orderId: json['orderId'] ?? 0,
      orderNumber: json['orderNumber'],
      customerName: json['customerName'] ?? '',
      amount: json['amount'] ?? 0,
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'amount': amount,
      'date': date,
    };
  }
}
