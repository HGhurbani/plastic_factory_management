import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/return_request_model.dart';
import '../repositories/returns_repository.dart';

class ReturnsUseCases {
  final ReturnsRepository repository;
  ReturnsUseCases(this.repository);

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
    final updated = request.copyWith(status: ReturnRequestStatus.completed);
    await repository.updateReturnRequest(updated);
  }
}
