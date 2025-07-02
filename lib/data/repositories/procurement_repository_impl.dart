import 'package:plastic_factory_management/data/datasources/procurement_datasource.dart';
import 'package:plastic_factory_management/data/models/purchase_request_model.dart';
import 'package:plastic_factory_management/domain/repositories/procurement_repository.dart';

class ProcurementRepositoryImpl implements ProcurementRepository {
  final ProcurementDatasource datasource;
  ProcurementRepositoryImpl(this.datasource);

  @override
  Stream<List<PurchaseRequestModel>> getPurchaseRequests() {
    return datasource.getPurchaseRequests();
  }

  @override
  Future<void> addPurchaseRequest(PurchaseRequestModel request) {
    return datasource.addPurchaseRequest(request);
  }

  @override
  Future<void> updatePurchaseRequest(PurchaseRequestModel request) {
    return datasource.updatePurchaseRequest(request);
  }
}
