// plastic_factory_management/lib/data/datasources/machinery_operator_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/operator_model.dart';

class MachineryOperatorDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Machine Operations ---

  Stream<List<MachineModel>> getMachines() {
    return _firestore.collection('machines').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MachineModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Future<void> addMachine(MachineModel machine) async {
    await _firestore.collection('machines').add(machine.toMap());
  }

  Future<void> updateMachine(MachineModel machine) async {
    await _firestore.collection('machines').doc(machine.id).update(machine.toMap());
  }

  Future<void> deleteMachine(String machineId) async {
    await _firestore.collection('machines').doc(machineId).delete();
  }

  Future<MachineModel?> getMachineById(String machineId) async {
    final doc = await _firestore.collection('machines').doc(machineId).get();
    if (doc.exists) {
      return MachineModel.fromDocumentSnapshot(doc);
    }
    return null;
  }

  // --- Operator Operations ---

  Stream<List<OperatorModel>> getOperators() {
    return _firestore.collection('operators').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => OperatorModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Future<void> addOperator(OperatorModel operator) async {
    await _firestore.collection('operators').add(operator.toMap());
  }

  Future<void> updateOperator(OperatorModel operator) async {
    await _firestore.collection('operators').doc(operator.id).update(operator.toMap());
  }

  Future<void> deleteOperator(String operatorId) async {
    await _firestore.collection('operators').doc(operatorId).delete();
  }

  Future<OperatorModel?> getOperatorById(String operatorId) async {
    final doc = await _firestore.collection('operators').doc(operatorId).get();
    if (doc.exists) {
      return OperatorModel.fromDocumentSnapshot(doc);
    }
    return null;
  }
}