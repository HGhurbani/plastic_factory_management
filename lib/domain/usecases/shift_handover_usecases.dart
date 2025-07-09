import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/shift_handover_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/repositories/shift_handover_repository.dart';

class ShiftHandoverUseCases {
  final ShiftHandoverRepository repository;

  ShiftHandoverUseCases(this.repository);

  Stream<List<ShiftHandoverModel>> getHandoversForOrder(String orderId) {
    return repository.getHandoversForOrder(orderId);
  }

  Future<void> addHandover({
    required String orderId,
    required UserModel fromSupervisor,
    required UserModel toSupervisor,
    required double meterReading,
    String? notes,
  }) async {
    final handover = ShiftHandoverModel(
      id: '',
      orderId: orderId,
      fromSupervisorUid: fromSupervisor.uid,
      fromSupervisorName: fromSupervisor.name,
      toSupervisorUid: toSupervisor.uid,
      toSupervisorName: toSupervisor.name,
      meterReading: meterReading,
      notes: notes,
      createdAt: Timestamp.now(),
    );
    await repository.addHandover(handover);
  }
}
