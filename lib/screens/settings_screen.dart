import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/core/app_card.dart';
import '../widgets/core/meander_divider.dart';
import '../providers/auth_notifier.dart';
import '../providers/settings_notifier.dart';
import '../providers/backup_notifier.dart';
import '../providers/profile_notifier.dart';
import '../router/app_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';
import '../models/ai/insight.dart';
import '../services/ocr_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final bool isAuthenticated = authNotifier.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: isAuthenticated
        ? _buildAuthenticatedSettings(context, ref, authNotifier, l10n)
        : _buildGuestSettings(context, authNotifier, l10n),
    );
  }

  Widget _buildAuthenticatedSettings(BuildContext context, WidgetRef ref, AuthNotifier authNotifier, AppLocalizations l10n) {
    final PlutusTokens t = context.tokens;
    final currentUser = authNotifier.currentUser;
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final profileState = ref.watch(profileNotifierProvider);
    final avatarPath = profileState.profile?.avatarPath;
    final Color avatarLetterColor = currentUser?.hasOAuth == true
        ? t.info.text
        : currentUser?.isGuest == true
            ? t.textSecondary
            : t.success.text;

    return ListView(
      children: [
        const SizedBox(height: AppSpacing.xl),
        CircleAvatar(
          radius: 50,
          backgroundColor: t.surfaceSubtle,
          backgroundImage: avatarPath != null
              ? FileImage(File(avatarPath))
              : null,
          child: avatarPath == null
              ? Text(
                  authNotifier.userName.isNotEmpty
                      ? authNotifier.userName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(fontSize: 40, color: avatarLetterColor),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            authNotifier.userName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            currentUser?.username != null ? '@${currentUser!.username}' : '',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        if (authNotifier.userEmail.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                authNotifier.userEmail,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (currentUser?.hasOAuth == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: t.info.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: t.info.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud, size: 14, color: t.info.text),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.googleLinked,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: t.info.text,
                        ),
                      ),
                    ],
                  ),
                ),
              if (currentUser?.isGuest == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: t.surfaceSubtle,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: t.border),
                  ),
                  child: Text(
                    l10n.guestMode,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),
                ),
              if (currentUser?.hasOAuth == false && currentUser?.isGuest == false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: t.success.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: t.success.border),
                  ),
                  child: Text(
                    l10n.localAccount,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.success.text,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Session info
        FutureBuilder<Map<String, dynamic>>(
          future: authNotifier.getSessionInfo(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final sessionInfo = snapshot.data!;
              final daysUntilExpiry = sessionInfo['daysUntilExpiry'] as int?;
              final isVerificationDue = sessionInfo['isVerificationDue'] as bool? ?? false;

              if (daysUntilExpiry == null || !isVerificationDue) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Container(
                  decoration: BoxDecoration(
                    color: t.info.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: t.info.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.offline_bolt, color: t.info.text),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.translate('settings_offline_access'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.translate('settings_offline_days_remaining').replaceFirst('\$days', daysUntilExpiry.toString()),
                          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.translate('settings_offline_message'),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        // Appearance Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Text(
            l10n.appearance.toUpperCase(),
            style: AppTextStyles.overlineStyle.copyWith(color: t.textSecondary),
          ),
        ),
        _buildThemeModeSelector(context, settings, settingsNotifier, l10n),
        const MeanderDivider(),

        // Preferences Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Text(
            l10n.preferences.toUpperCase(),
            style: AppTextStyles.overlineStyle.copyWith(color: t.textSecondary),
          ),
        ),
        _buildLanguageSelector(context, settings, settingsNotifier, l10n),
        _buildCurrencySelector(context, settings, settingsNotifier, l10n),
        _buildDateFormatSelector(context, settings, settingsNotifier, l10n),
        _buildTimeFormatSelector(context, settings, settingsNotifier, l10n),
        _buildBackupCard(context, ref, l10n),
        const MeanderDivider(),

        // AI & OCR Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Text(
            l10n.translate('settings_ai_ocr').toUpperCase(),
            style: AppTextStyles.overlineStyle.copyWith(color: t.textSecondary),
          ),
        ),
        _buildOcrModeSelector(context, settings, settingsNotifier),
        _buildAiPrivacySelector(context, settings, settingsNotifier),
        const MeanderDivider(),

        // Account Settings Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Text(
            l10n.accountSettings.toUpperCase(),
            style: AppTextStyles.overlineStyle.copyWith(color: t.textSecondary),
          ),
        ),
        if (currentUser?.hasOAuth == false && currentUser?.isGuest == false)
          ListTile(
            leading: Icon(Icons.link, color: t.brandNavy),
            title: Text(l10n.linkGoogle),
            subtitle: Text(l10n.translate('settings_backup_subtitle')),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.linkGoogle),
                  content: Text(
                    l10n.translate('settings_link_dialog'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.translate('settings_link_account')),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                final success = await authNotifier.linkOAuthAccount();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? l10n.translate('settings_google_connected')
                            : l10n.translate('settings_google_error'),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        if (currentUser?.hasOAuth == true)
          ListTile(
            leading: Icon(Icons.link_off, color: t.warning.text),
            title: Text(l10n.unlinkGoogle),
            subtitle: Text(l10n.translate('settings_local_subtitle')),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.unlinkGoogle),
                  content: Text(
                    l10n.translate('settings_unlink_dialog'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: t.warning.text),
                      child: Text(l10n.translate('settings_unlink')),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authNotifier.unlinkOAuthAccount();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('settings_google_disconnected')),
                    ),
                  );
                }
              }
            },
          ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.switch_account, color: t.brandNavy),
          title: Text(l10n.switchUser),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            context.go(AppRoutes.userSelection);
          },
        ),
        ListTile(
          leading: Icon(Icons.logout, color: t.error.text),
          title: Text(
            l10n.signOut,
            style: TextStyle(color: t.error.text),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.signOut),
                content: Text(l10n.areYouSureSignOut),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.signOut),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              await authNotifier.signOut();
              if (context.mounted) {
                context.go(AppRoutes.userSelection);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildGuestSettings(BuildContext context, AuthNotifier authNotifier, AppLocalizations l10n) {
    return ListView(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Icon(
            Icons.account_circle_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            l10n.guestMode,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            l10n.translate('settings_guest_message'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(AppRoutes.login);
            },
            icon: const Icon(Icons.login),
            label: Text(l10n.signIn),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, SettingsState settings, SettingsNotifier settingsNotifier, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_6),
              const SizedBox(width: AppSpacing.lg),
              Text(l10n.themeMode),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode, size: 16),
                  label: Text(l10n.themeLight, style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode, size: 16),
                  label: Text(l10n.themeDark, style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto, size: 16),
                  label: Text(l10n.themeSystem, style: const TextStyle(fontSize: 12)),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                settingsNotifier.setThemeMode(newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, SettingsState settings, SettingsNotifier settingsNotifier, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      trailing: DropdownButton<AppLanguage>(
        value: settings.language,
        items: AppLanguage.values.map((language) {
          return DropdownMenuItem(
            value: language,
            child: Text(language.displayName),
          );
        }).toList(),
        onChanged: (AppLanguage? newLanguage) {
          if (newLanguage != null) {
            settingsNotifier.setLanguage(newLanguage);
          }
        },
      ),
    );
  }

  Widget _buildCurrencySelector(BuildContext context, SettingsState settings, SettingsNotifier settingsNotifier, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.attach_money),
      title: Text(l10n.currency),
      trailing: DropdownButton<AppCurrency>(
        value: settings.currency,
        items: AppCurrency.values.map((currency) {
          return DropdownMenuItem(
            value: currency,
            child: Text(currency.isOriginal
                ? currency.displayName
                : '${currency.symbol} ${currency.code}'),
          );
        }).toList(),
        onChanged: (AppCurrency? newCurrency) {
          if (newCurrency != null) {
            settingsNotifier.setCurrency(newCurrency);
          }
        },
      ),
    );
  }

  Widget _buildDateFormatSelector(BuildContext context, SettingsState settings, SettingsNotifier settingsNotifier, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: Text(l10n.dateFormat),
      trailing: DropdownButton<DateFormatType>(
        value: settings.dateFormat,
        items: DateFormatType.values.map((format) {
          return DropdownMenuItem(
            value: format,
            child: Text(format.displayName),
          );
        }).toList(),
        onChanged: (DateFormatType? newFormat) {
          if (newFormat != null) {
            settingsNotifier.setDateFormat(newFormat);
          }
        },
      ),
    );
  }

  Widget _buildTimeFormatSelector(BuildContext context, SettingsState settings, SettingsNotifier settingsNotifier, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(l10n.timeFormat),
      trailing: DropdownButton<TimeFormatType>(
        value: settings.timeFormat,
        items: TimeFormatType.values.map((format) {
          return DropdownMenuItem(
            value: format,
            child: Text(format.displayName),
          );
        }).toList(),
        onChanged: (TimeFormatType? newFormat) {
          if (newFormat != null) {
            settingsNotifier.setTimeFormat(newFormat);
          }
        },
      ),
    );
  }

  Widget _buildOcrModeSelector(BuildContext context, SettingsState settings, SettingsNotifier settingsNotifier) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('settings_scanning_mode'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<OCRMode>(
              initialValue: settings.ocrMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(value: OCRMode.auto, child: Text(l10n.translate('settings_ocr_auto'))),
                DropdownMenuItem(value: OCRMode.online, child: Text(l10n.translate('settings_ocr_online'))),
                DropdownMenuItem(value: OCRMode.offline, child: Text(l10n.translate('settings_ocr_offline'))),
              ],
              onChanged: (val) {
                if (val != null) settingsNotifier.setOcrMode(val);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              settings.ocrMode == OCRMode.auto
                  ? l10n.translate('settings_ocr_auto_desc')
                  : settings.ocrMode == OCRMode.online
                      ? l10n.translate('settings_ocr_online_desc')
                      : l10n.translate('settings_ocr_offline_desc'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiPrivacySelector(BuildContext context, SettingsState settings, SettingsNotifier settingsNotifier) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('settings_ai_data_privacy'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<PrivacyLevel>(
              initialValue: settings.privacyLevel,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(value: PrivacyLevel.minimal, child: Text(l10n.translate('settings_privacy_minimal'))),
                DropdownMenuItem(value: PrivacyLevel.standard, child: Text(l10n.translate('settings_privacy_standard'))),
                DropdownMenuItem(value: PrivacyLevel.full, child: Text(l10n.translate('settings_privacy_full'))),
              ],
              onChanged: (val) {
                if (val != null) settingsNotifier.setPrivacyLevel(val);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              settings.privacyLevel == PrivacyLevel.minimal
                  ? l10n.translate('settings_privacy_minimal_desc')
                  : settings.privacyLevel == PrivacyLevel.standard
                      ? l10n.translate('settings_privacy_standard_desc')
                      : l10n.translate('settings_privacy_full_desc'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final PlutusTokens t = context.tokens;
    final backupState = ref.watch(backupNotifierProvider);
    final backupNotifier = ref.read(backupNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: t.brandNavy),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.backupSettings,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  backupState.isBackupEnabled
                      ? l10n.backupEnabled
                      : l10n.backupDisabled,
                ),
                Switch(
                  value: backupState.isBackupEnabled,
                  onChanged: backupState.isLoading
                      ? null
                      : (value) => backupNotifier.setBackupEnabled(value),
                ),
              ],
            ),
            Text(
              '${l10n.backupLastSync}: --',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            Text(
              'Cloud key: ${backupNotifier.backupKey?.substring(0, 8) ?? '-'} · remote: ${backupState.hasRemoteBackup ? 'found' : 'none'} · versions: ${backupState.versions.length}',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: backupState.isBackupEnabled && !backupState.isLoading
                    ? () => backupNotifier.triggerManualBackup()
                    : null,
                icon: backupState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                label: Text(l10n.backupManualBackup),
              ),
            ),
            if (backupState.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate(backupState.errorMessage!),
                style: TextStyle(fontSize: 12, color: t.error.text),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(Icons.history, color: t.brandNavy),
              title: Text(l10n.backupHistory),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push(AppRoutes.backupHistory),
            ),
          ],
        ),
      ),
    );
  }
}
