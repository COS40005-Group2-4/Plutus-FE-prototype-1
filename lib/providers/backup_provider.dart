import 'package:flutter/foundation.dart';

import '../models/backup_models.dart';
import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../services/sync_manager.dart';

class BackupProvider extends ChangeNotifier {
  final BackupService _backupService;
  final SyncManager _syncManager;
  final SettingsService _settingsService;

  bool _isBackupEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<VersionEntry> _versions = [];
  bool _hasConflict = false;
  bool _hasRemoteBackup = false;
  int? _userId;

  bool get isBackupEnabled => _isBackupEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VersionEntry> get versions => List.unmodifiable(_versions);
  bool get hasConflict => _hasConflict;
  bool get hasRemoteBackup => _hasRemoteBackup;

  BackupProvider({
    BackupService? backupService,
    SyncManager? syncManager,
    SettingsService? settingsService,
  })  : _backupService = backupService ?? BackupService(),
        _syncManager = syncManager ?? SyncManager(),
        _settingsService = settingsService ?? SettingsService();

  /// Initialize the provider for a given user.
  Future<void> initialize(int userId) async {
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    _hasRemoteBackup = false;
    notifyListeners();

    try {
      // Read backup setting from SettingsService
      _isBackupEnabled =
          await _settingsService.getAutoBackupEnabled(userId);

      // Always check if remote backups exist (for new device sync)
      try {
        final backups = await _backupService.listBackups(userId);
        _hasRemoteBackup = backups.isNotEmpty;
      } catch (_) {
        _hasRemoteBackup = false;
      }

      if (_isBackupEnabled) {
        // Run conflict check via SyncManager
        final conflictResult =
            await _syncManager.checkConflictOnLaunch(userId);
        _hasConflict = conflictResult == ConflictResult.mismatch;

        // Start auto-sync if enabled
        _syncManager.startAutoSync(userId);
      } else if (_hasRemoteBackup) {
        // Backup not enabled but remote data exists — flag for new device prompt
        _hasConflict = true;
      }
    } on BackupException catch (e) {
      _errorMessage = _mapErrorCode(e.code);
    } catch (e) {
      _errorMessage = 'backup_failed';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle backup on/off.
  Future<void> setBackupEnabled(bool enabled) async {
    if (_userId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Persist via SettingsService
      await _settingsService.setAutoBackupEnabled(_userId!, enabled);
      _isBackupEnabled = enabled;

      if (enabled) {
        _syncManager.startAutoSync(_userId!);
      } else {
        _syncManager.stopAutoSync();
      }
    } on BackupException catch (e) {
      _errorMessage = _mapErrorCode(e.code);
    } catch (e) {
      _errorMessage = 'backup_failed';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Trigger a manual backup upload.
  Future<void> triggerManualBackup() async {
    if (_userId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _backupService.uploadBackup(_userId!);
      await refreshVersions();
    } on BackupException catch (e) {
      _errorMessage = _mapErrorCode(e.code);
    } catch (e) {
      _errorMessage = 'backup_failed';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Restore a specific version.
  Future<void> restoreVersion(VersionEntry version) async {
    if (_userId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _backupService.restoreBackup(_userId!, version.s3ObjectKey);
    } on BackupException catch (e) {
      _errorMessage = _mapErrorCode(e.code);
    } catch (e) {
      _errorMessage = 'backup_failed';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Resolve conflict with user's choice.
  Future<void> resolveConflict(ConflictChoice choice) async {
    if (_userId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (choice) {
        case ConflictChoice.overrideLocal:
          // Download latest S3 version and replace local DB
          final backups = await _backupService.listBackups(_userId!);
          if (backups.isNotEmpty) {
            await _backupService.restoreBackup(
                _userId!, backups.first.s3ObjectKey);
          }
          break;
        case ConflictChoice.keepLocal:
          // Upload local DB as new version
          await _backupService.uploadBackup(_userId!);
          break;
        case ConflictChoice.cancel:
          // Do nothing
          break;
      }
      _hasConflict = false;
    } on BackupException catch (e) {
      _errorMessage = _mapErrorCode(e.code);
    } catch (e) {
      _errorMessage = 'backup_failed';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh the version list from S3.
  Future<void> refreshVersions() async {
    if (_userId == null) return;

    try {
      _versions = await _backupService.listBackups(_userId!);
    } on BackupException catch (e) {
      _errorMessage = _mapErrorCode(e.code);
    } catch (e) {
      _errorMessage = 'backup_failed';
    }

    notifyListeners();
  }

  /// Map BackupException error code to localization key.
  String _mapErrorCode(String? code) {
    switch (code) {
      case 'network_error':
        return 'backup_error_network';
      case 'credential_error':
        return 'backup_error_credentials';
      case 's3_error':
        return 'backup_error_s3';
      default:
        return 'backup_failed';
    }
  }

  @override
  void dispose() {
    _syncManager.stopAutoSync();
    super.dispose();
  }
}
