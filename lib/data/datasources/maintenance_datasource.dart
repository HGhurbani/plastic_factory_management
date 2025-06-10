// plastic_factory_management/lib/data/datasources/maintenance_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/maintenance_log_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart'; // لجلب بيانات الآلات

class MaintenanceDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Maintenance Log Operations ---

  Stream<List<MaintenanceLogModel>> getMaintenanceLogs() {
    return _firestore.collection('maintenance_logs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MaintenanceLogModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Stream<List<MaintenanceLogModel>> getScheduledMaintenance({String? machineId, String? responsibleUid}) {
    Query query = _firestore.collection('maintenance_logs').where('status', isEqualTo: 'scheduled');
    if (machineId != null) {
      query = query.where('machineId', isEqualTo: machineId);
    }
    if (responsibleUid != null) {
      query = query.where('responsibleUid', isEqualTo: responsibleUid);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MaintenanceLogModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Stream<List<MaintenanceLogModel>> getCompletedMaintenance() {
    return _firestore
        .collection('maintenance_logs')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MaintenanceLogModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Future<void> addMaintenanceLog(MaintenanceLogModel log) async {
    await _firestore.collection('maintenance_logs').add(log.toMap());
  }

  Future<void> updateMaintenanceLog(MaintenanceLogModel log) async {
    await _firestore.collection('maintenance_logs').doc(log.id).update(log.toMap());
  }

  Future<void> deleteMaintenanceLog(String logId) async {
    await _firestore.collection('maintenance_logs').doc(logId).delete();
  }

  Future<MaintenanceLogModel?> getMaintenanceLogById(String logId) async {
    final doc = await _firestore.collection('maintenance_logs').doc(logId).get();
    if (doc.exists) {
      return MaintenanceLogModel.fromDocumentSnapshot(doc);
    }
    return null;
  }

  // --- Machine Data Access (for dropdowns) ---
  Stream<List<MachineModel>> getAllMachines() {
    return _firestore.collection('machines').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MachineModel.fromDocumentSnapshot(doc)).toList();
    });
  }
}