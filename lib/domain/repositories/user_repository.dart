import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';

abstract interface class UserRepository {
  Future<Either<Failure, Unit>> saveUser(AuthUser user);
  Future<Either<Failure, AuthUser?>> getUserById(String id);
  Future<Either<Failure, Unit>> updatePhotoPath(String userId, String? photoPath);
  Stream<Either<Failure, AuthUser?>> watchUser(String userId);
}
