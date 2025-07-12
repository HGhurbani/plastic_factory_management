import 'package:plastic_factory_management/data/models/shift_handover_model.dart';

abstract class ShiftHandoverRepository {
  Stream<List<ShiftHandoverModel>> getHandoversForOrder(String orderId);
  Future<String> addHandover(ShiftHandoverModel handover);
  Future<void> updateHandover(ShiftHandoverModel handover);
}
