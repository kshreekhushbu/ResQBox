class DashboardResponse {
  int? status;
  String? message;
  DashboardData? data;

  DashboardResponse({this.status, this.message, this.data});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? DashboardData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data?.toJson()};
  }
}

class DashboardData {
  num? totalIncome;
  DashboardSummary? summary;

  DashboardData({this.totalIncome, this.summary});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalIncome: json['totalIncome'],
      summary: json['summary'] != null
          ? DashboardSummary.fromJson(json['summary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'totalIncome': totalIncome, 'summary': summary?.toJson()};
  }
}

class DashboardSummary {
  String? type;
  int? orders;
  num? revenue;
  int? cancelledOrders;

  DashboardSummary({
    this.type,
    this.orders,
    this.revenue,
    this.cancelledOrders,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      type: json['type'],
      orders: json['orders'],
      revenue: json['revenue'],
      cancelledOrders: json['cancelledOrders'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'orders': orders,
      'revenue': revenue,
      'cancelledOrders': cancelledOrders,
    };
  }
}
