// plastic_factory_management/lib/domain/usecases/production_daily_log_usecases.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';
import 'package:plastic_factory_management/data/models/production_daily_log_model.dart';
import 'package:plastic_factory_management/domain/repositories/production_daily_log_repository.dart';

class ProductionDailyLogUseCases {
  final ProductionDailyLogRepository repository;
  final FileUploadService _uploadService = FileUploadService();

  ProductionDailyLogUseCases(this.repository);

  Stream<List<ProductionDailyLogModel>> getLogsForOrder(String orderId) {
    return repository.getLogsForOrder(orderId);
  }

  Future<void> addDailyLog({
    required String orderId,
    required String supervisorUid,
    required String supervisorName,
    String? notes,
    List<File>? images,
  }) async {
    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      for (final file in images) {
        final url = await _uploadService.uploadFile(
          file,
          'daily_logs/$orderId/${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (url != null) imageUrls.add(url);
      }
    }

    final log = ProductionDailyLogModel(
      id: '',
      orderId: orderId,
      supervisorUid: supervisorUid,
      supervisorName: supervisorName,
      notes: notes,
      imageUrls: imageUrls,
      createdAt: Timestamp.now(),
    );
    await repository.addLog(log);
  }
}
