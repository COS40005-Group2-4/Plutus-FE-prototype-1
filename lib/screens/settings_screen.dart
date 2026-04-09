import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/backup_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../models/ai/insight.dart';
import '../services/ocr_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      ),
      body: authProvider.isAuthenticated 
        ? _buildAuthenticatedSettings(context, authProvider)
        : _buildGuestSettings(context, authProvider),
    );
  }

  Widget _buildAuthenticatedSettings(BuildContext context, AuthProvider authProvider) {
    final currentUser = authProvider.currentUser;
    final l10n = AppLocalizations.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return ListView(
      children: [
        const SizedBox(height: AppSpacing.xl),
        CircleAvatar(
          radius: 50,
          backgroundColor: currentUser?.hasOAuth == true
              ? AppColors.primary
              : currentUser?.isGuest == true
                  ? Colors.grey
                  : AppColors.success,
          child: Text(
            authProvider.userName.isNotEmpty 
                ? authProvider.userName[0].toUpperCase() 
                : 'U',
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            authProvider.userName,
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        if (authProvider.userEmail.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                authProvider.userEmail,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
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
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud, size: 14, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.googleLinked,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
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
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Text(
                    l10n.guestMode,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Text(
                    l10n.localAccount,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Session info
        FutureBuilder<Map<String, dynamic>>(
          future: authProvider.getSessionInfo(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final sessionInfo = snapshot.data!;
              final daysUntilExpiry = sessionInfo['daysUntilExpiry'] as int?;
              final isVerificationDue = sessionInfo['isVerificationDue'] as bool? ?? false;

              // Only show the offline banner when the session is unverified
              // (i.e. the user hasn't been confirmed online recently).
              // Right after a fresh sign-in, isVerificationDue is false,
              // so we hide the banner.
              if (daysUntilExpiry == null || !isVerificationDue) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: GlassContainer(
                  borderRadius: 12,
                  color: AppColors.primary,
                  opacity: 0.1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.offline_bolt, color: AppColors.primary),
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
                        if (daysUntilExpiry != null)
                          Text(
                            l10n.translate('settings_offline_days_remaining').replaceFirst('\$days', daysUntilExpiry.toString()),
                            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.translate('settings_offline_message'),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
            l10n.appearance,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildThemeModeSelector(context, settingsProvider, l10n),
        const Divider(),
        
        // Preferences Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Text(
            l10n.preferences,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildLanguageSelector(context, settingsProvider, l10n),
        _buildCurrencySelector(context, settingsProvider, l10n),
        _buildDateFormatSelector(context, settingsProvider, l10n),
        _buildTimeFormatSelector(context, settingsProvider, l10n),
        _buildBackupCard(context, l10n),
        const Divider(),

        // AI & OCR Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Text(
            l10n.translate('settings_ai_ocr'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildOcrModeSelector(context, settingsProvider),
        _buildAiPrivacySelector(context, settingsProvider),
        const Divider(),

        // Account Settings Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Text(
            l10n.accountSettings,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (currentUser?.hasOAuth == false && currentUser?.isGuest == false)
          ListTile(
            leading: const Icon(Icons.link, color: AppColors.primary),
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
                final success = await authProvider.linkOAuthAccount();
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
            leading: const Icon(Icons.link_off, color: Colors.orange),
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
                      style: TextButton.styleFrom(foregroundColor: Colors.orange),
                      child: Text(l10n.translate('settings_unlink')),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && context.mounted) {
                await authProvider.unlinkOAuthAccount();
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
          leading: const Icon(Icons.switch_account, color: AppColors.primary),
          title: Text(l10n.switchUser),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/user_selection');
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: Text(
            l10n.signOut,
            style: const TextStyle(color: AppColors.error),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.signOut),
                content: const Text('Are you sure you want to sign out?'),
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
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/user_selection');
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildGuestSettings(BuildContext context, AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context);
    
    return ListView(
      children: [
        const SizedBox(height: 40),
        const Center(
          child: Icon(
            Icons.account_circle_outlined,
            size: 100,
            color: Colors.grey,
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
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            icon: const Icon(Icons.login),
            label: Text(l10n.signIn),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, SettingsProvider settingsProvider, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_6),
              const SizedBox(width: 16),
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
              selected: {settingsProvider.themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                settingsProvider.setThemeMode(newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, SettingsProvider settingsProvider, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      trailing: DropdownButton<AppLanguage>(
        value: settingsProvider.language,
        items: AppLanguage.values.map((language) {
          return DropdownMenuItem(
            value: language,
            child: Text(language.displayName),
          );
        }).toList(),
        onChanged: (AppLanguage? newLanguage) {
          if (newLanguage != null) {
            settingsProvider.setLanguage(newLanguage);
          }
        },
      ),
    );
  }

  Widget _buildCurrencySelector(BuildContext context, SettingsProvider settingsProvider, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.attach_money),
      title: Text(l10n.currency),
      trailing: DropdownButton<AppCurrency>(
        value: settingsProvider.currency,
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
            settingsProvider.setCurrency(newCurrency);
          }
        },
      ),
    );
  }

  Widget _buildDateFormatSelector(BuildContext context, SettingsProvider settingsProvider, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: Text(l10n.dateFormat),
      trailing: DropdownButton<DateFormatType>(
        value: settingsProvider.dateFormat,
        items: DateFormatType.values.map((format) {
          return DropdownMenuItem(
            value: format,
            child: Text(format.displayName),
          );
        }).toList(),
        onChanged: (DateFormatType? newFormat) {
          if (newFormat != null) {
            settingsProvider.setDateFormat(newFormat);
          }
        },
      ),
    );
  }

  Widget _buildTimeFormatSelector(BuildContext context, SettingsProvider settingsProvider, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(l10n.timeFormat),
      trailing: DropdownButton<TimeFormatType>(
        value: settingsProvider.timeFormat,
        items: TimeFormatType.values.map((format) {
          return DropdownMenuItem(
            value: format,
            child: Text(format.displayName),
          );
        }).toList(),
        onChanged: (TimeFormatType? newFormat) {
          if (newFormat != null) {
            settingsProvider.setTimeFormat(newFormat);
          }
        },
      ),
    );
  }

  Widget _buildOcrModeSelector(BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.lg,
        opacity: 0.08,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('settings_scanning_mode'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<OCRMode>(
              initialValue: settingsProvider.ocrMode,
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
                if (val != null) settingsProvider.setOcrMode(val);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              settingsProvider.ocrMode == OCRMode.auto
                  ? l10n.translate('settings_ocr_auto_desc')
                  : settingsProvider.ocrMode == OCRMode.online
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

  Widget _buildAiPrivacySelector(BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.lg,
        opacity: 0.08,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('settings_ai_data_privacy'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<PrivacyLevel>(
              initialValue: settingsProvider.privacyLevel,
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
                if (val != null) settingsProvider.setPrivacyLevel(val);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              settingsProvider.privacyLevel == PrivacyLevel.minimal
                  ? l10n.translate('settings_privacy_minimal_desc')
                  : settingsProvider.privacyLevel == PrivacyLevel.standard
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

  Widget _buildBackupCard(BuildContext context, AppLocalizations l10n) {
    final backupProvider = context.watch<BackupProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: GlassContainer(
        borderRadius: 12,
        opacity: 0.1,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload, color: AppColors.primary),
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
                  backupProvider.isBackupEnabled
                      ? l10n.backupEnabled
                      : l10n.backupDisabled,
                ),
                Switch(
                  value: backupProvider.isBackupEnabled,
                  onChanged: backupProvider.isLoading
                      ? null
                      : (value) => backupProvider.setBackupEnabled(value),
                ),
              ],
            ),
            Text(
              '${l10n.backupLastSync}: --',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: backupProvider.isBackupEnabled && !backupProvider.isLoading
                    ? () => backupProvider.triggerManualBackup()
                    : null,
                icon: backupProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                label: Text(l10n.backupManualBackup),
              ),
            ),
            if (backupProvider.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate(backupProvider.errorMessage!),
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: Text(l10n.backupHistory),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, '/backup-history'),
            ),
          ],
        ),
      ),
    );
  }
}
