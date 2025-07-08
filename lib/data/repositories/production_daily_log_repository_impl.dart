// plastic_factory_management/lib/data/repositories/production_daily_log_repository_impl.dart

import 'package:plastic_factory_management/data/datasources/production_daily_log_datasource.dart';
import 'package:plastic_factory_management/data/models/production_daily_log_model.dart';
import 'package:plastic_factory_management/domain/repositories/production_daily_log_repository.dart';

class ProductionDailyLogRepositoryImpl implements ProductionDailyLogRepository {
  final ProductionDailyLogDatasource datasource;
  ProductionDailyLogRepositoryImpl(this.datasource);

  @override
  Stream<List<ProductionDailyLogModel>> getLogsForOrder(String orderId) {
    return datasource.getLogsForOrder(orderId);
  }

  @override
  Future<void> addLog(ProductionDailyLogModel log) {
    return datasource.addLog(log);
  }
}
