// Native implementation for file operations
import 'dart:io';

class FileHandler {
  static Future<bool> exists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  static Future<String> readAsString(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }
}
