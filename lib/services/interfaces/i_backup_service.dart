import '../../models/backup_models.dart';

abstract class IBackupService {
  Future<String> getDatabasePath();
  Future<String> uploadBackup(String backupKey);
  Future<void> restoreBackup(String backupKey, String s3ObjectKey);
  Future<List<VersionEntry>> listBackups(String backupKey);
  Future<void> deleteBackup(String s3ObjectKey);
  Future<String?> getLatestBackupChecksum(String backupKey);
  Future<String> computeLocalChecksum();
  Future<void> enforceVersionLimit(String backupKey);
}
