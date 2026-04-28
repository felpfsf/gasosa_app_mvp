import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/profile/viewmodel/profile_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_avatar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_confirm_dialog.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_edit_name_dialog.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<ProfileViewModel>();
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showGasosaConfirmDialog(
      context,
      title: ProfileStrings.logoutDialogTitle,
      content: ProfileStrings.logoutDialogContent,
      confirmLabel: ProfileStrings.logoutDialogConfirmLabel,
      danger: true,
    );
    if (!confirmed || !mounted) return;

    await _viewModel.logout();
    if (mounted) context.go(Routes.login);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showGasosaConfirmDialog(
      context,
      title: ProfileStrings.deleteAccountDialogTitle,
      content: ProfileStrings.deleteAccountDialogContent,
      confirmLabel: ProfileStrings.deleteAccountDialogConfirmLabel,
      danger: true,
    );
    if (!confirmed || !mounted) return;

    final result = await _viewModel.deleteAccount();
    if (!mounted) return;

    result.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) {
        Messages.showSuccess(context, ProfileStrings.deleteAccountSuccess);
        context.go(Routes.login);
      },
    );
  }

  Future<void> _editName(String currentName) async {
    final newName = await showGasosaEditNameDialog(context, currentName: currentName);
    if (newName == null || !mounted) return;

    final result = await _viewModel.updateDisplayName(newName);
    if (!mounted) return;

    result.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) => Messages.showSuccess(context, ProfileStrings.editNameSuccess),
    );
  }

  Future<void> _pickAvatar() async {
    final source = await _showPhotoSourceSheet();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null || !mounted) return;

    final result = await _viewModel.updateAvatar(File(picked.path));
    if (!mounted) return;

    result.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) => Messages.showSuccess(context, ProfileStrings.changePhotoSuccess),
    );
  }

  Future<ImageSource?> _showPhotoSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(ProfileStrings.changePhotoSourceTitle, style: AppTypography.textSmBold),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(ProfileStrings.changePhotoSourceCamera, style: AppTypography.textSmRegular),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(ProfileStrings.changePhotoSourceGallery, style: AppTypography.textSmRegular),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _removeAvatar() async {
    final result = await _viewModel.removeAvatar();
    if (!mounted) return;

    result.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) => Messages.showSuccess(context, ProfileStrings.removePhotoSuccess),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: _viewModel.currentUser,
      builder: (context, user, _) {
        return ValueListenableBuilder<File?>(
          valueListenable: _viewModel.localAvatar,
          builder: (context, localAvatar, _) {
            final hasLocalPhoto = localAvatar != null;

            return Scaffold(
              appBar: GasosaAppbar(
                title: ProfileStrings.screenTitle,
                showBackButton: true,
              ),
              body: ListView(
                padding: AppSpacing.paddingMd,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Avatar
                  Center(
                    child: GasosaAvatar(
                      localFile: localAvatar,
                      photoUrl: user?.photoUrl,
                      size: 96,
                      onTap: _pickAvatar,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Nome
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.xs,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: AppTypography.textLgBold,
                        ),
                        IconButton(
                          onPressed: () => _editName(user?.name ?? ''),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: ProfileStrings.editNameMenuLabel,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Email
                  Center(
                    child: Text(
                      user?.email ?? '',
                      style: AppTypography.textSmRegular.copyWith(
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),

                  // Foto
                  _SectionTile(
                    icon: Icons.camera_alt_outlined,
                    label: ProfileStrings.changePhotoMenuLabel,
                    onTap: _pickAvatar,
                  ),
                  if (hasLocalPhoto)
                    _SectionTile(
                      icon: Icons.hide_image_outlined,
                      label: ProfileStrings.removePhotoMenuLabel,
                      onTap: _removeAvatar,
                    ),

                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),

                  // Conta
                  _SectionTile(
                    icon: Icons.logout,
                    label: ProfileStrings.logoutLabel,
                    onTap: _logout,
                  ),
                  _SectionTile(
                    icon: Icons.delete_forever_outlined,
                    label: ProfileStrings.deleteAccountLabel,
                    onTap: _deleteAccount,
                    destructive: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.text;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTypography.textSmRegular.copyWith(color: color)),
      onTap: onTap,
    );
  }
}
