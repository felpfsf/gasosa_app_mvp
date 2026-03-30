import 'dart:io';

import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/local_photo_storage.dart';
import 'package:injectable/injectable.dart';

@injectable
class SavePhotoCommand {
  SavePhotoCommand(this._storage);
  final LocalPhotoStorage _storage;

  Future<Either<Failure, String>> call({required File file, String? oldPath}) async {
    try {
      if (!await file.exists()) {
        return left(const UnexpectedFailure('Arquivo de foto não encontrado', null, null));
      }

      final newPath = await _storage.savePhoto(file);
      if (oldPath != null && oldPath.isNotEmpty && oldPath != newPath) {
        try {
          await _storage.deletePhoto(oldPath);
        } catch (_) {}
      }

      return right(newPath);
    } catch (e) {
      return left(UnexpectedFailure('Falha ao salvar foto: $e', null, null));
    }
  }
}
