// plastic_factory_management/lib/domain/usecases/maintenance_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/maintenance_log_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart'; // لاستخدام بيانات المستخدم
import 'package:plastic_factory_management/domain/repositories/maintenance_repository.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/machinery_operator_usecases.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';

class MaintenanceUseCases {
  final MaintenanceRepository repository;
  final InventoryUseCases inventoryUseCases;
  final MachineryOperatorUseCases machineryUseCases;

  MaintenanceUseCases(
    this.repository,
    this.inventoryUseCases,
    this.machineryUseCases,
  );

  Stream<List<MaintenanceLogModel>> getMaintenanceLogs() {
    return repository.getMaintenanceLogs();
  }

  Stream<List<MaintenanceLogModel>> getScheduledMaintenance({String? machineId, String? responsibleUid}) {
    return repository.getScheduledMaintenance(machineId: machineId, responsibleUid: responsibleUid);
  }

  Stream<List<MaintenanceLogModel>> getCompletedMaintenance() {
    return repository.getCompletedMaintenance();
  }

  Future<void> scheduleMaintenance({
    required MachineModel selectedMachine,
    required DateTime maintenanceDateTime,
    required MaintenanceType type,
    required UserModel responsibleUser,
    required MaintenanceAssetType assetType,
    double? meterReading,
    List<MaintenanceSparePart> sparePartsUsed = const [],
    String? notes,
    required List<String> checklistTasks,
  }) async {
    final newLog = MaintenanceLogModel(
      id: '', // Firestore will generate
      machineId: selectedMachine.id,
      machineName: selectedMachine.name,
      maintenanceDate: Timestamp.fromDate(maintenanceDateTime),
      type: type,
      assetType: assetType,
      responsibleUid: responsibleUser.uid,
      responsibleName: responsibleUser.name,
      notes: notes,
      meterReading: meterReading,
      sparePartsUsed: sparePartsUsed,
      checklist: checklistTasks.map((task) => MaintenanceChecklistItem(task: task)).toList(),
      status: 'scheduled',
    );
    await repository.addMaintenanceLog(newLog);
    // Update machine status to under maintenance immediately
    await machineryUseCases.updateMachineStatus(
      selectedMachine.id,
      MachineStatus.underMaintenance,
    );
  }

  Future<void> updateMaintenanceLog({
    required String id,
    required String machineId,
    required String machineName,
    required DateTime maintenanceDate,
    required MaintenanceType type,
    required MaintenanceAssetType assetType,
    required String responsibleUid,
    required String responsibleName,
    String? notes,
    double? meterReading,
    List<MaintenanceSparePart> sparePartsUsed = const [],
    required List<MaintenanceChecklistItem> checklist,
    required String status,
  }) async {
    final updatedLog = MaintenanceLogModel(
      id: id,
      machineId: machineId,
      machineName: machineName,
      maintenanceDate: Timestamp.fromDate(maintenanceDate),
      type: type,
      assetType: assetType,
      responsibleUid: responsibleUid,
      responsibleName: responsibleName,
      notes: notes,
      meterReading: meterReading,
      sparePartsUsed: sparePartsUsed,
      checklist: checklist,
      status: status,
    );
    await repository.updateMaintenanceLog(updatedLog);
  }

  Future<void> completeMaintenanceTask({
    required MaintenanceLogModel log,
    required UserModel completer,
    required List<MaintenanceChecklistItem> updatedChecklist,
    String? finalNotes,
  }) async {
    // Check if all checklist items are completed before marking the log as 'completed'
    final allCompleted = updatedChecklist.every((item) => item.completed);
    final newStatus = allCompleted ? 'completed' : 'in_progress';

    final updatedLog = log.copyWith(
      checklist: updatedChecklist,
      notes: finalNotes ?? log.notes,
      status: newStatus,
    );

    await repository.updateMaintenanceLog(updatedLog);

    // If completed, update machine status to 'ready'
    if (newStatus == 'completed') {
      for (final part in log.sparePartsUsed) {
        await inventoryUseCases.adjustInventory(
          itemId: part.partId,
          type: InventoryItemType.sparePart,
          delta: -part.quantity,
        );
      }
      await machineryUseCases.updateMachineStatus(
        log.machineId,
        MachineStatus.ready,
      );
    }
  }

  Future<void> deleteMaintenanceLog(String logId) async {
    await repository.deleteMaintenanceLog(logId);
  }

  Stream<List<MachineModel>> getAllMachines() {
    return repository.getAllMachines();
  }
}