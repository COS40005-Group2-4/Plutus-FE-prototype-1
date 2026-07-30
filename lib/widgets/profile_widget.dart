import 'dart:io';
import '../../theme/app_spacing.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../providers/profile_notifier.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';
import 'avatar_editor_widget.dart';

/// Main Profile Widget for displaying and editing user profile
class ProfileWidget extends ConsumerStatefulWidget {
  final User user;
  final String defaultAvatarAsset;
  final bool isCompact;

  const ProfileWidget({
    super.key,
    required this.user,
    required this.defaultAvatarAsset,
    this.isCompact = false,
  });

  @override
  ConsumerState<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends ConsumerState<ProfileWidget> {
  late TextEditingController _dobController;
  late TextEditingController _positionController;
  late TextEditingController _employmentController;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _dobController = TextEditingController();
    _positionController = TextEditingController();
    _employmentController = TextEditingController();
    _loadAvatarBytes();
  }

  Future<void> _loadAvatarBytes() async {
    try {
      final blob = await DatabaseService().getAvatarBlob(widget.user.id);
      if (blob != null && mounted) {
        setState(() => _avatarBytes = blob);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _dobController.dispose();
    _positionController.dispose();
    _employmentController.dispose();
    super.dispose();
  }

  void _initializeControllers(Profile profile) {
    _dobController.text = profile.dateOfBirth ?? '';
    _positionController.text = profile.position ?? '';
    _employmentController.text = profile.placeOfEmployment ?? '';
  }

  void _showAvatarPicker(Profile profile) {
    showDialog(
      context: context,
      builder: (context) => AvatarPickerDialog(
        onAvatarSelected: (file) {
          ref.read(profileNotifierProvider.notifier).updateAvatar(file);
        },
      ),
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = picked.toString().split(' ')[0];
    }
  }

  void _showEditDialog(Profile profile) {
    _initializeControllers(profile);
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (ctx, dialogRef, _) {
          final profileState = dialogRef.watch(profileNotifierProvider);
          final p = profileState.profile ?? profile;
          return _buildEditDialog(p, dialogRef);
        },
      ),
    );
  }

  Widget _buildEditDialog(Profile profile, WidgetRef dialogRef) {
    final PlutusTokens t = context.tokens;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 24,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: t.border,
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: t.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: t.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildEditTextField(
                label: 'Date of Birth',
                controller: _dobController,
                icon: Icons.calendar_today,
                onTap: _selectDate,
              ),
              const SizedBox(height: 12),
              _buildEditTextField(
                label: 'Position',
                controller: _positionController,
                icon: Icons.work,
              ),
              const SizedBox(height: 12),
              _buildEditTextField(
                label: 'Place of Employment',
                controller: _employmentController,
                icon: Icons.business,
              ),
              const SizedBox(height: 24),
              Text(
                'Display on dashboard',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 12),
              _buildEditDialogCheckbox(
                'Name',
                profile.showName,
                'name',
                dialogRef,
              ),
              _buildEditDialogCheckbox(
                'Email',
                profile.showEmail,
                'email',
                dialogRef,
              ),
              if (profile.dateOfBirth != null &&
                  profile.dateOfBirth!.isNotEmpty)
                _buildEditDialogCheckbox(
                  'Date of Birth',
                  profile.showDateOfBirth,
                  'dateOfBirth',
                  dialogRef,
                ),
              if (profile.position != null && profile.position!.isNotEmpty)
                _buildEditDialogCheckbox(
                  'Position',
                  profile.showPosition,
                  'position',
                  dialogRef,
                ),
              if (profile.placeOfEmployment != null &&
                  profile.placeOfEmployment!.isNotEmpty)
                _buildEditDialogCheckbox(
                  'Place of Employment',
                  profile.showPlaceOfEmployment,
                  'placeOfEmployment',
                  dialogRef,
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final hasDob = _dobController.text.isNotEmpty;
                        final hasPosition = _positionController.text.isNotEmpty;
                        final hasEmployment =
                            _employmentController.text.isNotEmpty;
                        final wasAddingDob = profile.dateOfBirth == null ||
                            profile.dateOfBirth!.isEmpty;
                        final wasAddingPosition = profile.position == null ||
                            profile.position!.isEmpty;
                        final wasAddingEmployment =
                            profile.placeOfEmployment == null ||
                                profile.placeOfEmployment!.isEmpty;
                        await ref.read(profileNotifierProvider.notifier).updateProfile(
                          dateOfBirth:
                              hasDob ? _dobController.text : null,
                          position:
                              hasPosition ? _positionController.text : null,
                          placeOfEmployment:
                              hasEmployment ? _employmentController.text : null,
                          showDateOfBirth: hasDob && wasAddingDob ? true : null,
                          showPosition:
                              hasPosition && wasAddingPosition ? true : null,
                          showPlaceOfEmployment:
                              hasEmployment && wasAddingEmployment ? true : null,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final PlutusTokens t = context.tokens;
    return TextField(
      controller: controller,
      readOnly: onTap != null,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: t.textSecondary),
      ),
    );
  }

  Widget _buildEditDialogCheckbox(
    String label,
    bool value,
    String fieldName,
    WidgetRef dialogRef,
  ) {
    final PlutusTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) async {
              if (newValue != null) {
                await dialogRef.read(profileNotifierProvider.notifier).toggleFieldVisibility(fieldName);
              }
            },
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: t.text, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityCheckbox(
    String label,
    bool value,
    String fieldName,
  ) {
    final PlutusTokens t = context.tokens;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) async {
              if (newValue != null) {
                await ref.read(profileNotifierProvider.notifier).toggleFieldVisibility(fieldName);
              }
            },
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.profile;

    if (profileState.status == ProfileStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profileState.status == ProfileStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: t.error.text),
              const SizedBox(height: AppSpacing.lg),
              Text(
                profileState.errorMessage,
                style: TextStyle(color: t.text),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.error.dot,
                  foregroundColor: t.onStatus,
                ),
                onPressed: () {
                  ref.read(profileNotifierProvider.notifier).resetState();
                  ref.read(profileNotifierProvider.notifier).loadProfile(widget.user.id);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Build display mode or edit mode
    if (widget.isCompact) {
      return _buildCompactView(profile);
    } else {
      return _buildFullView(profile);
    }
  }

  Widget _buildCompactView(Profile profile) {
    final PlutusTokens t = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isCompact = width < 200 || height < 250;
        final avatarSize = _responsiveSize(width, height, min: 48, max: 96);
        final titleSize = _responsiveSize(width, height, min: 12, max: 16);
        final labelSize = _responsiveSize(width, height, min: 9, max: 11);
        final valueSize = _responsiveSize(width, height, min: 11, max: 14);
        final spacing = _responsiveSize(width, height, min: 4, max: 12);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing,
                  vertical: spacing * 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isCompact ? 28 : 36),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showAvatarPicker(profile),
                        child: _buildAvatarCircle(profile, size: avatarSize),
                      ),
                    ),
                    SizedBox(height: spacing),
                    if (profile.showName)
                      _buildCompactInfoItem(
                        'Name',
                        widget.user.displayName,
                        labelSize: labelSize,
                        valueSize: valueSize,
                        isPrimary: true,
                        valueColor: t.text,
                        labelColor: t.textMuted,
                      ),
                    if (profile.showName &&
                        (profile.showEmail ||
                            (profile.dateOfBirth != null &&
                                profile.dateOfBirth!.isNotEmpty &&
                                profile.showDateOfBirth) ||
                            (profile.position != null &&
                                profile.position!.isNotEmpty &&
                                profile.showPosition) ||
                            (profile.placeOfEmployment != null &&
                                profile.placeOfEmployment!.isNotEmpty &&
                                profile.showPlaceOfEmployment)))
                      Divider(
                        height: spacing,
                        color: t.border,
                        thickness: 1,
                      ),
                    if (profile.showEmail &&
                        widget.user.email != null &&
                        widget.user.email!.isNotEmpty)
                      _buildCompactInfoItem(
                        'Email',
                        widget.user.email!,
                        labelSize: labelSize,
                        valueSize: valueSize,
                        valueColor: t.text,
                        labelColor: t.textMuted,
                      ),
                    if (profile.dateOfBirth != null &&
                        profile.dateOfBirth!.isNotEmpty &&
                        profile.showDateOfBirth)
                      _buildCompactInfoItem(
                        'DOB',
                        profile.dateOfBirth!,
                        labelSize: labelSize,
                        valueSize: valueSize,
                        valueColor: t.text,
                        labelColor: t.textMuted,
                      ),
                    if (profile.position != null &&
                        profile.position!.isNotEmpty &&
                        profile.showPosition)
                      _buildCompactInfoItem(
                        'Position',
                        profile.position!,
                        labelSize: labelSize,
                        valueSize: valueSize,
                        valueColor: t.text,
                        labelColor: t.textMuted,
                      ),
                    if (profile.placeOfEmployment != null &&
                        profile.placeOfEmployment!.isNotEmpty &&
                        profile.showPlaceOfEmployment)
                      _buildCompactInfoItem(
                        'Employment',
                        profile.placeOfEmployment!,
                        labelSize: labelSize,
                        valueSize: valueSize,
                        valueColor: t.text,
                        labelColor: t.textMuted,
                      ),
                    SizedBox(height: spacing),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).myProfile,
                        style: TextStyle(
                          color: t.text,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showEditDialog(profile),
                        borderRadius: AppRadius.borderXl,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            color: t.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _responsiveSize(double width, double height, {required double min, required double max}) {
    final shortSide = width < height ? width : height;
    final factor = ((shortSide - 80) / 320).clamp(0.0, 1.0);
    return min + (max - min) * factor;
  }

  Widget _buildCompactInfoItem(
    String label,
    String value, {
    required double labelSize,
    required double valueSize,
    bool isPrimary = false,
    Color? labelColor,
    Color? valueColor,
  }) {
    final PlutusTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.overlineStyle.copyWith(
              fontSize: labelSize,
              color: labelColor ?? t.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              color: valueColor ?? t.text,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(Profile profile) {
    final PlutusTokens t = context.tokens;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final avatarSize = isSmallScreen ? 100.0 : 120.0;
    final horizontalPadding = isSmallScreen ? 12.0 : 20.0;
    final verticalPadding = isSmallScreen ? 12.0 : 20.0;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: t.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: t.textSecondary),
                  onPressed: () => _showEditDialog(profile),
                  tooltip: 'Edit Profile',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            SizedBox(height: verticalPadding),

            // Avatar section
            Center(
              child: GestureDetector(
                onTap: () => _showAvatarPicker(profile),
                child: _buildAvatarCircle(profile, size: avatarSize),
              ),
            ),
            SizedBox(height: verticalPadding),

            // User information section
            _buildInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Name',
                    value: widget.user.displayName,
                    isVisible: profile.showName,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: widget.user.email ?? 'Not provided',
                    isVisible: profile.showEmail,
                  ),
                  if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) ...[
                    const Divider(),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date of Birth',
                      value: profile.dateOfBirth!,
                      isVisible: profile.showDateOfBirth,
                    ),
                  ],
                  if (profile.position != null && profile.position!.isNotEmpty) ...[
                    const Divider(),
                    _buildInfoRow(
                      icon: Icons.work,
                      label: 'Position',
                      value: profile.position!,
                      isVisible: profile.showPosition,
                    ),
                  ],
                  if (profile.placeOfEmployment != null &&
                      profile.placeOfEmployment!.isNotEmpty) ...[
                    const Divider(),
                    _buildInfoRow(
                      icon: Icons.business,
                      label: 'Place of Employment',
                      value: profile.placeOfEmployment!,
                      isVisible: profile.showPlaceOfEmployment,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: verticalPadding),

            // Visibility settings section
            Text(
              'Dashboard Visibility',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: t.text,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoCard(
              child: Column(
                children: [
                  _buildVisibilityCheckbox(
                    'Show Name',
                    profile.showName,
                    'name',
                  ),
                  _buildVisibilityCheckbox(
                    'Show Email',
                    profile.showEmail,
                    'email',
                  ),
                  if (profile.dateOfBirth != null &&
                      profile.dateOfBirth!.isNotEmpty)
                    _buildVisibilityCheckbox(
                      'Show Date of Birth',
                      profile.showDateOfBirth,
                      'dateOfBirth',
                    ),
                  if (profile.position != null && profile.position!.isNotEmpty)
                    _buildVisibilityCheckbox(
                      'Show Position',
                      profile.showPosition,
                      'position',
                    ),
                  if (profile.placeOfEmployment != null &&
                      profile.placeOfEmployment!.isNotEmpty)
                    _buildVisibilityCheckbox(
                      'Show Place of Employment',
                      profile.showPlaceOfEmployment,
                      'placeOfEmployment',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(Profile profile, {required double size}) {
    final PlutusTokens t = context.tokens;
    final ringWidth = (size * 0.06).clamp(2.0, 4.0);
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: t.border,
              width: ringWidth,
            ),
            boxShadow: t.shadowLow,
          ),
          child: ClipOval(
            child: _buildAvatarImage(profile, size: size),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all((size * 0.12).clamp(4.0, 8.0)),
            decoration: BoxDecoration(
              color: t.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: t.border,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              color: t.textSecondary,
              size: (size * 0.2).clamp(12.0, 18.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(Profile profile, {required double size}) {
    // Cap decoded resolution at ~3× the rendered logical size so memory
    // stays small on retina displays without visible quality loss.
    final cacheDim = (size * 3).round();

    // On web, load from DB blob since dart:io File is unavailable
    if (kIsWeb) {
      if (_avatarBytes != null) {
        return Image.memory(
          _avatarBytes!,
          fit: BoxFit.cover,
          cacheWidth: cacheDim,
          cacheHeight: cacheDim,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            widget.defaultAvatarAsset,
            fit: BoxFit.cover,
            cacheWidth: cacheDim,
            cacheHeight: cacheDim,
          ),
        );
      }
      return Image.asset(
        widget.defaultAvatarAsset,
        fit: BoxFit.cover,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
      );
    }

    // On native platforms, load from file path
    if (profile.avatarPath != null && File(profile.avatarPath!).existsSync()) {
      return Image.file(
        File(profile.avatarPath!),
        fit: BoxFit.cover,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          widget.defaultAvatarAsset,
          fit: BoxFit.cover,
          cacheWidth: cacheDim,
          cacheHeight: cacheDim,
        ),
      );
    }
    return Image.asset(
      widget.defaultAvatarAsset,
      fit: BoxFit.cover,
      cacheWidth: cacheDim,
      cacheHeight: cacheDim,
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    final PlutusTokens t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: t.surfaceSubtle,
        border: Border.all(
          color: t.border,
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isVisible,
  }) {
    final PlutusTokens t = context.tokens;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Opacity(
      opacity: isVisible ? 1.0 : 0.5,
      child: Row(
        children: [
          Icon(icon, color: t.textSecondary, size: isSmallScreen ? 18 : 20),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: t.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: t.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
