// To parse this JSON data, do
//
//     final ordersDetailsModel = ordersDetailsModelFromJson(jsonString);

import 'dart:convert';

OrdersDetailsModel ordersDetailsModelFromJson(String str) =>
    OrdersDetailsModel.fromJson(json.decode(str));

String ordersDetailsModelToJson(OrdersDetailsModel data) =>
    json.encode(data.toJson());

class OrdersDetailsModel {
  int? status;
  String? message;
  Order? order;

  OrdersDetailsModel({
    this.status,
    this.message,
    this.order,
  });

  factory OrdersDetailsModel.fromJson(Map<String, dynamic> json) =>
      OrdersDetailsModel(
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
  String? orderDisplayId;
  int? orderId;
  int? userId;
  int? kitchenId;
  String? deliveryType;
  String? status;
  double? itemTotal;
  double? gstAmount;
  double? platformFee;
  double? discount;
  double? totalAmount;
  String? pickupId;
  String? paymentMethod;
  String? paymentStatus;
  DateTime? orderedAt;
  DateTime? updatedAt;
  DateTime? acceptedAt;
  DateTime? preparedAt;
  dynamic cancelReason;
  DateTime? cancelledAt;
  DateTime? pickedAt;
  String? rating;
  String? pickupStartTime;
  String? pickupEndTime;
  Kitchen? kitchen;
  List<Item>? items;
  OrderInvoice? orderInvoice;
  double? taxPercent;

  Order({
    this.orderDisplayId,
    this.orderId,
    this.userId,
    this.kitchenId,
    this.deliveryType,
    this.status,
    this.itemTotal,
    this.gstAmount,
    this.platformFee,
    this.discount,
    this.totalAmount,
    this.pickupId,
    this.paymentMethod,
    this.paymentStatus,
    this.orderedAt,
    this.updatedAt,
    this.acceptedAt,
    this.preparedAt,
    this.cancelReason,
    this.cancelledAt,
    this.pickedAt,
    this.rating,
    this.pickupStartTime,
    this.pickupEndTime,
    this.kitchen,
    this.items,
    this.orderInvoice,
    this.taxPercent,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderDisplayId: json["orderDisplayId"],
        orderId: json["orderId"],
        userId: json["userId"],
        kitchenId: json["kitchenId"],
        deliveryType: json["deliveryType"],
        status: json["status"],
        itemTotal: json["itemTotal"]?.toDouble(),
        gstAmount: json["gstAmount"]?.toDouble(),
        platformFee: json["platformFee"]?.toDouble(),
        discount: json["discount"]?.toDouble(),
        totalAmount: json["totalAmount"]?.toDouble(),
        pickupId: json["pickupId"],
        paymentMethod: json["paymentMethod"],
        paymentStatus: json["paymentStatus"],
        orderedAt: json["orderedAt"] == null
            ? null
            : DateTime.parse(json["orderedAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        acceptedAt: json["acceptedAt"] == null
            ? null
            : DateTime.parse(json["acceptedAt"]),
        preparedAt: json["preparedAt"] == null
            ? null
            : DateTime.parse(json["preparedAt"]),
        cancelReason: json["cancelReason"],
        cancelledAt: json["cancelledAt"] == null
            ? null
            : DateTime.parse(json["cancelledAt"]),
        pickedAt:
            json["pickedAt"] == null ? null : DateTime.parse(json["pickedAt"]),
        rating: json["rating"],
        pickupStartTime: json["pickupStartTime"],
        pickupEndTime: json["pickupEndTime"],
        kitchen:
            json["kitchen"] == null ? null : Kitchen.fromJson(json["kitchen"]),
        items: json["items"] == null
            ? []
            : List<Item>.from(json["items"]!.map((x) => Item.fromJson(x))),
        orderInvoice: json["orderInvoice"] == null
            ? null
            : OrderInvoice.fromJson(json["orderInvoice"]),
        taxPercent: json["taxPercent"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "orderDisplayId": orderDisplayId,
        "orderId": orderId,
        "userId": userId,
        "kitchenId": kitchenId,
        "deliveryType": deliveryType,
        "status": status,
        "itemTotal": itemTotal,
        "gstAmount": gstAmount,
        "platformFee": platformFee,
        "discount": discount,
        "totalAmount": totalAmount,
        "pickupId": pickupId,
        "paymentMethod": paymentMethod,
        "paymentStatus": paymentStatus,
        "orderedAt": orderedAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "acceptedAt": acceptedAt?.toIso8601String(),
        "preparedAt": preparedAt?.toIso8601String(),
        "cancelReason": cancelReason,
        "cancelledAt": cancelledAt?.toIso8601String(),
        "pickedAt": pickedAt?.toIso8601String(),
        "rating": rating,
        "pickupStartTime": pickupStartTime,
        "pickupEndTime": pickupEndTime,
        "kitchen": kitchen?.toJson(),
        "items": items == null
            ? []
            : List<dynamic>.from(items!.map((x) => x.toJson())),
        "orderInvoice": orderInvoice?.toJson(),
        "taxPercent": taxPercent,
      };
}

class Item {
  int? menuItemId;
  String? name;
  int? quantity;
  String? image;
  String? startTime;
  String? endTime;

  Item({
    this.menuItemId,
    this.name,
    this.quantity,
    this.image,
    this.startTime,
    this.endTime,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        menuItemId: json["menuItemId"],
        name: json["name"],
        quantity: json["quantity"],
        image: json["image"],
        startTime: json["startTime"],
        endTime: json["endTime"],
      );

  Map<String, dynamic> toJson() => {
        "menuItemId": menuItemId,
        "name": name,
        "quantity": quantity,
        "image": image,
        "startTime": startTime,
        "endTime": endTime,
      };
}

class Kitchen {
  int? kitchenId;
  String? kitchenName;
  String? kitchenImage;
  Photos? photos;
  Address? address;
  Timezone? timezone;

  Kitchen({
    this.kitchenId,
    this.kitchenName,
    this.kitchenImage,
    this.photos,
    this.address,
    this.timezone,
  });

  factory Kitchen.fromJson(Map<String, dynamic> json) => Kitchen(
        kitchenId: json["kitchenId"],
        kitchenName: json["kitchenName"],
        kitchenImage: json["kitchenImage"],
        photos: json["photos"] == null ? null : Photos.fromJson(json["photos"]),
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
        timezone: json["timezone"] == null
            ? null
            : Timezone.fromJson(json["timezone"]),
      );

  Map<String, dynamic> toJson() => {
        "kitchenId": kitchenId,
        "kitchenName": kitchenName,
        "kitchenImage": kitchenImage,
        "photos": photos?.toJson(),
        "address": address?.toJson(),
        "timezone": timezone?.toJson(),
      };
}

class OrderInvoice {
  int? invoiceId;
  int? orderId;
  String? invoiceNumber;
  String? pdfUrl;
  DateTime? createdAt;

  OrderInvoice({
    this.invoiceId,
    this.orderId,
    this.invoiceNumber,
    this.pdfUrl,
    this.createdAt,
  });

  factory OrderInvoice.fromJson(Map<String, dynamic> json) => OrderInvoice(
        invoiceId: json["invoiceId"],
        orderId: json["orderId"],
        invoiceNumber: json["invoiceNumber"],
        pdfUrl: json["pdfUrl"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
      );

  Map<String, dynamic> toJson() => {
        "invoiceId": invoiceId,
        "orderId": orderId,
        "invoiceNumber": invoiceNumber,
        "pdfUrl": pdfUrl,
        "createdAt": createdAt?.toIso8601String(),
      };
}

class Address {
  int? addressId;
  int? kitchenId;
  String? houseNo;
  String? street;
  String? pincode;
  String? state;
  String? city;
  String? country;
  String? landmark;
  double? latitude;
  double? longitude;

  Address({
    this.addressId,
    this.kitchenId,
    this.houseNo,
    this.street,
    this.pincode,
    this.state,
    this.city,
    this.country,
    this.landmark,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json["addressId"],
        kitchenId: json["kitchenId"],
        houseNo: json["houseNo"],
        street: json["street"],
        pincode: json["pincode"],
        state: json["state"],
        city: json["city"],
        country: json["country"],
        landmark: json["landmark"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "addressId": addressId,
        "kitchenId": kitchenId,
        "houseNo": houseNo,
        "street": street,
        "pincode": pincode,
        "state": state,
        "city": city,
        "country": country,
        "landmark": landmark,
        "latitude": latitude,
        "longitude": longitude,
      };
}

class Photos {
  String? kitchenProfilePhoto;

  Photos({
    this.kitchenProfilePhoto,
  });

  factory Photos.fromJson(Map<String, dynamic> json) => Photos(
        kitchenProfilePhoto: json["kitchenProfilePhoto"],
      );

  Map<String, dynamic> toJson() => {
        "kitchenProfilePhoto": kitchenProfilePhoto,
      };
}

class Timezone {
  int? id;
  String? name;
  String? displayName;
  String? offset;

  Timezone({
    this.id,
    this.name,
    this.displayName,
    this.offset,
  });

  factory Timezone.fromJson(Map<String, dynamic> json) => Timezone(
        id: json["id"],
        name: json["name"],
        displayName: json["displayName"],
        offset: json["offset"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "displayName": displayName,
        "offset": offset,
      };
}
