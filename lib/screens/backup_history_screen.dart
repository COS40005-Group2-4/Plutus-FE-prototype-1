import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/backup_models.dart';
import '../providers/backup_notifier.dart';
import '../widgets/glass_container.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

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
    final backupState = ref.watch(backupNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupHistory),
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      ),
      body: Builder(
        builder: (context) {
          if (backupState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (backupState.versions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.backupNoVersions,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
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
                child: GlassContainer(
                  borderRadius: AppRadius.md,
                  opacity: 0.1,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: InkWell(
                    onTap: () => _confirmRestore(context, version),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_done, color: AppColors.primary),
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
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.restore, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ],
                    ),
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
