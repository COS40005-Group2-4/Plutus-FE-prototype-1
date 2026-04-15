import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/backup_models.dart';
import '../services/interfaces/i_backup_service.dart';
import '../services/interfaces/i_settings_service.dart';
import '../services/interfaces/i_sync_manager.dart';
import '../services/database_service.dart';
import '../di/service_locator.dart';

/// Callback invoked after a backup restore so providers can reload from DB.
typedef PostRestoreCallback = Future<void> Function();

// ---------------------------------------------------------------------------
// BackupState — immutable value type
// ---------------------------------------------------------------------------

class BackupState {
  final bool isBackupEnabled;
  final bool isLoading;
  final String? errorMessage;
  final List<VersionEntry> versions;
  final bool hasConflict;
  final bool hasRemoteBackup;

  const BackupState({
    this.isBackupEnabled = false,
    this.isLoading = false,
    this.errorMessage,
    this.versions = const <VersionEntry>[],
    this.hasConflict = false,
    this.hasRemoteBackup = false,
  });

  BackupState copyWith({
    bool? isBackupEnabled,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<VersionEntry>? versions,
    bool? hasConflict,
    bool? hasRemoteBackup,
  }) {
    return BackupState(
      isBackupEnabled: isBackupEnabled ?? this.isBackupEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      versions: versions ?? this.versions,
      hasConflict: hasConflict ?? this.hasConflict,
      hasRemoteBackup: hasRemoteBackup ?? this.hasRemoteBackup,
    );
  }
}

// ---------------------------------------------------------------------------
// BackupNotifier
// ---------------------------------------------------------------------------

class BackupNotifier extends Notifier<BackupState> {
  late final IBackupService _backupService;
  late final ISyncManager _syncManager;
  late final ISettingsService _settingsService;

  /// Registered callbacks that run after a backup restore completes.
  final List<PostRestoreCallback> _postRestoreCallbacks = <PostRestoreCallback>[];

  int? _userId;

  @override
  BackupState build() {
    _backupService = sl<IBackupService>();
    _syncManager = sl<ISyncManager>();
    _settingsService = sl<ISettingsService>();

    return const BackupState();
  }

  // -------------------------------------------------------------------------
  // Public methods
  // -------------------------------------------------------------------------

  /// Register a callback to run after every backup restore (e.g. reload cache).
  void addPostRestoreCallback(PostRestoreCallback cb) {
    _postRestoreCallbacks.add(cb);
  }

  /// Initialize the notifier for a given user.
  Future<void> initialize(int userId) async {
    _userId = userId;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      hasRemoteBackup: false,
    );

    try {
      // Read backup setting from SettingsService
      final bool isEnabled = await _settingsService.getAutoBackupEnabled(userId);

      // Check if remote backups exist for this user
      bool hasRemote = false;
      try {
        final List<VersionEntry> backups = await _backupService.listBackups(userId);
        hasRemote = backups.isNotEmpty;
      } catch (_) {
        hasRemote = false;
      }

      bool hasConflict = false;
      if (isEnabled) {
        // Run conflict check via SyncManager
        final ConflictResult conflictResult =
            await _syncManager.checkConflictOnLaunch(userId);
        hasConflict = conflictResult == ConflictResult.mismatch;

        // Start auto-sync if enabled
        _syncManager.startAutoSync(userId);
      } else if (hasRemote) {
        // Backup not enabled but remote data exists — flag for new device prompt
        hasConflict = true;
      }

      state = state.copyWith(
        isBackupEnabled: isEnabled,
        hasRemoteBackup: hasRemote,
        hasConflict: hasConflict,
        isLoading: false,
      );
    } on BackupException catch (e) {
      state = state.copyWith(
        errorMessage: _mapErrorCode(e.code),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'backup_failed',
        isLoading: false,
      );
    }
  }

  /// Toggle backup on/off.
  Future<void> setBackupEnabled(bool enabled) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Persist via SettingsService
      await _settingsService.setAutoBackupEnabled(_userId!, enabled);

      if (enabled) {
        _syncManager.startAutoSync(_userId!);
      } else {
        _syncManager.stopAutoSync();
      }

      state = state.copyWith(isBackupEnabled: enabled, isLoading: false);
    } on BackupException catch (e) {
      state = state.copyWith(
        errorMessage: _mapErrorCode(e.code),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'backup_failed',
        isLoading: false,
      );
    }
  }

  /// Trigger a manual backup upload.
  Future<void> triggerManualBackup() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _backupService.uploadBackup(_userId!);
      await refreshVersions();
      state = state.copyWith(isLoading: false);
    } on BackupException catch (e) {
      state = state.copyWith(
        errorMessage: _mapErrorCode(e.code),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'backup_failed',
        isLoading: false,
      );
    }
  }

  /// Restore a specific version.
  Future<void> restoreVersion(VersionEntry version) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _onPreRestore();
      await _backupService.restoreBackup(_userId!, version.s3ObjectKey);
      await _onPostRestore();
      state = state.copyWith(isLoading: false);
    } on BackupException catch (e) {
      state = state.copyWith(
        errorMessage: _mapErrorCode(e.code),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'backup_failed',
        isLoading: false,
      );
    }
  }

  /// Resolve conflict with user's choice.
  Future<void> resolveConflict(ConflictChoice choice) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      switch (choice) {
        case ConflictChoice.overrideLocal:
          // Download latest S3 version and replace local DB
          final List<VersionEntry> backups = await _backupService.listBackups(_userId!);
          if (backups.isNotEmpty) {
            await _onPreRestore();
            await _backupService.restoreBackup(_userId!, backups.first.s3ObjectKey);
            await _onPostRestore();
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

      state = state.copyWith(hasConflict: false, isLoading: false);
    } on BackupException catch (e) {
      state = state.copyWith(
        errorMessage: _mapErrorCode(e.code),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'backup_failed',
        isLoading: false,
      );
    }
  }

  /// Refresh the version list from S3.
  Future<void> refreshVersions() async {
    if (_userId == null) return;

    try {
      final List<VersionEntry> versions = await _backupService.listBackups(_userId!);
      state = state.copyWith(versions: versions);
    } on BackupException catch (e) {
      state = state.copyWith(errorMessage: _mapErrorCode(e.code));
    } catch (e) {
      state = state.copyWith(errorMessage: 'backup_failed');
    }
  }

  /// Delete a specific version from S3.
  Future<void> deleteVersion(VersionEntry version) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _backupService.deleteBackup(version.s3ObjectKey);
      await refreshVersions();
      state = state.copyWith(isLoading: false);
    } on BackupException catch (e) {
      state = state.copyWith(
        errorMessage: _mapErrorCode(e.code),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'backup_failed',
        isLoading: false,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Close the DB connection before restore so the file isn't locked.
  Future<void> _onPreRestore() async {
    await DatabaseService().resetConnection();
  }

  /// After a restore, reset the DB connection and notify registered callbacks.
  Future<void> _onPostRestore() async {
    await DatabaseService().resetConnection();
    for (final PostRestoreCallback cb in _postRestoreCallbacks) {
      await cb();
    }
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
}

// ---------------------------------------------------------------------------
// Provider definition
// ---------------------------------------------------------------------------

final backupNotifierProvider =
    NotifierProvider<BackupNotifier, BackupState>(BackupNotifier.new);
