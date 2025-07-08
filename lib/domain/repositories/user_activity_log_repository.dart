// plastic_factory_management/lib/domain/repositories/user_activity_log_repository.dart

import '../../data/models/user_activity_log_model.dart';

abstract class UserActivityLogRepository {
  Stream<List<UserActivityLog>> getLogsForUser(String userId);
  Future<void> addLog(UserActivityLog log);
}
