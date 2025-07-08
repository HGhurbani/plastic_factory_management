// plastic_factory_management/lib/domain/usecases/quality_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/quality_check_model.dart';
import 'package:plastic_factory_management/domain/repositories/quality_repository.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';

class QualityUseCases {
  final QualityRepository repository;
  QualityUseCases(this.repository);

  Stream<List<QualityCheckModel>> getQualityChecks() {
    return repository.getQualityChecks();
  }

  Future<void> recordQualityCheck({
    required String orderId,
    required OrderType orderType,
    required QualityApprovalStatus status,
    String? productId,
    String? productName,
    int inspectedQuantity = 0,
    int rejectedQuantity = 0,
    String? shiftSupervisorUid,
    String? shiftSupervisorName,
    required String qualityInspectorUid,
    required String qualityInspectorName,
    String? notes,
    String? defectAnalysis,
    List<String> imageUrls = const [],
  }) async {
    final check = QualityCheckModel(
      id: '',
      orderId: orderId,
      orderType: orderType,
      status: status,
      productId: productId,
      productName: productName,
      inspectedQuantity: inspectedQuantity,
      rejectedQuantity: rejectedQuantity,
      acceptedQuantity: inspectedQuantity - rejectedQuantity,
      shiftSupervisorUid: shiftSupervisorUid,
      shiftSupervisorName: shiftSupervisorName,
      qualityInspectorUid: qualityInspectorUid,
      qualityInspectorName: qualityInspectorName,
      notes: notes,
      defectAnalysis: defectAnalysis,
      imageUrls: imageUrls,
      createdAt: Timestamp.now(),
    );
    await repository.addQualityCheck(check);
  }
}
