// plastic_factory_management/lib/domain/usecases/machinery_operator_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/operator_model.dart';
import 'package:plastic_factory_management/domain/repositories/machinery_operator_repository.dart';

class MachineryOperatorUseCases {
  final MachineryOperatorRepository repository;

  MachineryOperatorUseCases(this.repository);

  // --- Machine Use Cases ---

  Stream<List<MachineModel>> getMachines() {
    return repository.getMachines();
  }

  Future<void> addMachine({
    required String name,
    required String machineId,
    String? details,
    required double costPerHour,
    MachineStatus status = MachineStatus.ready, // Default status
  }) async {
    final newMachine = MachineModel(
      id: '', // Firestore will generate
      name: name,
      machineId: machineId,
      details: details,
      costPerHour: costPerHour,
      status: status,
      lastMaintenance: null, // Initially no maintenance date
    );
    await repository.addMachine(newMachine);
  }

  Future<void> updateMachine({
    required String id,
    required String name,
    required String machineId,
    String? details,
    required double costPerHour,
    required MachineStatus status,
    Timestamp? lastMaintenance,
  }) async {
    final updatedMachine = MachineModel(
      id: id,
      name: name,
      machineId: machineId,
      details: details,
      costPerHour: costPerHour,
      status: status,
      lastMaintenance: lastMaintenance,
    );
    await repository.updateMachine(updatedMachine);
  }

  Future<void> deleteMachine(String machineId) async {
    await repository.deleteMachine(machineId);
  }

  Future<MachineModel?> getMachineById(String machineId) {
    return repository.getMachineById(machineId);
  }

  // --- Operator Use Cases ---

  Stream<List<OperatorModel>> getOperators() {
    return repository.getOperators();
  }

  Future<void> addOperator({
    required String name,
    required String employeeId,
    String? personalData,
    required double costPerHour,
    OperatorStatus status = OperatorStatus.available, // Default status
  }) async {
    final newOperator = OperatorModel(
      id: '', // Firestore will generate
      name: name,
      employeeId: employeeId,
      personalData: personalData,
      costPerHour: costPerHour,
      currentMachineId: null,
      status: status,
    );
    await repository.addOperator(newOperator);
  }

  Future<void> updateOperator({
    required String id,
    required String name,
    required String employeeId,
    String? personalData,
    required double costPerHour,
    String? currentMachineId,
    required OperatorStatus status,
  }) async {
    final updatedOperator = OperatorModel(
      id: id,
      name: name,
      employeeId: employeeId,
      personalData: personalData,
      costPerHour: costPerHour,
      currentMachineId: currentMachineId,
      status: status,
    );
    await repository.updateOperator(updatedOperator);
  }

  Future<void> deleteOperator(String operatorId) async {
    await repository.deleteOperator(operatorId);
  }

  // --- Combination Use Cases ---

  // Get available machines (for assignment)
  Stream<List<MachineModel>> getAvailableMachines() {
    return repository.getMachines().map(
          (machines) => machines.where((m) => m.status == MachineStatus.ready).toList(),
    );
  }

  // Get available operators (for assignment)
  Stream<List<OperatorModel>> getAvailableOperators() {
    return repository.getOperators().map(
          (operators) => operators.where((o) => o.status == OperatorStatus.available).toList(),
    );
  }
}