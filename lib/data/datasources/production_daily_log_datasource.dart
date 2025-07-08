// plastic_factory_management/lib/data/datasources/production_daily_log_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/production_daily_log_model.dart';

class ProductionDailyLogDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ProductionDailyLogModel>> getLogsForOrder(String orderId) {
    return _firestore
        .collection('production_daily_logs')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductionDailyLogModel.fromDocumentSnapshot(doc))
            .toList());
  }

  Future<void> addLog(ProductionDailyLogModel log) async {
    await _firestore.collection('production_daily_logs').add(log.toMap());
  }
}
