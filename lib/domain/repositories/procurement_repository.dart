import 'package:plastic_factory_management/data/models/purchase_request_model.dart';

abstract class ProcurementRepository {
  Stream<List<PurchaseRequestModel>> getPurchaseRequests();
  Future<void> addPurchaseRequest(PurchaseRequestModel request);
  Future<void> updatePurchaseRequest(PurchaseRequestModel request);
}
