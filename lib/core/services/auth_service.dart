// plastic_factory_management/lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/data/models/user_model.dart'; // سنقوم بإنشاء هذا لاحقاً

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream لمراقبة حالة المصادقة
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  // تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<UserModel> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // جلب بيانات المستخدم من Firestore بعد تسجيل الدخول
      DocumentSnapshot doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!doc.exists) {
        // إذا لم يكن هناك مستند للمستخدم في Firestore، يمكن اعتباره خطأ أو إنشاء مستند افتراضي
        throw Exception("User data not found in Firestore.");
      }
      return UserModel.fromDocumentSnapshot(doc);
    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء المصادقة المحددة
      print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      rethrow; // إعادة رمي الخطأ للتعامل معه في الواجهة الأمامية
    } catch (e) {
      print('Error during sign in: $e');
      rethrow;
    }
  }

  /// Attempts to sign in. If the user does not exist, a new account is created
  /// automatically using a default name and [UserRole.unknown].
  Future<UserModel> signInOrCreate(String email, String password) async {
    try {
      return await signInWithEmailPassword(email, password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        final defaultName = email.split('@').first;
        return await signUpWithEmailPassword(
          email,
          password,
          defaultName,
          UserRole.unknown,
        );
      }
      rethrow;
    }
  }

  /// Attempts to sign in with the provided [email] and [password].
  /// If the user does not exist, a new account will be created using
  /// the provided [name] and [role].
  Future<UserModel> signInOrCreateWithRole(
      String email, String password, String name, UserRole role) async {
    try {
      return await signInWithEmailPassword(email, password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return await signUpWithEmailPassword(email, password, name, role);
      }
      rethrow;
    }
  }

  // تسجيل مستخدم جديد (قد يستخدمه المدير لإنشاء حسابات)
  Future<UserModel> signUpWithEmailPassword(String email, String password, String name, UserRole role) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // إنشاء مستند المستخدم في Firestore
        UserModel newUser = UserModel(
          uid: firebaseUser.uid,
          email: email,
          name: name,
          role: role.toFirestoreString(), // حفظ الدور كنص في Firestore
          employeeId: null, // يمكن إضافة هذا لاحقاً
          createdAt: Timestamp.now(),
        );

        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        return newUser;
      } else {
        throw Exception("Failed to create user.");
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // جلب بيانات المستخدم الحالي من Firestore
  Future<UserModel?> getCurrentUserFirestoreData() async {
    User? currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        return UserModel.fromDocumentSnapshot(doc);
      }
    }
    return null;
  }
}