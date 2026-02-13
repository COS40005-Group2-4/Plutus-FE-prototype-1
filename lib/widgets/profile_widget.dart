import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../providers/profile_provider.dart';
import '../l10n/app_localizations.dart';
import 'avatar_editor_widget.dart';

/// Main Profile Widget for displaying and editing user profile
class ProfileWidget extends StatefulWidget {
  final User user;
  final String defaultAvatarAsset;
  final bool isCompact;

  const ProfileWidget({
    Key? key,
    required this.user,
    required this.defaultAvatarAsset,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late ProfileProvider _profileProvider;
  late TextEditingController _dobController;
  late TextEditingController _positionController;
  late TextEditingController _employmentController;

  @override
  void initState() {
    super.initState();
    _dobController = TextEditingController();
    _positionController = TextEditingController();
    _employmentController = TextEditingController();

    _profileProvider = ProfileProvider();
    _profileProvider.loadProfile(widget.user.id);
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

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (context) => AvatarPickerDialog(
        currentAvatarPath: _profileProvider.profile?.avatarPath,
        defaultAvatarAsset: widget.defaultAvatarAsset,
        onAvatarSelected: (file) {
          _profileProvider.updateAvatar(file);
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
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: _profileProvider,
        child: Consumer<ProfileProvider>(
          builder: (ctx, provider, _) {
            final p = provider.profile ?? profile;
            return _buildEditDialog(p);
          },
        ),
      ),
    );
  }

  Widget _buildEditDialog(Profile profile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final maxWidth = isSmallScreen ? double.infinity : 500.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 24,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
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
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildEditDialogCheckbox(
                'Name',
                profile.showName,
                'name',
              ),
              _buildEditDialogCheckbox(
                'Email',
                profile.showEmail,
                'email',
              ),
              if (profile.dateOfBirth != null &&
                  profile.dateOfBirth!.isNotEmpty)
                _buildEditDialogCheckbox(
                  'Date of Birth',
                  profile.showDateOfBirth,
                  'dateOfBirth',
                ),
              if (profile.position != null && profile.position!.isNotEmpty)
                _buildEditDialogCheckbox(
                  'Position',
                  profile.showPosition,
                  'position',
                ),
              if (profile.placeOfEmployment != null &&
                  profile.placeOfEmployment!.isNotEmpty)
                _buildEditDialogCheckbox(
                  'Place of Employment',
                  profile.showPlaceOfEmployment,
                  'placeOfEmployment',
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
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
                        await _profileProvider.updateProfile(
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
    return TextField(
      controller: controller,
      readOnly: onTap != null,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildEditDialogCheckbox(
    String label,
    bool value,
    String fieldName,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) async {
              if (newValue != null) {
                await _profileProvider.toggleFieldVisibility(fieldName);
              }
            },
            fillColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.blue,
            ),
            checkColor: Colors.white,
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
                await _profileProvider.toggleFieldVisibility(fieldName);
              }
            },
            fillColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.blue,
            ),
            checkColor: Colors.white,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _profileProvider,
      child: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          final profile = profileProvider.profile;

          if (profileProvider.state == ProfileState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileProvider.state == ProfileState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      profileProvider.errorMessage,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      profileProvider.resetState();
                      _profileProvider.loadProfile(widget.user.id);
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
        },
      ),
    );
  }

  Widget _buildCompactView(Profile profile) {
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
                        onTap: _showAvatarPicker,
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                                         ),
                    if (profile.dateOfBirth != null &&
                        profile.dateOfBirth!.isNotEmpty &&
                        profile.showDateOfBirth)
                      _buildCompactInfoItem(
                        'DOB',
                        profile.dateOfBirth!,
                        labelSize: labelSize,
                        valueSize: valueSize,
                      ),
                    if (profile.position != null &&
                        profile.position!.isNotEmpty &&
                        profile.showPosition)
                      _buildCompactInfoItem(
                        'Position',
                        profile.position!,
                        labelSize: labelSize,
                        valueSize: valueSize,
                      ),
                    if (profile.placeOfEmployment != null &&
                        profile.placeOfEmployment!.isNotEmpty &&
                        profile.showPlaceOfEmployment)
                      _buildCompactInfoItem(
                        'Employment',
                        profile.placeOfEmployment!,
                        labelSize: labelSize,
                        valueSize: valueSize,
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).myProfile,
                        style: TextStyle(
                          color: Colors.white,
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
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Colors.white.withValues(alpha: 0.9),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: labelSize,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                color: Colors.white,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(Profile profile) {
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
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
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
                onTap: _showAvatarPicker,
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
                  const Divider(color: Colors.white24),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: widget.user.email ?? 'Not provided',
                    isVisible: profile.showEmail,
                  ),
                  if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) ...[
                    const Divider(color: Colors.white24),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date of Birth',
                      value: profile.dateOfBirth!,
                      isVisible: profile.showDateOfBirth,
                    ),
                  ],
                  if (profile.position != null && profile.position!.isNotEmpty) ...[
                    const Divider(color: Colors.white24),
                    _buildInfoRow(
                      icon: Icons.work,
                      label: 'Position',
                      value: profile.position!,
                      isVisible: profile.showPosition,
                    ),
                  ],
                  if (profile.placeOfEmployment != null &&
                      profile.placeOfEmployment!.isNotEmpty) ...[
                    const Divider(color: Colors.white24),
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
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
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
    final ringWidth = (size * 0.06).clamp(2.0, 4.0);
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: ringWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: _buildAvatarImage(profile),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all((size * 0.12).clamp(4.0, 8.0)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: (size * 0.2).clamp(12.0, 18.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(Profile profile) {
    if (profile.avatarPath != null && File(profile.avatarPath!).existsSync()) {
      return Image.file(
        File(profile.avatarPath!),
        fit: BoxFit.cover,
      );
    }
    return Image.asset(
      widget.defaultAvatarAsset,
      fit: BoxFit.cover,
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Opacity(
      opacity: isVisible ? 1.0 : 0.5,
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: isSmallScreen ? 18 : 20),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
