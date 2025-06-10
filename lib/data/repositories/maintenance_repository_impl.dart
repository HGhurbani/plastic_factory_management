// plastic_factory_management/lib/data/repositories/maintenance_repository_impl.dart

import 'package:plastic_factory_management/data/datasources/maintenance_datasource.dart';
import 'package:plastic_factory_management/data/models/maintenance_log_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/domain/repositories/maintenance_repository.dart'; // سنقوم بإنشاء هذا لاحقاً

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final MaintenanceDatasource datasource;

  MaintenanceRepositoryImpl(this.datasource);

  @override
  Stream<List<MaintenanceLogModel>> getMaintenanceLogs() {
    return datasource.getMaintenanceLogs();
  }

  @override
  Stream<List<MaintenanceLogModel>> getScheduledMaintenance({String? machineId, String? responsibleUid}) {
    return datasource.getScheduledMaintenance(machineId: machineId, responsibleUid: responsibleUid);
  }

  @override
  Stream<List<MaintenanceLogModel>> getCompletedMaintenance() {
    return datasource.getCompletedMaintenance();
  }

  @override
  Future<void> addMaintenanceLog(MaintenanceLogModel log) {
    return datasource.addMaintenanceLog(log);
  }

  @override
  Future<void> updateMaintenanceLog(MaintenanceLogModel log) {
    return datasource.updateMaintenanceLog(log);
  }

  @override
  Future<void> deleteMaintenanceLog(String logId) {
    return datasource.deleteMaintenanceLog(logId);
  }

  @override
  Future<MaintenanceLogModel?> getMaintenanceLogById(String logId) {
    return datasource.getMaintenanceLogById(logId);
  }

  @override
  Stream<List<MachineModel>> getAllMachines() {
    return datasource.getAllMachines();
  }
}