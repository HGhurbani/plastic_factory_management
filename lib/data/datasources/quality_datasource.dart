// plastic_factory_management/lib/data/datasources/quality_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quality_check_model.dart';

class QualityDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<QualityCheckModel>> getQualityChecks() {
    return _firestore
        .collection('quality_checks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QualityCheckModel.fromDocumentSnapshot(doc))
            .toList());
  }

  Future<void> addQualityCheck(QualityCheckModel check) async {
    await _firestore.collection('quality_checks').add(check.toMap());
  }
}
