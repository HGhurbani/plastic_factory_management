// plastic_factory_management/lib/domain/usecases/maintenance_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/maintenance_log_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart'; // لاستخدام بيانات المستخدم
import 'package:plastic_factory_management/domain/repositories/maintenance_repository.dart';

class MaintenanceUseCases {
  final MaintenanceRepository repository;

  MaintenanceUseCases(this.repository);

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
    String? notes,
    required List<String> checklistTasks,
  }) async {
    final newLog = MaintenanceLogModel(
      id: '', // Firestore will generate
      machineId: selectedMachine.id,
      machineName: selectedMachine.name,
      maintenanceDate: Timestamp.fromDate(maintenanceDateTime),
      type: type,
      responsibleUid: responsibleUser.uid,
      responsibleName: responsibleUser.name,
      notes: notes,
      checklist: checklistTasks.map((task) => MaintenanceChecklistItem(task: task)).toList(),
      status: 'scheduled',
    );
    await repository.addMaintenanceLog(newLog);

    // Update machine status to 'underMaintenance' or 'scheduled_maintenance' (if we had such status)
    // For simplicity, we might update it to 'underMaintenance' when the scheduled date arrives
    // or when the maintenance starts. This would typically involve Cloud Functions.
    // For now, only the log is created.
  }

  Future<void> updateMaintenanceLog({
    required String id,
    required String machineId,
    required String machineName,
    required DateTime maintenanceDate,
    required MaintenanceType type,
    required String responsibleUid,
    required String responsibleName,
    String? notes,
    required List<MaintenanceChecklistItem> checklist,
    required String status,
  }) async {
    final updatedLog = MaintenanceLogModel(
      id: id,
      machineId: machineId,
      machineName: machineName,
      maintenanceDate: Timestamp.fromDate(maintenanceDate),
      type: type,
      responsibleUid: responsibleUid,
      responsibleName: responsibleName,
      notes: notes,
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
      // This part would typically be handled by MachineryOperatorUseCases,
      // but to avoid circular dependency for this example, we'll keep it simple
      // or assume a Cloud Function would handle it.
      // For now, let's just make a direct call if this is the only place it's needed.
      // You'd need to fetch the machine and update its status.
      // E.g., await MachineryOperatorUseCases(...).updateMachineStatus(log.machineId, MachineStatus.ready);
    }
  }

  Future<void> deleteMaintenanceLog(String logId) async {
    await repository.deleteMaintenanceLog(logId);
  }

  Stream<List<MachineModel>> getAllMachines() {
    return repository.getAllMachines();
  }
}