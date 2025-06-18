// plastic_factory_management/lib/data/models/customer_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id; // Firestore document ID
  final String name; // اسم العميل
  final String contactPerson; // الشخص المسؤول للتواصل
  final String phone; // رقم الهاتف
  final String? email; // البريد الإلكتروني (اختياري)
  final String? address; // العنوان الكامل (اختياري)
  final Timestamp createdAt; // تاريخ إنشاء حساب العميل

  CustomerModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.email,
    this.address,
    required this.createdAt,
  });

  factory CustomerModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    Timestamp? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}