// plastic_factory_management/lib/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // يتم تخزينها كنص (e.g., 'factory_manager')
  final String? employeeId;
  final Timestamp createdAt;
  final Timestamp? termsAcceptedAt; // تاريخ قبول المستخدم للشروط

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.employeeId,
    required this.createdAt,
    this.termsAcceptedAt,
  });

  // التحويل من Map ( Firestore document) إلى كائن UserModel
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      role: data['role'] as String,
      employeeId: data['employeeId'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      termsAcceptedAt: data['termsAcceptedAt'] as Timestamp?,
    );
  }

  // التحويل من DocumentSnapshot إلى كائن UserModel
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id, // UID هو معرف المستند
      email: data['email'] as String,
      name: data['name'] as String,
      role: data['role'] as String,
      employeeId: data['employeeId'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      termsAcceptedAt: data['termsAcceptedAt'] as Timestamp?,
    );
  }

  // التحويل من كائن UserModel إلى Map (لتخزينه في Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'employeeId': employeeId,
      'createdAt': createdAt,
      'termsAcceptedAt': termsAcceptedAt,
    };
  }

  // دالة مساعدة للحصول على الدور كـ Enum
  UserRole get userRoleEnum => UserRoleExtension.fromString(role);

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? employeeId,
    Timestamp? createdAt,
    Timestamp? termsAcceptedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      createdAt: createdAt ?? this.createdAt,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
    );
  }

  // دالة مساعدة للحصول على الدور كـ Enum
  // UserRole get userRoleEnum => UserRoleExtension.fromString(role);
}
