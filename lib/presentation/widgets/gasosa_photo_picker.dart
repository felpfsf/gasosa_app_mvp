import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:image_picker/image_picker.dart';

class GasosaPhotoPicker extends StatefulWidget {
  const GasosaPhotoPicker({super.key, required this.label, this.image, required this.onFileSelected});

  final String label;
  final File? image;
  final ValueChanged<File?> onFileSelected;

  @override
  State<GasosaPhotoPicker> createState() => _GasosaPhotoPickerState();
}

class _GasosaPhotoPickerState extends State<GasosaPhotoPicker> {
  final _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> pick(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final pickeFile = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
      if (!mounted) return;
      if (pickeFile != null) {
        final file = File(pickeFile.path);
        widget.onFileSelected(file);
      }
    } catch (e) {
      if (!context.mounted) return;
      Messages.showError(context, 'Não foi possível selecionar a imagem.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _remove() {
    widget.onFileSelected(null);
    setState(() {});
  }

  void _preview() {
    final image = widget.image;
    if (image == null) return;
    showDialog(
      context: context,
      barrierColor: AppColors.background.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Hero(
                tag: image.path,
                child: Image.file(
                  image,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close, color: AppColors.text),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;

    Widget buildPreview() {
      final hasImage = image != null && image.existsSync();
      return GestureDetector(
        onTap: hasImage ? _preview : null,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: AppSpacing.radiusMd,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: hasImage
                    ? Hero(
                        tag: image.path,
                        child: Image.file(image, width: double.infinity, height: 180, fit: BoxFit.cover),
                      )
                    : Container(
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.directions_car_filled_outlined,
                          color: AppColors.primary,
                          size: 64,
                        ),
                      ),
              ),
            ),
            if (hasImage)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  child: IconButton(
                    tooltip: 'Remover foto',
                    onPressed: _remove,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.text),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget buildButtons() {
      if (image != null && image.existsSync()) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _preview,
                icon: const Icon(Icons.remove_red_eye),
                label: const Text('Visualizar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _remove,
                icon: const Icon(Icons.delete),
                label: const Text('Remover'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Câmera'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeria'),
            ),
          ),
          if (_isPicking) ...[
            AppSpacing.gap16,
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        buildPreview(),
        buildButtons(),
      ],
    );
  }
}
