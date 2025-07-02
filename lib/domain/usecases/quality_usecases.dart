// plastic_factory_management/lib/domain/usecases/quality_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/quality_check_model.dart';
import 'package:plastic_factory_management/domain/repositories/quality_repository.dart';

class QualityUseCases {
  final QualityRepository repository;
  QualityUseCases(this.repository);

  Stream<List<QualityCheckModel>> getQualityChecks() {
    return repository.getQualityChecks();
  }

  Future<void> recordQualityCheck({
    required String productId,
    required String productName,
    required int inspectedQuantity,
    required int rejectedQuantity,
    required String shiftSupervisorUid,
    required String shiftSupervisorName,
    required String qualityInspectorUid,
    required String qualityInspectorName,
    String? defectAnalysis,
    List<String> imageUrls = const [],
  }) async {
    final check = QualityCheckModel(
      id: '',
      productId: productId,
      productName: productName,
      inspectedQuantity: inspectedQuantity,
      rejectedQuantity: rejectedQuantity,
      acceptedQuantity: inspectedQuantity - rejectedQuantity,
      shiftSupervisorUid: shiftSupervisorUid,
      shiftSupervisorName: shiftSupervisorName,
      qualityInspectorUid: qualityInspectorUid,
      qualityInspectorName: qualityInspectorName,
      defectAnalysis: defectAnalysis,
      imageUrls: imageUrls,
      createdAt: Timestamp.now(),
    );
    await repository.addQualityCheck(check);
  }
}
