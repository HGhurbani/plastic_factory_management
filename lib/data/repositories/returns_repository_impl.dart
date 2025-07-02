import '../datasources/returns_datasource.dart';
import '../models/return_request_model.dart';
import '../../domain/repositories/returns_repository.dart';

class ReturnsRepositoryImpl implements ReturnsRepository {
  final ReturnsDatasource datasource;
  ReturnsRepositoryImpl(this.datasource);

  @override
  Stream<List<ReturnRequestModel>> getReturnRequests() {
    return datasource.getReturnRequests();
  }

  @override
  Future<void> addReturnRequest(ReturnRequestModel request) {
    return datasource.addReturnRequest(request);
  }

  @override
  Future<void> updateReturnRequest(ReturnRequestModel request) {
    return datasource.updateReturnRequest(request);
  }
}
