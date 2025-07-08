// plastic_factory_management/lib/domain/repositories/production_daily_log_repository.dart

import 'package:plastic_factory_management/data/models/production_daily_log_model.dart';

abstract class ProductionDailyLogRepository {
  Stream<List<ProductionDailyLogModel>> getLogsForOrder(String orderId);
  Future<void> addLog(ProductionDailyLogModel log);
}
