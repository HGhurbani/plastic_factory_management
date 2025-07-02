import '../../data/models/return_request_model.dart';

abstract class ReturnsRepository {
  Stream<List<ReturnRequestModel>> getReturnRequests();
  Future<void> addReturnRequest(ReturnRequestModel request);
  Future<void> updateReturnRequest(ReturnRequestModel request);
}
