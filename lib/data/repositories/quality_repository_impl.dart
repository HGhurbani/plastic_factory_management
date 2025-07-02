// plastic_factory_management/lib/data/repositories/quality_repository_impl.dart

import 'package:plastic_factory_management/data/datasources/quality_datasource.dart';
import 'package:plastic_factory_management/data/models/quality_check_model.dart';
import 'package:plastic_factory_management/domain/repositories/quality_repository.dart';

class QualityRepositoryImpl implements QualityRepository {
  final QualityDatasource datasource;
  QualityRepositoryImpl(this.datasource);

  @override
  Stream<List<QualityCheckModel>> getQualityChecks() {
    return datasource.getQualityChecks();
  }

  @override
  Future<void> addQualityCheck(QualityCheckModel check) {
    return datasource.addQualityCheck(check);
  }
}
