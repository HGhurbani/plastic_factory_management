import 'package:plastic_factory_management/domain/repositories/shift_handover_repository.dart';
import '../datasources/shift_handover_datasource.dart';
import '../models/shift_handover_model.dart';

class ShiftHandoverRepositoryImpl implements ShiftHandoverRepository {
  final ShiftHandoverDatasource datasource;
  ShiftHandoverRepositoryImpl(this.datasource);

  @override
  Stream<List<ShiftHandoverModel>> getHandoversForOrder(String orderId) {
    return datasource.getHandoversForOrder(orderId);
  }

  @override
  Future<String> addHandover(ShiftHandoverModel handover) {
    return datasource.addHandover(handover);
  }

  @override
  Future<void> updateHandover(ShiftHandoverModel handover) {
    return datasource.updateHandover(handover);
  }
}
