// plastic_factory_management/lib/domain/repositories/user_repository.dart

import "package:plastic_factory_management/data/models/user_model.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
abstract class UserRepository {
  Stream<List<UserModel>> getUsers();
  Future<UserModel?> getUserById(String uid);
  Future<List<UserModel>> getUsersByRole(String role);
  Future<void> addUser(UserModel user, String password);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String uid);
  Future<void> setTermsAccepted(String uid, Timestamp acceptedAt);
}
