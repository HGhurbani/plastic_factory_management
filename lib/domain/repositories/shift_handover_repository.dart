import 'package:plastic_factory_management/data/models/shift_handover_model.dart';

abstract class ShiftHandoverRepository {
  Stream<List<ShiftHandoverModel>> getHandoversForOrder(String orderId);
  Future<void> addHandover(ShiftHandoverModel handover);
}
