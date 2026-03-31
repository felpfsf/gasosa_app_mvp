import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/local_photo_storage.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeletePhotoUseCase {
  DeletePhotoUseCase(this._storage);
  final LocalPhotoStorage _storage;

  Future<Either<Failure, void>> call(String path) async {
    try {
      await _storage.deletePhoto(path);
      return right(null);
    } catch (e) {
      return left(UnexpectedFailure('Falha ao deletar foto', e, null));
    }
  }
}
