// plastic_factory_management/lib/data/datasources/user_activity_log_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_activity_log_model.dart';

class UserActivityLogDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserActivityLog>> getLogsForUser(String userId) {
    return _firestore
        .collection('user_activity_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserActivityLog.fromDocumentSnapshot(doc))
            .toList());
  }

  Future<void> addLog(UserActivityLog log) async {
    await _firestore.collection('user_activity_logs').add(log.toMap());
  }
}
