class VersionEntry {
  final String s3ObjectKey; // e.g. "backups/1/1719849600000.db"
  final DateTime timestamp;
  final int fileSizeBytes;
  final String checksum; // MD5 / ETag

  VersionEntry({
    required this.s3ObjectKey,
    required this.timestamp,
    required this.fileSizeBytes,
    required this.checksum,
  });
}

enum ConflictResult {
  match, // Local and remote checksums are equal
  mismatch, // Checksums differ — show dialog
  noRemote, // No backup exists on S3 yet
  offline, // No network — skip check
  error, // S3 request failed
}

enum ConflictChoice {
  overrideLocal, // Download S3 version, replace local
  keepLocal, // Upload local as new version
  cancel, // Do nothing
}

class BackupException implements Exception {
  final String message;
  final String? code; // e.g. 'network_error', 'credential_error', 's3_error'

  BackupException(this.message, {this.code});
}
