// plastic_factory_management/lib/data/repositories/machinery_operator_repository_impl.dart

import 'package:plastic_factory_management/data/datasources/machinery_operator_datasource.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/operator_model.dart';
import 'package:plastic_factory_management/domain/repositories/machinery_operator_repository.dart'; // سنقوم بإنشاء هذا لاحقاً

class MachineryOperatorRepositoryImpl implements MachineryOperatorRepository {
  final MachineryOperatorDatasource datasource;

  MachineryOperatorRepositoryImpl(this.datasource);

  @override
  Stream<List<MachineModel>> getMachines() {
    return datasource.getMachines();
  }

  @override
  Future<void> addMachine(MachineModel machine) {
    return datasource.addMachine(machine);
  }

  @override
  Future<void> updateMachine(MachineModel machine) {
    return datasource.updateMachine(machine);
  }

  @override
  Future<void> deleteMachine(String machineId) {
    return datasource.deleteMachine(machineId);
  }

  @override
  Future<MachineModel?> getMachineById(String machineId) {
    return datasource.getMachineById(machineId);
  }

  @override
  Stream<List<OperatorModel>> getOperators() {
    return datasource.getOperators();
  }

  @override
  Future<void> addOperator(OperatorModel operator) {
    return datasource.addOperator(operator);
  }

  @override
  Future<void> updateOperator(OperatorModel operator) {
    return datasource.updateOperator(operator);
  }

  @override
  Future<void> deleteOperator(String operatorId) {
    return datasource.deleteOperator(operatorId);
  }

  @override
  Future<OperatorModel?> getOperatorById(String operatorId) {
    return datasource.getOperatorById(operatorId);
  }
}