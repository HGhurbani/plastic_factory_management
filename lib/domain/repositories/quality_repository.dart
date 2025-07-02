// plastic_factory_management/lib/domain/repositories/quality_repository.dart

import 'package:plastic_factory_management/data/models/quality_check_model.dart';

abstract class QualityRepository {
  Stream<List<QualityCheckModel>> getQualityChecks();
  Future<void> addQualityCheck(QualityCheckModel check);
}
