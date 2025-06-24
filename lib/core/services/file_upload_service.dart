import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class FileUploadService {
  final FirebaseStorage storage;

  FileUploadService({FirebaseStorage? storage})
      : storage = storage ?? FirebaseStorage.instance;

  Future<String?> uploadFile(File file, String path) async {
    final ref = storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  Future<String?> uploadBytes(Uint8List bytes, String path) async {
    final ref = storage.ref().child(path);
    final uploadTask = ref.putData(bytes);
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }
}
