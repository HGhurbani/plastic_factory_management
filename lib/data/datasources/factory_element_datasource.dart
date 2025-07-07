import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/factory_element_model.dart';

class FactoryElementDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<FactoryElementModel>> getElements() {
    return _firestore.collection('factory_elements').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FactoryElementModel.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  Future<void> addElement(FactoryElementModel element) async {
    await _firestore.collection('factory_elements').add(element.toMap());
  }

  Future<void> updateElement(FactoryElementModel element) async {
    await _firestore
        .collection('factory_elements')
        .doc(element.id)
        .update(element.toMap());
  }

  Future<void> deleteElement(String id) async {
    await _firestore.collection('factory_elements').doc(id).delete();
  }
}
