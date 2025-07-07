import '../datasources/factory_element_datasource.dart';
import '../models/factory_element_model.dart';
import '../../domain/repositories/factory_element_repository.dart';

class FactoryElementRepositoryImpl implements FactoryElementRepository {
  final FactoryElementDatasource datasource;
  FactoryElementRepositoryImpl(this.datasource);

  @override
  Stream<List<FactoryElementModel>> getElements() {
    return datasource.getElements();
  }

  @override
  Future<void> addElement(FactoryElementModel element) {
    return datasource.addElement(element);
  }

  @override
  Future<void> updateElement(FactoryElementModel element) {
    return datasource.updateElement(element);
  }

  @override
  Future<void> deleteElement(String id) {
    return datasource.deleteElement(id);
  }
}
