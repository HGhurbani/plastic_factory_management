// plastic_factory_management/lib/data/datasources/user_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';

class UserDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<UserModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDocumentSnapshot(doc);
    }
    return null;
  }

  Future<void> addUser(UserModel user, String password) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );
    final newUser = user.copyWith(uid: cred.user!.uid, createdAt: Timestamp.now());
    await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<void> setTermsAccepted(String uid, Timestamp acceptedAt) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'termsAcceptedAt': acceptedAt});
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromDocumentSnapshot(doc))
        .toList();
  }
}
