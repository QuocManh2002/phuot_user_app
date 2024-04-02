import 'dart:convert';

import 'package:greenwheel_user_app/core/constants/contact_type.dart';

class EmergencyContactViewModel {
  int? id;
  String? name;
  String? type;
  String? phone;
  String? address;
  String? imageUrl;

  EmergencyContactViewModel({this.id, this.address, this.name, this.phone, this.type, this.imageUrl});

  factory EmergencyContactViewModel.fromJsonByLocation(Map<String, dynamic> json) =>
      EmergencyContactViewModel(
          address: json['address'],
          id:json['id'],
          name: json['name'],
          phone: json['phone'],
          imageUrl: json['imagePath'],
          type: json['type']);
      factory EmergencyContactViewModel.fromJsonByPlan(Map<String, dynamic> json) =>
      EmergencyContactViewModel(
          address: json['address'],
          id: json['id'],
          name: json['name'],
          phone: json['phone'],
          imageUrl: json['imagePath'],
          type: contact_types[int.parse(json['type'].toString())]); 
  Map<String, dynamic> toJson(EmergencyContactViewModel model) => {
        "address": json.encode(model.address),
        "name": json.encode(model.name),
        "phone": json.encode(model.phone),
        "type": model.type,
        "id": model.id
      };
}
