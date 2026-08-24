import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/backup_models.dart';
import 'interfaces/i_backup_service.dart';
import 'interfaces/i_sync_manager.dart';
import '../di/service_locator.dart';

class SyncManager implements ISyncManager {
  final IBackupService _backupService;

  /// Polling timer: checks DB checksum every 30 seconds.
  Timer? _pollingTimer;

  /// Debounce timer: waits 2 minutes after last detected change.
  Timer? _debounceTimer;

  /// The user ID for the current auto-sync session.
  String? _backupKey;

  /// Last known checksum of the local DB.
  String? _lastKnownChecksum;

  /// Whether the device currently has network connectivity.
  bool _isConnected = true;

  /// Queue of user IDs with pending uploads (from connectivity loss).
  final List<String> _pendingUploads = [];

  static const Duration _pollInterval = Duration(seconds: 30);
  static const Duration _debounceDelay = Duration(minutes: 2);

  SyncManager({IBackupService? backupService})
      : _backupService = backupService ?? sl<IBackupService>();

  /// Check for conflict between local DB and latest S3 backup.
  /// Returns ConflictResult indicating match, mismatch, no-remote, or offline.
  @override
  Future<ConflictResult> checkConflictOnLaunch(String backupKey) async {
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
          await _backupService.getLatestBackupChecksum(backupKey);
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
  /// Polls local DB checksum every 30 seconds.
  /// Triggers upload 2 minutes after last detected change.
  @override
  void startAutoSync(String backupKey) {
    stopAutoSync();
    _backupKey = backupKey;

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
    _backupKey = null;
    _lastKnownChecksum = null;
  }

  /// Handle connectivity changes. Retries queued uploads on reconnect.
  @override
  void onConnectivityChanged(bool isConnected) {
    _isConnected = isConnected;

    if (isConnected && _pendingUploads.isNotEmpty) {
      // Copy and clear the queue, then retry each
      final toRetry = List<String>.from(_pendingUploads);
      _pendingUploads.clear();

      for (final backupKey in toRetry) {
        _triggerUpload(backupKey);
      }
    }
  }

  /// Poll the local DB for changes by comparing its checksum.
  /// (Checksum instead of File.stat() so it also works on web.)
  Future<void> _pollForChanges() async {
    if (_backupKey == null) return;

    try {
      final currentChecksum = await _backupService.computeLocalChecksum();

      if (_lastKnownChecksum == null) {
        // First poll — just record the current checksum
        _lastKnownChecksum = currentChecksum;
        return;
      }

      if (currentChecksum != _lastKnownChecksum) {
        // DB was modified — reset debounce timer
        _lastKnownChecksum = currentChecksum;
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
    final backupKey = _backupKey;
    if (backupKey == null) return;

    _debounceTimer = Timer(_debounceDelay, () {
      _triggerUpload(backupKey);
    });
  }

  /// Trigger an upload via BackupService.
  /// If offline, queue the upload for retry on reconnect.
  Future<void> _triggerUpload(String backupKey) async {
    if (!_isConnected) {
      if (!_pendingUploads.contains(backupKey)) {
        _pendingUploads.add(backupKey);
      }
      return;
    }

    try {
      await _backupService.uploadBackup(backupKey);
      if (kDebugMode) {
        debugPrint('SyncManager: Auto-sync upload completed for $backupKey');
      }
    } on BackupException catch (e) {
      if (e.code == 'network_error') {
        // Queue for retry on reconnect
        if (!_pendingUploads.contains(backupKey)) {
          _pendingUploads.add(backupKey);
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
