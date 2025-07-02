import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/payment_model.dart';
import 'package:plastic_factory_management/data/models/purchase_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_request_model.dart';

class FinancialDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Payments collection
  Stream<List<PaymentModel>> getPaymentsForCustomer(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => PaymentModel.fromDocumentSnapshot(d)).toList());
  }

  Future<void> addPayment(PaymentModel payment) async {
    await _firestore.collection('payments').add(payment.toMap());
  }

  // Purchases collection
  Stream<List<PurchaseModel>> getPurchases() {
    return _firestore.collection('purchases').snapshots().map((snapshot) =>
        snapshot.docs.map((d) => PurchaseModel.fromDocumentSnapshot(d)).toList());
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    await _firestore.collection('purchases').add(purchase.toMap());
  }

  // Spare part requests
  Stream<List<SparePartRequestModel>> getSparePartRequests() {
    return _firestore.collection('spare_part_requests').snapshots().map(
        (snapshot) => snapshot.docs
            .map((d) => SparePartRequestModel.fromDocumentSnapshot(d))
            .toList());
  }

  Future<void> addSparePartRequest(SparePartRequestModel request) async {
    await _firestore.collection('spare_part_requests').add(request.toMap());
  }

  Future<void> updateSparePartRequest(SparePartRequestModel request) async {
    await _firestore
        .collection('spare_part_requests')
        .doc(request.id)
        .update(request.toMap());
  }
}
