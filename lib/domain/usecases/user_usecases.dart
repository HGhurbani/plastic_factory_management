// plastic_factory_management/lib/domain/usecases/user_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/repositories/user_repository.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';

class UserUseCases {
  final UserRepository repository;

  UserUseCases(this.repository);

  Stream<List<UserModel>> getUsers() {
    return repository.getUsers();
  }

  Future<UserModel?> getUserById(String uid) {
    return repository.getUserById(uid);
  }

  Future<List<UserModel>> getUsersByRole(UserRole role) {
    return repository.getUsersByRole(role.toFirestoreString());
  }

  Future<void> addUser({
    required String email,
    required String name,
    required UserRole role,
    required String password,
    String? employeeId,
  }) {
    final user = UserModel(
      uid: '',
      email: email,
      name: name,
      role: role.toFirestoreString(),
      employeeId: employeeId,
      createdAt: Timestamp.now(),
    );
    return repository.addUser(user, password);
  }

  Future<void> updateUser({
    required String uid,
    required String email,
    required String name,
    required UserRole role,
    String? employeeId,
  }) {
    final user = UserModel(
      uid: uid,
      email: email,
      name: name,
      role: role.toFirestoreString(),
      employeeId: employeeId,
      createdAt: Timestamp.now(),
    );
    return repository.updateUser(user);
  }

  Future<void> deleteUser(String uid) {
    return repository.deleteUser(uid);
  }

  Future<void> acceptTerms(String uid) {
    return repository.setTermsAccepted(uid, Timestamp.now());
  }
}
