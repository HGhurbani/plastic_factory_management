import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_handover_model.dart';

class ShiftHandoverDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ShiftHandoverModel>> getHandoversForOrder(String orderId) {
    return _firestore
        .collection('shift_handovers')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftHandoverModel.fromDocumentSnapshot(doc))
            .toList());
  }

  Future<void> addHandover(ShiftHandoverModel handover) async {
    await _firestore.collection('shift_handovers').add(handover.toMap());
  }
}
