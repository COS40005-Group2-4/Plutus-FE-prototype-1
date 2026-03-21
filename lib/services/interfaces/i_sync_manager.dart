import '../../models/backup_models.dart';

abstract class ISyncManager {
  Future<ConflictResult> checkConflictOnLaunch(int userId);
  void startAutoSync(int userId);
  void stopAutoSync();
  void onConnectivityChanged(bool isConnected);
  bool get isAutoSyncActive;
  bool get hasPendingUploads;
}
