import 'dart:io';
import 'package:http/http.dart' as http;

class FileUploadService {
  final String baseUrl;
  FileUploadService({this.baseUrl = 'https://bhbgroup.me/uploads/'});

  Future<String?> uploadFile(File file, String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      return '$baseUrl$path';
    }
    return null;
  }
}
