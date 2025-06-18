import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationUseCases {
  final NotificationRepository repository;

  NotificationUseCases(this.repository);

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return repository.getUserNotifications(userId);
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: title,
      message: message,
      createdAt: Timestamp.now(),
      read: false,
    );
    await repository.addNotification(notification);
  }

  Future<void> markAsRead(String notificationId) {
    return repository.markAsRead(notificationId);
  }
}
