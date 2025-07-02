import 'package:plastic_factory_management/data/datasources/financial_datasource.dart';
import 'package:plastic_factory_management/data/models/payment_model.dart';
import 'package:plastic_factory_management/data/models/purchase_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_request_model.dart';
import 'package:plastic_factory_management/domain/repositories/financial_repository.dart';

class FinancialRepositoryImpl implements FinancialRepository {
  final FinancialDatasource datasource;
  FinancialRepositoryImpl(this.datasource);

  @override
  Stream<List<PaymentModel>> getPaymentsForCustomer(String customerId) {
    return datasource.getPaymentsForCustomer(customerId);
  }

  @override
  Future<void> addPayment(PaymentModel payment) {
    return datasource.addPayment(payment);
  }

  @override
  Stream<List<PurchaseModel>> getPurchases() {
    return datasource.getPurchases();
  }

  @override
  Future<void> addPurchase(PurchaseModel purchase) {
    return datasource.addPurchase(purchase);
  }

  @override
  Stream<List<SparePartRequestModel>> getSparePartRequests() {
    return datasource.getSparePartRequests();
  }

  @override
  Future<void> addSparePartRequest(SparePartRequestModel request) {
    return datasource.addSparePartRequest(request);
  }

  @override
  Future<void> updateSparePartRequest(SparePartRequestModel request) {
    return datasource.updateSparePartRequest(request);
  }
}
