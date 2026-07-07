class OrderResponse {
  int? status;
  String? message;
  List<Order>? orders;

  OrderResponse({this.status, this.message, this.orders});

  factory OrderResponse.fromJson(Map<String, dynamic> json) => OrderResponse(
    status: json["status"],
    message: json["message"],
    orders: json["orders"] == null
        ? []
        : List<Order>.from(json["orders"].map((x) => Order.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "orders": orders == null
        ? []
        : List<dynamic>.from(orders!.map((x) => x.toJson())),
  };
}

class OrderDetailResponse {
  int? status;
  String? message;
  Order? order;

  OrderDetailResponse({this.status, this.message, this.order});

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) =>
      OrderDetailResponse(
        status: json["status"],
        message: json["message"],
        order: json["order"] == null ? null : Order.fromJson(json["order"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "order": order?.toJson(),
  };
}

class Order {
  int? orderNumber;
  int? orderId;
  String? orderUid;
  int? userId;
  int? kitchenId;
  String? deliveryType;
  DeliveryAddress? deliveryAddress;
  String? status;
  String? pickupId;
  double? itemTotal;
  double? gstAmount;
  double? platformFee; // Renamed from flatForm
  double? deliveryFee;
  double? discount;
  double? totalAmount;
  String? paymentMethod;
  String? paymentStatus;
  String? orderedAt;
  String? updatedAt;
  double? distance;
  String? acceptedAt;
  String? preparedAt;
  String? pickedAt;
  String? cancelledAt;
  String? cancelReason;
  String? rating;
  String? pickupStartTime;
  String? pickupEndTime;
  List<OrderItem>? items;
  User? user;
  RestaurantOrderInvoice? restaurantOrderInvoice;

  String get orderDisplayId => orderNumber != null
      ? orderNumber.toString()
      : (orderId != null ? orderId.toString().padLeft(4, '0') : '0000');

  Order({
    this.orderNumber,
    this.orderId,
    this.orderUid,
    this.userId,
    this.kitchenId,
    this.deliveryType,
    this.deliveryAddress,
    this.status,
    this.itemTotal,
    this.gstAmount,
    this.platformFee,
    this.deliveryFee,
    this.discount,
    this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.orderedAt,
    this.updatedAt,
    this.distance,
    this.acceptedAt,
    this.preparedAt,
    this.pickedAt,
    this.cancelledAt,
    this.cancelReason,
    this.rating,
    this.pickupStartTime,
    this.pickupEndTime,
    this.pickupId,
    this.items,
    this.user,
    this.restaurantOrderInvoice,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    orderNumber: json["orderNumber"],
    orderId: json["orderId"],
    orderUid: json["orderUid"],
    userId: json["userId"],
    kitchenId: json["kitchenId"],
    deliveryType: json["deliveryType"],
    deliveryAddress: json["deliveryAddress"] == null
        ? null
        : DeliveryAddress.fromJson(json["deliveryAddress"]),
    status: json["status"],
    itemTotal: json["itemTotal"]?.toDouble(),
    gstAmount: json["gstAmount"]?.toDouble(),
    deliveryFee: json["deliveryFee"]?.toDouble(),
    platformFee: json["platformFee"]?.toDouble(),
    discount: json["discount"]?.toDouble(),
    totalAmount: json["totalAmount"]?.toDouble(),
    paymentMethod: json["paymentMethod"],
    paymentStatus: json["paymentStatus"],
    pickupId: json["pickupId"],
    orderedAt: json["orderedAt"],
    updatedAt: json["updatedAt"],
    distance: json["distance"]?.toDouble(),
    acceptedAt: json["acceptedAt"],
    preparedAt: json["preparedAt"],
    pickedAt: json["pickedAt"],
    cancelledAt: json["cancelledAt"],
    cancelReason: json["cancelReason"],
    rating: json["rating"],
    pickupStartTime: json["pickupStartTime"],
    pickupEndTime: json["pickupEndTime"],
    items: json["items"] == null
        ? []
        : List<OrderItem>.from(json["items"].map((x) => OrderItem.fromJson(x))),
    user: json["user"] == null ? null : User.fromJson(json["user"]),
    restaurantOrderInvoice: json["restaurantOrderInvoice"] == null
        ? null
        : RestaurantOrderInvoice.fromJson(json["restaurantOrderInvoice"]),
  );

  Map<String, dynamic> toJson() => {
    "orderNumber": orderNumber,
    "orderId": orderId,
    "orderUid": orderUid,
    "userId": userId,
    "kitchenId": kitchenId,
    "deliveryType": deliveryType,
    "deliveryAddress": deliveryAddress?.toJson(),
    "status": status,
    "itemTotal": itemTotal,
    "pickupId": pickupId,
    "gstAmount": gstAmount,
    "deliveryFee": deliveryFee,
    "platformFee": platformFee,
    "discount": discount,
    "totalAmount": totalAmount,
    "paymentMethod": paymentMethod,
    "paymentStatus": paymentStatus,
    "orderedAt": orderedAt,
    "updatedAt": updatedAt,
    "distance": distance,
    "acceptedAt": acceptedAt,
    "preparedAt": preparedAt,
    "pickedAt": pickedAt,
    "cancelledAt": cancelledAt,
    "cancelReason": cancelReason,
    "rating": rating,
    "pickupStartTime": pickupStartTime,
    "pickupEndTime": pickupEndTime,
    "items": items == null
        ? []
        : List<dynamic>.from(items!.map((x) => x.toJson())),
    "user": user?.toJson(),
    "restaurantOrderInvoice": restaurantOrderInvoice?.toJson(),
  };
}

class RestaurantOrderInvoice {
  String? invoiceNumber;
  String? pdfUrl;
  double? serviceFeePercent;
  String? createdAt;

  RestaurantOrderInvoice({
    this.invoiceNumber,
    this.pdfUrl,
    this.serviceFeePercent,
    this.createdAt,
  });

  factory RestaurantOrderInvoice.fromJson(Map<String, dynamic> json) =>
      RestaurantOrderInvoice(
        invoiceNumber: json["invoiceNumber"],
        pdfUrl: json["pdfUrl"],
        serviceFeePercent: json["serviceFeePercent"]?.toDouble(),
        createdAt: json["createdAt"],
      );

  Map<String, dynamic> toJson() => {
    "invoiceNumber": invoiceNumber,
    "pdfUrl": pdfUrl,
    "serviceFeePercent": serviceFeePercent,
    "createdAt": createdAt,
  };
}

class DeliveryAddress {
  int? id;
  String? name;
  String? email;
  int? userId;
  String? pincode;
  String? building;
  int? isActive;
  String? landmark;
  String? createdAt;
  bool? isDefault;
  String? updatedAt;
  String? addressType;
  String? houseNumber;
  String? contactNumber;

  DeliveryAddress({
    this.id,
    this.name,
    this.email,
    this.userId,
    this.pincode,
    this.building,
    this.isActive,
    this.landmark,
    this.createdAt,
    this.isDefault,
    this.updatedAt,
    this.addressType,
    this.houseNumber,
    this.contactNumber,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      DeliveryAddress(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        userId: json["userId"],
        pincode: json["pincode"],
        building: json["building"],
        isActive: json["isActive"],
        landmark: json["landmark"],
        createdAt: json["createdAt"],
        isDefault: json["isDefault"],
        updatedAt: json["updatedAt"],
        addressType: json["addressType"],
        houseNumber: json["houseNumber"],
        contactNumber: json["contactNumber"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "userId": userId,
    "pincode": pincode,
    "building": building,
    "isActive": isActive,
    "landmark": landmark,
    "createdAt": createdAt,
    "isDefault": isDefault,
    "updatedAt": updatedAt,
    "addressType": addressType,
    "houseNumber": houseNumber,
    "contactNumber": contactNumber,
  };
}

class OrderItem {
  int? orderItemId;
  int? orderId;
  int? menuItemId;
  int? quantity;
  double? price;
  double? totalPrice;
  String? itemQuantityLabel;
  MenuItem? menu;

  OrderItem({
    this.orderItemId,
    this.orderId,
    this.menuItemId,
    this.quantity,
    this.price,
    this.totalPrice,
    this.itemQuantityLabel,
    this.menu,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    orderItemId: json["orderItemId"],
    orderId: json["orderId"],
    menuItemId: json["menuItemId"],
    quantity: json["quantity"],
    price: json["price"]?.toDouble(),
    totalPrice: json["totalPrice"]?.toDouble(),
    itemQuantityLabel: json["itemQuantityLabel"],
    menu: json["menu"] == null ? null : MenuItem.fromJson(json["menu"]),
  );

  Map<String, dynamic> toJson() => {
    "orderItemId": orderItemId,
    "orderId": orderId,
    "menuItemId": menuItemId,
    "quantity": quantity,
    "price": price,
    "totalPrice": totalPrice,
    "itemQuantityLabel": itemQuantityLabel,
    "menu": menu?.toJson(),
  };
}

class MenuItem {
  String? name;
  int? price;
  String? quantity;
  bool? isVegetarian;
  dynamic isSpicy;

  MenuItem({
    this.name,
    this.price,
    this.quantity,
    this.isVegetarian,
    this.isSpicy,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    name: json["name"],
    price: json["price"],
    quantity: json["quantity"]?.toString(),
    isVegetarian: json["isVegetarian"],
    isSpicy: json["isSpicy"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "price": price,
    "quantity": quantity,
    "isVegetarian": isVegetarian,
    "isSpicy": isSpicy,
  };
}

class User {
  String? name;
  String? phoneNumber;
  String? profilePicture;

  User({this.name, this.phoneNumber, this.profilePicture});

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json["name"],
    phoneNumber: json["phoneNumber"],
    profilePicture: json["profilePicture"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "phoneNumber": phoneNumber,
    "profilePicture": profilePicture,
  };
}

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  picked,
  noShow,
  cancelled,
  rejected,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return "PENDING";
      case OrderStatus.accepted:
        return "ACCEPTED";
      case OrderStatus.preparing:
        return "PREPARING";
      case OrderStatus.ready:
        return "READY";
      case OrderStatus.picked:
        return "PICKED";
      case OrderStatus.noShow:
        return "NO_SHOW";
      case OrderStatus.cancelled:
        return "CANCELLED";
      case OrderStatus.rejected:
        return "REJECTED";
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return OrderStatus.pending;
      case "ACCEPTED":
        return OrderStatus.accepted;
      case "PREPARING":
        return OrderStatus.preparing;
      case "READY":
        return OrderStatus.ready;
      case "PICKED":
        return OrderStatus.picked;
      case "NO_SHOW":
        return OrderStatus.noShow;
      case "CANCELLED":
        return OrderStatus.cancelled;
      case "REJECTED":
        return OrderStatus.rejected;
      default:
        return OrderStatus.pending;
    }
  }
}
