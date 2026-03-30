import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/user.dart';

abstract interface class UserRepository {
  Future<Either<Failure, Unit>> save(UserEntity user);
  Future<Either<Failure, UserEntity?>> getById(String id);
  Future<Either<Failure, UserEntity?>> getByEmail(String email);
  Future<Either<Failure, Unit>> update(UserEntity user);
  Future<Either<Failure, Unit>> delete(String id);
}
