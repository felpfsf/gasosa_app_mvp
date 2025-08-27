import 'dart:io';

import 'package:gasosa_app/core/helpers/uuid.dart';
import 'package:gasosa_app/domain/services/local_photo_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalPhotoStorageImpl implements LocalPhotoStorage {
  static const _folder = 'photos';

  Future<Directory> _ensureDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<String> savePhoto(File photo) async {
    if (!await photo.exists()) {
      throw FileSystemException('Arquivo não encontrado', photo.path);
    }

    final dir = await _ensureDir();
    final ext = p.extension(photo.path).toLowerCase();
    final name = '${UuidHelper.generate()}${ext.isNotEmpty ? ext : '.jpg'}';
    final destPath = p.join(dir.path, name);

    final saved = await photo.copy(destPath);
    return saved.path;
  }

  @override
  Future<void> deletePhoto(String path) async {
    if (path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
