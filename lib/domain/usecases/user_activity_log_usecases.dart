// plastic_factory_management/lib/domain/usecases/user_activity_log_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_activity_log_model.dart';
import '../repositories/user_activity_log_repository.dart';

class UserActivityLogUseCases {
  final UserActivityLogRepository repository;

  UserActivityLogUseCases(this.repository);

  Stream<List<UserActivityLog>> getLogsForUser(String userId) {
    return repository.getLogsForUser(userId);
  }

  Future<void> logActivity({
    required String userId,
    required String action,
    String? details,
  }) async {
    final log = UserActivityLog(
      id: '',
      userId: userId,
      action: action,
      details: details,
      timestamp: Timestamp.now(),
    );
    await repository.addLog(log);
  }
}
