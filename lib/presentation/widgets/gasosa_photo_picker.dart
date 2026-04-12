import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  File? _localImage;
  final _picker = ImagePicker();
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _localImage = widget.image;
  }

  @override
  void didUpdateWidget(covariant GasosaPhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image?.path != oldWidget.image?.path) {
      setState(() => _localImage = widget.image);
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (!mounted) return;
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() => _localImage = file);
        widget.onFileSelected(file);
      }
    } catch (e) {
      if (!context.mounted) return;
      Messages.showError(context, 'Não foi possível selecionar a imagem.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickFromFiles() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'],
      );
      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() => _localImage = file);
        widget.onFileSelected(file);
      }
    } catch (e) {
      if (!context.mounted) return;
      Messages.showError(context, 'Não foi possível selecionar o arquivo.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _remove() {
    setState(() => _localImage = null);
    widget.onFileSelected(null);
  }

  void _preview(File image) {
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
                child: Image.file(image, fit: BoxFit.contain, gaplessPlayback: true),
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

  void _showOptions(BuildContext context, {required bool hasImage}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.text.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.of(context).pop();
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.of(context).pop();
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Arquivos'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFromFiles();
              },
            ),
            if (hasImage) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _remove();
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _localImage ?? widget.image;
    final hasImage = image != null && image.existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => hasImage ? _preview(image) : _showOptions(context, hasImage: hasImage),
          child: ClipRRect(
            borderRadius: AppSpacing.radiusMd,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Hero(
                      tag: image.path,
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surface,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: AppSpacing.sm,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary.withValues(alpha: 0.7),
                            size: 40,
                          ),
                          Text(
                            'Toque para adicionar foto',
                            style: TextStyle(
                              color: AppColors.text.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isPicking)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (hasImage)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _showOptions(context, hasImage: hasImage),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
