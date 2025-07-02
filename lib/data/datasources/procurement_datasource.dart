import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/purchase_request_model.dart';

class ProcurementDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PurchaseRequestModel>> getPurchaseRequests() {
    return _firestore
        .collection('purchase_requests')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => PurchaseRequestModel.fromDocumentSnapshot(d))
            .toList());
  }

  Future<void> addPurchaseRequest(PurchaseRequestModel request) async {
    await _firestore.collection('purchase_requests').add(request.toMap());
  }

  Future<void> updatePurchaseRequest(PurchaseRequestModel request) async {
    await _firestore
        .collection('purchase_requests')
        .doc(request.id)
        .update(request.toMap());
  }
}
