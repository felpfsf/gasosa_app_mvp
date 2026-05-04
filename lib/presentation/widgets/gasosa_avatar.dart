import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';

class GasosaAvatar extends StatelessWidget {
  const GasosaAvatar({
    super.key,
    this.localFile,
    this.photoUrl,
    this.size = 48,
    this.onTap,
  });

  /// Foto local (prioridade máxima). Usado após o usuário definir um avatar local.
  final File? localFile;

  /// URL de foto remota (ex: Google). Usada apenas se [localFile] for nulo ou inválido.
  final String? photoUrl;

  final double size;

  /// Callback opcional — quando fornecido, o avatar torna-se tappable com indicador visual.
  final VoidCallback? onTap;

  /// Chave única para forçar o Flutter a recarregar a imagem quando a fonte muda.
  Object get _imageKey => localFile?.path ?? photoUrl ?? 'default';

  Widget _buildImageContent() {
    if (localFile != null) {
      return Image.file(
        localFile!,
        key: ValueKey(_imageKey),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _defaultAvatar(),
      );
    }
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        key: ValueKey(_imageKey),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _defaultAvatar(),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() => Image.asset(
    'assets/images/avatar_placeholder.png',
    key: const ValueKey('default'),
    fit: BoxFit.cover,
    width: size,
    height: size,
  );

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.5)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: ColoredBox(
            color: AppColors.surface,
            child: _buildImageContent(),
          ),
        ),
      ),
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          Container(
            width: size * 0.35,
            height: size * 0.35,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 1.5),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: size * 0.2,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}
