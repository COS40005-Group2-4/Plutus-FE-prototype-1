import 'dart:convert';
import 'dart:io';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory, getDatabasesPath;

import '../config/aws_config.dart';
import '../models/backup_models.dart';
import 'interfaces/i_backup_service.dart';

class BackupService implements IBackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  String get _bucketName => AWSConfig.bucketName;
  String get _region => AWSConfig.region;
  String get _s3Host => '$_bucketName.s3.$_region.amazonaws.com';

  AWSSigV4Signer get _signer => AWSSigV4Signer(
        credentialsProvider: AWSCredentialsProvider(
          AWSCredentials(
            AWSConfig.accessKeyId,
            AWSConfig.secretAccessKey,
            AWSConfig.sessionToken,
          ),
        ),
      );

  AWSCredentialScope get _scope => AWSCredentialScope(
        region: _region,
        service: AWSService.s3,
      );

  /// Get the local database file path (same pattern as DatabaseService).
  @override
  Future<String> getDatabasePath() async {
    if (kIsWeb) return 'plutus_local.db';

    String directory;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      directory = (await getApplicationSupportDirectory()).path;
    } else if (Platform.isAndroid) {
      directory = await getDatabasesPath();
    } else if (Platform.isIOS) {
      directory = (await getApplicationDocumentsDirectory()).path;
    } else {
      directory = (await getApplicationSupportDirectory()).path;
    }
    return p.join(directory, 'plutus_local.db');
  }

  /// Upload local DB file to S3 as a new version.
  /// Returns the S3 object key on success.
  @override
  Future<String> uploadBackup(int userId) async {
    _validateCredentials();

    final dbPath = await getDatabasePath();

    // Read database bytes cross-platform (works on web + native)
    final Uint8List bytes;
    if (kIsWeb) {
      bytes = await databaseFactory.readDatabaseBytes(dbPath);
    } else {
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw BackupException('Local database file not found', code: 'local_db_missing');
      }
      bytes = await dbFile.readAsBytes();
    }

    // Enforce version limit before uploading
    await enforceVersionLimit(userId);
    final checksum = md5.convert(bytes).toString();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final s3Key = 'backups/$userId/$timestamp.db';

    try {
      final uri = Uri.https(_s3Host, '/$s3Key');
      final request = AWSHttpRequest(
        method: AWSHttpMethod.put,
        uri: uri,
        headers: {
          'content-type': 'application/octet-stream',
          'content-md5': base64Encode(md5.convert(bytes).bytes),
        },
        body: bytes,
      );

      final signedRequest = await _signer.sign(
        request,
        credentialScope: _scope,
      );

      final response = await http.put(
        signedRequest.uri,
        headers: signedRequest.headers,
        body: await signedRequest.bodyBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('BackupService: Uploaded backup $s3Key (checksum: $checksum)');
        }
        return s3Key;
      } else {
        throw BackupException(
          'S3 upload failed: ${response.statusCode} ${response.body}',
          code: 's3_error',
        );
      }
    } on SocketException catch (e) {
      throw BackupException('Network error during upload: $e', code: 'network_error');
    } on HttpException catch (e) {
      throw BackupException('Network error during upload: $e', code: 'network_error');
    }
  }

  /// Download a specific backup version and overwrite local DB.
  /// Uses a temp file for rollback on failure (native only).
  @override
  Future<void> restoreBackup(int userId, String s3ObjectKey) async {
    _validateCredentials();

    final dbPath = await getDatabasePath();

    // Save current DB for rollback (native only; web has no temp files)
    Uint8List? originalBytes;
    if (kIsWeb) {
      try {
        originalBytes = await databaseFactory.readDatabaseBytes(dbPath);
      } catch (_) {}
    }

    File? tempFile;
    bool hadExistingDb = false;
    if (!kIsWeb) {
      final dbFile = File(dbPath);
      final tempPath = '$dbPath.tmp';
      tempFile = File(tempPath);
      hadExistingDb = await dbFile.exists();
      if (hadExistingDb) {
        await dbFile.copy(tempPath);
      }
    }

    try {
      final uri = Uri.https(_s3Host, '/$s3ObjectKey');
      final request = AWSHttpRequest(
        method: AWSHttpMethod.get,
        uri: uri,
        headers: {},
      );

      final signedRequest = await _signer.sign(
        request,
        credentialScope: _scope,
      );

      final response = await http.get(
        signedRequest.uri,
        headers: signedRequest.headers,
      );

      if (response.statusCode == 200) {
        if (kIsWeb) {
          await databaseFactory.writeDatabaseBytes(dbPath, response.bodyBytes);
        } else {
          await File(dbPath).writeAsBytes(response.bodyBytes);
          // Remove stale WAL/SHM files so SQLite opens the fresh DB cleanly
          for (final suffix in ['-wal', '-shm']) {
            try {
              final f = File('$dbPath$suffix');
              if (await f.exists()) await f.delete();
            } catch (_) {}
          }
          if (tempFile != null && await tempFile.exists()) {
            await tempFile.delete();
          }
        }
        if (kDebugMode) {
          debugPrint('BackupService: Restored backup from $s3ObjectKey');
        }
      } else {
        throw BackupException(
          'S3 download failed: ${response.statusCode} ${response.body}',
          code: 's3_error',
        );
      }
    } catch (e) {
      // Rollback
      if (kIsWeb && originalBytes != null) {
        try {
          await databaseFactory.writeDatabaseBytes(dbPath, originalBytes);
        } catch (_) {}
      } else if (!kIsWeb && hadExistingDb && tempFile != null && await tempFile.exists()) {
        await tempFile.copy(dbPath);
        await tempFile.delete();
      }
      if (e is BackupException) rethrow;
      if (e is SocketException || e is HttpException) {
        throw BackupException('Network error during restore: $e', code: 'network_error');
      }
      rethrow;
    }
  }

  /// List all backup versions for a user, sorted by timestamp descending.
  @override
  Future<List<VersionEntry>> listBackups(int userId) async {
    _validateCredentials();

    final prefix = 'backups/$userId/';

    try {
      final uri = Uri.https(_s3Host, '/', {
        'list-type': '2',
        'prefix': prefix,
      });
      final request = AWSHttpRequest(
        method: AWSHttpMethod.get,
        uri: uri,
        headers: {},
      );

      final signedRequest = await _signer.sign(
        request,
        credentialScope: _scope,
      );

      final response = await http.get(
        signedRequest.uri,
        headers: signedRequest.headers,
      );

      if (response.statusCode == 200) {
        return _parseListResponse(response.body);
      } else {
        throw BackupException(
          'S3 list failed: ${response.statusCode} ${response.body}',
          code: 's3_error',
        );
      }
    } on SocketException catch (e) {
      throw BackupException('Network error during list: $e', code: 'network_error');
    } on HttpException catch (e) {
      throw BackupException('Network error during list: $e', code: 'network_error');
    }
  }

  /// Parse S3 ListObjectsV2 XML response into a list of [VersionEntry].
  List<VersionEntry> _parseListResponse(String xmlBody) {
    final entries = <VersionEntry>[];

    // Match each <Contents> block
    final contentsRegex = RegExp(r'<Contents>(.*?)</Contents>', dotAll: true);
    final keyRegex = RegExp(r'<Key>(.*?)</Key>');
    final sizeRegex = RegExp(r'<Size>(.*?)</Size>');
    final lastModifiedRegex = RegExp(r'<LastModified>(.*?)</LastModified>');
    final etagRegex = RegExp(r'<ETag>"?(.*?)"?</ETag>');

    for (final match in contentsRegex.allMatches(xmlBody)) {
      final block = match.group(1) ?? '';

      final key = keyRegex.firstMatch(block)?.group(1);
      final sizeStr = sizeRegex.firstMatch(block)?.group(1);
      final lastModStr = lastModifiedRegex.firstMatch(block)?.group(1);
      final etag = etagRegex.firstMatch(block)?.group(1);

      if (key == null || !key.endsWith('.db')) continue;

      final size = int.tryParse(sizeStr ?? '0') ?? 0;
      final timestamp = lastModStr != null
          ? DateTime.tryParse(lastModStr) ?? DateTime.now()
          : DateTime.now();

      entries.add(VersionEntry(
        s3ObjectKey: key,
        timestamp: timestamp,
        fileSizeBytes: size,
        checksum: etag ?? '',
      ));
    }

    // Sort descending by timestamp
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }



  /// Delete a specific backup from S3.
  @override
  Future<void> deleteBackup(String s3ObjectKey) async {
    _validateCredentials();

    try {
      final uri = Uri.https(_s3Host, '/$s3ObjectKey');
      final request = AWSHttpRequest(
        method: AWSHttpMethod.delete,
        uri: uri,
        headers: {},
      );

      final signedRequest = await _signer.sign(
        request,
        credentialScope: _scope,
      );

      final response = await http.delete(
        signedRequest.uri,
        headers: signedRequest.headers,
      );

      // S3 returns 204 on successful delete
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw BackupException(
          'S3 delete failed: ${response.statusCode} ${response.body}',
          code: 's3_error',
        );
      }

      if (kDebugMode) {
        debugPrint('BackupService: Deleted backup $s3ObjectKey');
      }
    } on SocketException catch (e) {
      throw BackupException('Network error during delete: $e', code: 'network_error');
    } on HttpException catch (e) {
      throw BackupException('Network error during delete: $e', code: 'network_error');
    }
  }

  /// Get the MD5 checksum (ETag) of the latest backup on S3.
  /// Returns null if no backups exist.
  @override
  Future<String?> getLatestBackupChecksum(int userId) async {
    final backups = await listBackups(userId);
    if (backups.isEmpty) return null;

    // backups are already sorted descending, first is latest
    final latest = backups.first;

    try {
      final uri = Uri.https(_s3Host, '/${latest.s3ObjectKey}');
      final request = AWSHttpRequest(
        method: AWSHttpMethod.head,
        uri: uri,
        headers: {},
      );

      final signedRequest = await _signer.sign(
        request,
        credentialScope: _scope,
      );

      final response = await http.head(
        signedRequest.uri,
        headers: signedRequest.headers,
      );

      if (response.statusCode == 200) {
        // ETag comes with quotes, strip them
        final etag = response.headers['etag']?.replaceAll('"', '');
        return etag;
      } else {
        throw BackupException(
          'S3 HEAD failed: ${response.statusCode}',
          code: 's3_error',
        );
      }
    } on SocketException catch (e) {
      throw BackupException('Network error during checksum fetch: $e', code: 'network_error');
    } on HttpException catch (e) {
      throw BackupException('Network error during checksum fetch: $e', code: 'network_error');
    }
  }

  /// Compute MD5 checksum of the local database file.
  @override
  Future<String> computeLocalChecksum() async {
    final dbPath = await getDatabasePath();

    final Uint8List bytes;
    if (kIsWeb) {
      bytes = await databaseFactory.readDatabaseBytes(dbPath);
    } else {
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw BackupException('Local database file not found', code: 'local_db_missing');
      }
      bytes = await dbFile.readAsBytes();
    }
    return md5.convert(bytes).toString();
  }

  /// Enforce the 10-version limit by deleting oldest backups.
  @override
  Future<void> enforceVersionLimit(int userId) async {
    final backups = await listBackups(userId);
    // backups sorted descending — delete from the end (oldest)
    while (backups.length >= 10) {
      final oldest = backups.removeLast();
      await deleteBackup(oldest.s3ObjectKey);
      if (kDebugMode) {
        debugPrint('BackupService: Deleted oldest backup ${oldest.s3ObjectKey} (enforcing limit)');
      }
    }
  }

  /// Validate that AWS credentials are configured.
  void _validateCredentials() {
    if (AWSConfig.accessKeyId == 'YOUR_ACCESS_KEY_ID' ||
        AWSConfig.secretAccessKey == 'YOUR_SECRET_ACCESS_KEY') {
      throw BackupException(
        'AWS credentials not configured. Check your .env file.',
        code: 'credential_error',
      );
    }
  }
}
