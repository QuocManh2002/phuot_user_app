class ProductViewModel {
  int id;
  String name;
  String paymentType;
  int price;
  String thumbnailUrl;
  int supplierId;
  String supplierName;
  int? partySize;
  String? supplierThumbnailUrl;
  String? supplierPhone;
  String? supplierAddress;

  ProductViewModel({
    required this.id,
    required this.name,
    required this.paymentType,
    required this.price,
    required this.thumbnailUrl,
    required this.supplierId,
    required this.supplierName,
    required this.partySize,
    this.supplierThumbnailUrl,
    this.supplierPhone,
    this.supplierAddress
  });

  factory ProductViewModel.fromJson(Map<String, dynamic> json) =>
      ProductViewModel(
        id: json["id"],
        name: json["name"],
        paymentType: json["paymentType"],
        price: json["price"],
        thumbnailUrl: json["imageUrl"],
        supplierId: json["supplier"]["id"],
        supplierName: json["supplier"]["name"],
        partySize: json["partySize"],
        supplierThumbnailUrl: json['supplier']['imageUrl'],
        supplierPhone: json['supplier']['phone'],
        supplierAddress: json['supplier']['address']
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "paymentType": paymentType,
        "originalPrice": price,
        "thumbnailUrl": thumbnailUrl,
        "supplierId": supplierId,
        "supplierName": supplierName,
        "partySize": partySize,
      };
}
