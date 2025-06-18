import '../datasources/notification_datasource.dart';
import '../models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDatasource datasource;

  NotificationRepositoryImpl(this.datasource);

  @override
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return datasource.getUserNotifications(userId);
  }

  @override
  Future<void> addNotification(AppNotification notification) {
    return datasource.addNotification(notification);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return datasource.markAsRead(notificationId);
  }
}
