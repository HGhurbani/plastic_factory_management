import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/data/models/payment_model.dart';
import 'package:plastic_factory_management/data/models/purchase_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_request_model.dart';
import 'package:plastic_factory_management/domain/repositories/financial_repository.dart';
import 'package:plastic_factory_management/domain/repositories/sales_repository.dart';

class FinancialUseCases {
  final FinancialRepository repository;
  final SalesRepository salesRepository; // لاستخدام بيانات العملاء

  FinancialUseCases(this.repository, this.salesRepository);

  // Payments
  Stream<List<PaymentModel>> getPaymentsForCustomer(String customerId) {
    return repository.getPaymentsForCustomer(customerId);
  }

  Future<void> recordPayment({
    required PaymentModel payment,
    required CustomerModel customer,
  }) async {
    await repository.addPayment(payment);
    final updatedCustomer =
        customer.copyWith(currentDebt: customer.currentDebt - payment.amount);
    await salesRepository.updateCustomer(updatedCustomer);
  }

  // Purchases
  Stream<List<PurchaseModel>> getPurchases() {
    return repository.getPurchases();
  }

  Future<void> recordPurchase(PurchaseModel purchase) async {
    await repository.addPurchase(purchase);
  }

  // Spare part requests
  Stream<List<SparePartRequestModel>> getSparePartRequests() {
    return repository.getSparePartRequests();
  }

  Future<void> createSparePartRequest(SparePartRequestModel request) async {
    await repository.addSparePartRequest(request);
  }

  Future<void> approveSparePartRequest(
      SparePartRequestModel request, String approverUid, String approverName) async {
    final updated = request.copyWith(
      status: SparePartRequestStatus.approved,
      approvedByUid: approverUid,
      approvedByName: approverName,
      approvedAt: Timestamp.now(),
      rejectionReason: null,
    );
    await repository.updateSparePartRequest(updated);
  }

  Future<void> rejectSparePartRequest(
      SparePartRequestModel request, String approverUid, String approverName, String reason) async {
    final updated = request.copyWith(
      status: SparePartRequestStatus.rejected,
      approvedByUid: approverUid,
      approvedByName: approverName,
      approvedAt: Timestamp.now(),
      rejectionReason: reason,
    );
    await repository.updateSparePartRequest(updated);
  }
}
