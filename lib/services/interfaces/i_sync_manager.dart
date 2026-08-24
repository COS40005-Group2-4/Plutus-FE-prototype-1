import '../../models/backup_models.dart';

abstract class ISyncManager {
  Future<ConflictResult> checkConflictOnLaunch(String backupKey);
  void startAutoSync(String backupKey);
  void stopAutoSync();
  void onConnectivityChanged(bool isConnected);
  bool get isAutoSyncActive;
  bool get hasPendingUploads;
}
