// plastic_factory_management/lib/domain/repositories/maintenance_repository.dart

import 'package:plastic_factory_management/data/models/maintenance_log_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';

abstract class MaintenanceRepository {
  Stream<List<MaintenanceLogModel>> getMaintenanceLogs();
  Stream<List<MaintenanceLogModel>> getScheduledMaintenance({String? machineId, String? responsibleUid});
  Stream<List<MaintenanceLogModel>> getCompletedMaintenance();
  Future<void> addMaintenanceLog(MaintenanceLogModel log);
  Future<void> updateMaintenanceLog(MaintenanceLogModel log);
  Future<void> deleteMaintenanceLog(String logId);
  Future<MaintenanceLogModel?> getMaintenanceLogById(String logId);

  Stream<List<MachineModel>> getAllMachines(); // لتمكين اختيار الآلة في الصيانة
}