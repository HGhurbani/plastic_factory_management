import '../../data/models/factory_element_model.dart';
import '../repositories/factory_element_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FactoryElementUseCases {
  final FactoryElementRepository repository;
  FactoryElementUseCases(this.repository);

  Stream<List<FactoryElementModel>> getElements() {
    return repository.getElements();
  }

  Future<void> addElement({required String type, required String name, String? unit}) {
    final element = FactoryElementModel(
      id: '',
      type: type,
      name: name,
      unit: unit,
    );
    return repository.addElement(element);
  }

  Future<void> updateElement({
    required String id,
    required String type,
    required String name,
    String? unit,
  }) {
    final element = FactoryElementModel(
      id: id,
      type: type,
      name: name,
      unit: unit,
    );
    return repository.updateElement(element);
  }

  Future<void> deleteElement(String id) {
    return repository.deleteElement(id);
  }
}
