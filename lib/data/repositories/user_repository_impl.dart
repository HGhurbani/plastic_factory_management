// plastic_factory_management/lib/data/repositories/user_repository_impl.dart

import 'package:plastic_factory_management/data/datasources/user_datasource.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDatasource datasource;

  UserRepositoryImpl(this.datasource);

  @override
  Stream<List<UserModel>> getUsers() {
    return datasource.getUsers();
  }

  @override
  Future<UserModel?> getUserById(String uid) {
    return datasource.getUserById(uid);
  }

  @override
  Future<List<UserModel>> getUsersByRole(String role) {
    return datasource.getUsersByRole(role);
  }

  @override
  Future<void> addUser(UserModel user, String password) {
    return datasource.addUser(user, password);
  }

  @override
  Future<void> updateUser(UserModel user) {
    return datasource.updateUser(user);
  }

  @override
  Future<void> deleteUser(String uid) {
    return datasource.deleteUser(uid);
  }

  @override
  Future<void> setTermsAccepted(String uid, Timestamp acceptedAt) {
    return datasource.setTermsAccepted(uid, acceptedAt);
  }
}
