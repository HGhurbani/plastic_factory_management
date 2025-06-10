// plastic_factory_management/lib/domain/repositories/machinery_operator_repository.dart

import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/operator_model.dart';

abstract class MachineryOperatorRepository {
  Stream<List<MachineModel>> getMachines();
  Future<void> addMachine(MachineModel machine);
  Future<void> updateMachine(MachineModel machine);
  Future<void> deleteMachine(String machineId);
  Future<MachineModel?> getMachineById(String machineId);

  Stream<List<OperatorModel>> getOperators();
  Future<void> addOperator(OperatorModel operator);
  Future<void> updateOperator(OperatorModel operator);
  Future<void> deleteOperator(String operatorId);
  Future<OperatorModel?> getOperatorById(String operatorId);
}