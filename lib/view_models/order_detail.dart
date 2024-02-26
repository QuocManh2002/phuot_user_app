// To parse this JSON data, do
//
//     final orderDetail = orderDetailFromJson(jsonString);

import 'dart:convert';

OrderDetailViewModel orderDetailFromJson(String str) => OrderDetailViewModel.fromJson(json.decode(str));

String orderDetailToJson(OrderDetailViewModel data) => json.encode(data.toJson());

class OrderDetailViewModel {
    int id;
    String productName;
    int quantity;
    double price;
    double unitPrice;

    OrderDetailViewModel({
        required this.id,
        required this.productName,
        required this.quantity,
        required this.price,
        required this.unitPrice
    });

    factory OrderDetailViewModel.fromJson(Map<String, dynamic> json) => OrderDetailViewModel(
        id: json["id"],
        productName: json["product"]["name"],
        quantity: json["quantity"],
        price: double.parse(json["price"].toString()),
        unitPrice: double.parse(json['product']['price'].toString())
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "productName": productName,
        "quantity": quantity,
        "price": price,
    };
}
