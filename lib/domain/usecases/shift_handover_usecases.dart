import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:plastic_factory_management/data/models/shift_handover_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/repositories/shift_handover_repository.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';

class ShiftHandoverUseCases {
  final ShiftHandoverRepository repository;
  final FileUploadService _uploadService = FileUploadService();

  ShiftHandoverUseCases(this.repository);

  Stream<List<ShiftHandoverModel>> getHandoversForOrder(String orderId) {
    return repository.getHandoversForOrder(orderId);
  }

  Future<String> addHandover({
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
    final id = await repository.addHandover(handover);
    return id;
  }

  Future<void> receiveHandover({
    required ShiftHandoverModel handover,
    required double meterReading,
    String? notes,
    List<File>? images,
  }) async {
    List<String> urls = [];
    if (images != null && images.isNotEmpty) {
      for (final file in images) {
        final url = await _uploadService.uploadFile(
          file,
          'handover_receiving/${handover.id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (url != null) urls.add(url);
      }
    }

    final updated = handover.copyWith(
      receivingMeterReading: meterReading,
      receivingNotes: notes,
      receivingImageUrls: [...handover.receivingImageUrls, ...urls],
      receivedAt: Timestamp.now(),
    );
    await repository.updateHandover(updated);
  }
}
