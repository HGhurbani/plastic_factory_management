import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/return_request_model.dart';
import '../repositories/returns_repository.dart';
import 'sales_usecases.dart';
import 'inventory_usecases.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';

class ReturnsUseCases {
  final ReturnsRepository repository;
  final SalesUseCases salesUseCases;
  final InventoryUseCases inventoryUseCases;
  ReturnsUseCases(
      this.repository, this.salesUseCases, this.inventoryUseCases);

  Stream<List<ReturnRequestModel>> getReturnRequests() {
    return repository.getReturnRequests();
  }

  Future<void> createReturnRequest(ReturnRequestModel request) async {
    await repository.addReturnRequest(request);
  }

  Future<void> approveOperations(
      ReturnRequestModel request, String uid, String name) async {
    final updated = request.copyWith(
      status: ReturnRequestStatus.pendingSalesApproval,
      operationsUid: uid,
      operationsName: name,
      operationsApprovedAt: Timestamp.now(),
    );
    await repository.updateReturnRequest(updated);
  }

  Future<void> approveSales(
      ReturnRequestModel request, String uid, String name) async {
    final updated = request.copyWith(
      status: ReturnRequestStatus.awaitingPickup,
      salesManagerUid: uid,
      salesManagerName: name,
      salesApprovedAt: Timestamp.now(),
    );
    await repository.updateReturnRequest(updated);
  }

  Future<void> schedulePickup(ReturnRequestModel request,
      {required String driverName,
      required String warehouseKeeperName}) async {
    final updated = request.copyWith(
      status: ReturnRequestStatus.awaitingPickup,
      driverName: driverName,
      warehouseKeeperName: warehouseKeeperName,
      pickupScheduledAt: Timestamp.now(),
    );
    await repository.updateReturnRequest(updated);
  }

  Future<void> markCompleted(ReturnRequestModel request) async {
    final order = await salesUseCases.getSalesOrderById(request.salesOrderId);
    if (order != null) {
      for (final item in order.orderItems) {
        await inventoryUseCases.adjustInventoryWithNotification(
          itemId: item.productId,
          itemName: item.productName,
          type: InventoryItemType.finishedProduct,
          delta: item.quantity.toDouble(),
        );
      }
    }
    final updated = request.copyWith(status: ReturnRequestStatus.completed);
    await repository.updateReturnRequest(updated);
  }
}
