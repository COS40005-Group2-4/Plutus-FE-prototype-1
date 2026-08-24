import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/backup_models.dart';
import '../providers/backup_notifier.dart';
import '../theme/plutus_tokens.dart';
import '../widgets/core/app_card.dart';
import '../widgets/core/status_badge.dart';

class BackupHistoryScreen extends ConsumerStatefulWidget {
  const BackupHistoryScreen({super.key});

  @override
  ConsumerState<BackupHistoryScreen> createState() => _BackupHistoryScreenState();
}

class _BackupHistoryScreenState extends ConsumerState<BackupHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupNotifierProvider.notifier).refreshVersions();
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTimestamp(DateTime timestamp) {
    final y = timestamp.year.toString();
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    final h = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<void> _confirmRestore(BuildContext context, VersionEntry version) async {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupRestore),
        content: Text(l10n.backupRestoreConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: t.error.text),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(backupNotifierProvider.notifier).restoreVersion(version);
      if (context.mounted) {
        final backupState = ref.read(backupNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backupState.errorMessage != null
                  ? AppLocalizations.of(context).translate(backupState.errorMessage!)
                  : AppLocalizations.of(context).backupSuccess,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final backupState = ref.watch(backupNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupHistory),
      ),
      body: Builder(
        builder: (context) {
          if (backupState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (backupState.versions.isEmpty) {
            final String? err = backupState.errorMessage;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: t.textMuted),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    err != null ? l10n.translate(err) : l10n.backupNoVersions,
                    style: TextStyle(fontSize: 16, color: t.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: backupState.versions.length,
            itemBuilder: (context, index) {
              final version = backupState.versions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => _confirmRestore(context, version),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_done, color: t.brandNavy),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.backupVersionTimestamp}: ${_formatTimestamp(version.timestamp)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${l10n.backupVersionSize}: ${_formatFileSize(version.fileSizeBytes)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: t.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            StatusBadge(kind: StatusKind.success, label: l10n.done),
                          ],
                        ),
                      ),
                      Icon(Icons.restore, color: t.textSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
