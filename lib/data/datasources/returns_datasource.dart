import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/return_request_model.dart';

class ReturnsDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReturnRequestModel>> getReturnRequests() {
    return _firestore
        .collection('return_requests')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => ReturnRequestModel.fromDocumentSnapshot(d))
            .toList());
  }

  Future<void> addReturnRequest(ReturnRequestModel request) async {
    await _firestore.collection('return_requests').add(request.toMap());
  }

  Future<void> updateReturnRequest(ReturnRequestModel request) async {
    await _firestore
        .collection('return_requests')
        .doc(request.id)
        .update(request.toMap());
  }
}
