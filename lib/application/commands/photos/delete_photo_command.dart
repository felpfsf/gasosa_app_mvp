import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/local_photo_storage.dart';

class DeletePhotoCommand {
  DeletePhotoCommand(this._storage);
  final LocalPhotoStorage _storage;

  Future<Either<Failure, void>> call(String path) async {
    try {
      await _storage.deletePhoto(path);
      return right(null);
    } catch (e) {
      return left(StorageFailure('Error deleting photo: $e'));
    }
  }
}
