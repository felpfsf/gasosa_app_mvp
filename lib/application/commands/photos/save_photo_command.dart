import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/local_photo_storage.dart';

class SavePhotoCommand {
  SavePhotoCommand(this._storage);
  final LocalPhotoStorage _storage;

  Future<Either<Failure, String>> call({required File file, String? oldPath}) async {
    try {
      if (!await file.exists()) {
        return left(const StorageFailure('Arquivo de foto não encontrado'));
      }

      final newPath = await _storage.savePhoto(file);
      if (oldPath != null && oldPath.isNotEmpty && oldPath != newPath) {
        try {
          await _storage.deletePhoto(oldPath);
        } catch (_) {}
      }
      
      return right(newPath);
    } catch (e) {
      return left(StorageFailure('Falha ao salvar foto: $e'));
    }
  }
}
