import '../../models/backup_models.dart';

abstract class IBackupService {
  Future<String> getDatabasePath();
  Future<String> uploadBackup(int userId);
  Future<void> restoreBackup(int userId, String s3ObjectKey);
  Future<List<VersionEntry>> listBackups(int userId);
  Future<List<VersionEntry>> listAllBackups();
  Future<void> deleteBackup(String s3ObjectKey);
  Future<String?> getLatestBackupChecksum(int userId);
  Future<String> computeLocalChecksum();
  Future<void> enforceVersionLimit(int userId);
}
