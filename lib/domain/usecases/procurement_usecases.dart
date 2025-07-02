import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/purchase_request_model.dart';
import 'package:plastic_factory_management/domain/repositories/procurement_repository.dart';
import 'inventory_usecases.dart';

class ProcurementUseCases {
  final ProcurementRepository repository;
  final InventoryUseCases inventoryUseCases;

  ProcurementUseCases(this.repository, this.inventoryUseCases);

  Stream<List<PurchaseRequestModel>> getPurchaseRequests() {
    return repository.getPurchaseRequests();
  }

  Future<void> createPurchaseRequest(PurchaseRequestModel request) async {
    await repository.addPurchaseRequest(request);
  }

  Future<void> sendToSupplier(PurchaseRequestModel request,
      {required String supplierId, required String supplierName}) async {
    final updated = request.copyWith(
      status: PurchaseRequestStatus.awaitingFinance,
      supplierId: supplierId,
      supplierName: supplierName,
    );
    await repository.updatePurchaseRequest(updated);
  }

  Future<void> approveFinance(
      PurchaseRequestModel request, String approverUid, String approverName) async {
    final updated = request.copyWith(
      status: PurchaseRequestStatus.completed,
      financeUid: approverUid,
      financeName: approverName,
      financeApprovedAt: Timestamp.now(),
    );
    await repository.updatePurchaseRequest(updated);
  }
}
