// Stub implementation for web platform
class FileHandler {
  static Future<bool> exists(String filePath) async {
    // On web, we don't have file system access
    return false;
  }

  static Future<String> readAsString(String filePath) async {
    throw UnsupportedError('File system access not available on web platform');
  }
}
