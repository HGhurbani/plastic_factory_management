import '../../data/models/factory_element_model.dart';

abstract class FactoryElementRepository {
  Stream<List<FactoryElementModel>> getElements();
  Future<void> addElement(FactoryElementModel element);
  Future<void> updateElement(FactoryElementModel element);
  Future<void> deleteElement(String id);
}
