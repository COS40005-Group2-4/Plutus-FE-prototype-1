import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/backup_models.dart';
import 'interfaces/i_backup_service.dart';
import 'interfaces/i_sync_manager.dart';
import '../di/service_locator.dart';

class SyncManager implements ISyncManager {
  final IBackupService _backupService;

  /// Polling timer: checks DB file modification time every 30 seconds.
  Timer? _pollingTimer;

  /// Debounce timer: waits 2 minutes after last detected change.
  Timer? _debounceTimer;

  /// The user ID for the current auto-sync session.
  int? _userId;

  /// Last known modification time of the DB file.
  DateTime? _lastKnownModTime;

  /// Whether the device currently has network connectivity.
  bool _isConnected = true;

  /// Queue of user IDs with pending uploads (from connectivity loss).
  final List<int> _pendingUploads = [];

  static const Duration _pollInterval = Duration(seconds: 30);
  static const Duration _debounceDelay = Duration(minutes: 2);

  SyncManager({IBackupService? backupService})
      : _backupService = backupService ?? sl<IBackupService>();

  /// Check for conflict between local DB and latest S3 backup.
  /// Returns ConflictResult indicating match, mismatch, no-remote, or offline.
  @override
  Future<ConflictResult> checkConflictOnLaunch(int userId) async {
    // Check connectivity first
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        return ConflictResult.offline;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncManager: Connectivity check failed: $e');
      }
      return ConflictResult.offline;
    }

    try {
      // Fetch remote checksum
      final remoteChecksum =
          await _backupService.getLatestBackupChecksum(userId);
      if (remoteChecksum == null) {
        return ConflictResult.noRemote;
      }

      // Compute local checksum
      final localChecksum = await _backupService.computeLocalChecksum();

      // Compare
      if (localChecksum == remoteChecksum) {
        return ConflictResult.match;
      } else {
        return ConflictResult.mismatch;
      }
    } on BackupException catch (e) {
      if (kDebugMode) {
        debugPrint('SyncManager: Conflict check error: ${e.message}');
      }
      return ConflictResult.error;
    }
  }

  /// Start the debounced auto-sync polling loop.
  /// Polls local DB file modification time every 30 seconds.
  /// Triggers upload 2 minutes after last detected change.
  @override
  void startAutoSync(int userId) {
    stopAutoSync();
    _userId = userId;

    _pollingTimer = Timer.periodic(_pollInterval, (_) => _pollForChanges());
  }

  /// Stop auto-sync: cancel polling timer and debounce timer.
  /// Does NOT trigger an upload (per Requirement 5.5).
  @override
  void stopAutoSync() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _userId = null;
    _lastKnownModTime = null;
  }

  /// Handle connectivity changes. Retries queued uploads on reconnect.
  @override
  void onConnectivityChanged(bool isConnected) {
    _isConnected = isConnected;

    if (isConnected && _pendingUploads.isNotEmpty) {
      // Copy and clear the queue, then retry each
      final toRetry = List<int>.from(_pendingUploads);
      _pendingUploads.clear();

      for (final userId in toRetry) {
        _triggerUpload(userId);
      }
    }
  }

  /// Poll the DB file for modification time changes.
  Future<void> _pollForChanges() async {
    if (_userId == null) return;

    try {
      final dbPath = await _backupService.getDatabasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) return;

      final stat = await dbFile.stat();
      final currentModTime = stat.modified;

      if (_lastKnownModTime == null) {
        // First poll — just record the current mod time
        _lastKnownModTime = currentModTime;
        return;
      }

      if (currentModTime.isAfter(_lastKnownModTime!)) {
        // File was modified — reset debounce timer
        _lastKnownModTime = currentModTime;
        _resetDebounceTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncManager: Error polling for changes: $e');
      }
    }
  }

  /// Reset the 2-minute debounce timer.
  /// If a timer is already running, cancel it and start a new one.
  void _resetDebounceTimer() {
    _debounceTimer?.cancel();
    final userId = _userId;
    if (userId == null) return;

    _debounceTimer = Timer(_debounceDelay, () {
      _triggerUpload(userId);
    });
  }

  /// Trigger an upload via BackupService.
  /// If offline, queue the upload for retry on reconnect.
  Future<void> _triggerUpload(int userId) async {
    if (!_isConnected) {
      if (!_pendingUploads.contains(userId)) {
        _pendingUploads.add(userId);
      }
      return;
    }

    try {
      await _backupService.uploadBackup(userId);
      if (kDebugMode) {
        debugPrint('SyncManager: Auto-sync upload completed for user $userId');
      }
    } on BackupException catch (e) {
      if (e.code == 'network_error') {
        // Queue for retry on reconnect
        if (!_pendingUploads.contains(userId)) {
          _pendingUploads.add(userId);
        }
      }
      if (kDebugMode) {
        debugPrint('SyncManager: Upload failed: ${e.message}');
      }
    }
  }

  /// Whether auto-sync is currently active.
  @override
  bool get isAutoSyncActive => _pollingTimer != null;

  /// Whether there are pending uploads queued.
  @override
  bool get hasPendingUploads => _pendingUploads.isNotEmpty;
}
