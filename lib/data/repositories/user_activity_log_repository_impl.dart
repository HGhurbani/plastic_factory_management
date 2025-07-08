// plastic_factory_management/lib/data/repositories/user_activity_log_repository_impl.dart

import '../datasources/user_activity_log_datasource.dart';
import '../models/user_activity_log_model.dart';
import '../../domain/repositories/user_activity_log_repository.dart';

class UserActivityLogRepositoryImpl implements UserActivityLogRepository {
  final UserActivityLogDatasource datasource;

  UserActivityLogRepositoryImpl(this.datasource);

  @override
  Stream<List<UserActivityLog>> getLogsForUser(String userId) {
    return datasource.getLogsForUser(userId);
  }

  @override
  Future<void> addLog(UserActivityLog log) {
    return datasource.addLog(log);
  }
}
