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

  Future<void> approveByAccountant(
      PurchaseRequestModel request, String approverUid, String approverName) async {
    final updated = request.copyWith(
      status: PurchaseRequestStatus.awaitingWarehouse,
      accountantUid: approverUid,
      accountantName: approverName,
      accountantApprovedAt: Timestamp.now(),
    );
    await repository.updatePurchaseRequest(updated);
  }

  Future<void> rejectByAccountant(
      PurchaseRequestModel request, String approverUid, String approverName) async {
    final updated = request.copyWith(
      status: PurchaseRequestStatus.rejected,
      accountantUid: approverUid,
      accountantName: approverName,
      accountantApprovedAt: Timestamp.now(),
    );
    await repository.updatePurchaseRequest(updated);
  }

  Future<void> receiveByWarehouse(
      PurchaseRequestModel request, String uid, String name,
      InventoryUseCases inventoryUseCases) async {
    final updated = request.copyWith(
      status: PurchaseRequestStatus.completed,
      warehouseUid: uid,
      warehouseName: name,
      warehouseReceivedAt: Timestamp.now(),
    );
    await repository.updatePurchaseRequest(updated);

    for (final item in request.items) {
      await inventoryUseCases.adjustInventoryWithNotification(
        itemId: item.itemId,
        itemName: item.itemName,
        type: InventoryItemType.rawMaterial,
        delta: item.quantity.toDouble(),
      );
    }
  }
}
