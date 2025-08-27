import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/local_photo_storage.dart';

class SaveVehiclePhotoCommand {
  SaveVehiclePhotoCommand(this._storage);
  final LocalPhotoStorage _storage;

  Future<Either<Failure, String>> call({
    required File file,
    String? oldPath,
  }) async {
    try {
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
