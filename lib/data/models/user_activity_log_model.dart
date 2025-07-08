// plastic_factory_management/lib/data/models/user_activity_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivityLog {
  final String id;
  final String userId;
  final String action;
  final String? details;
  final Timestamp timestamp;

  UserActivityLog({
    required this.id,
    required this.userId,
    required this.action,
    this.details,
    required this.timestamp,
  });

  factory UserActivityLog.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserActivityLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      details: data['details'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      'details': details,
      'timestamp': timestamp,
    };
  }
}
