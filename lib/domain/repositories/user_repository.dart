// plastic_factory_management/lib/domain/repositories/user_repository.dart

import "package:plastic_factory_management/data/models/user_model.dart";
abstract class UserRepository {
  Stream<List<UserModel>> getUsers();
  Future<UserModel?> getUserById(String uid);
  Future<void> addUser(UserModel user, String password);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String uid);
}
