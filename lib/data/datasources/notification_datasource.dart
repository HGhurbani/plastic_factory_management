import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  Future<void> addNotification(AppNotification notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}
