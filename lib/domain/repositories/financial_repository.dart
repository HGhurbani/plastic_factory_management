import 'package:plastic_factory_management/data/models/payment_model.dart';
import 'package:plastic_factory_management/data/models/purchase_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_request_model.dart';

abstract class FinancialRepository {
  // Payments
  Stream<List<PaymentModel>> getPaymentsForCustomer(String customerId);
  Future<void> addPayment(PaymentModel payment);

  // Purchases
  Stream<List<PurchaseModel>> getPurchases();
  Future<void> addPurchase(PurchaseModel purchase);

  // Spare part requests
  Stream<List<SparePartRequestModel>> getSparePartRequests();
  Future<void> addSparePartRequest(SparePartRequestModel request);
  Future<void> updateSparePartRequest(SparePartRequestModel request);
}
