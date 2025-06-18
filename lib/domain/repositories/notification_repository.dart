import '../../data/models/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> getUserNotifications(String userId);
  Future<void> addNotification(AppNotification notification);
  Future<void> markAsRead(String notificationId);
}
