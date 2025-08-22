import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/domain/entities/user.dart';

abstract interface class UserRepository {
  FResult<Unit> save(UserEntity user);
  FResult<UserEntity?> getById(String id);
  FResult<UserEntity?> getByEmail(String email);
  FResult<Unit> update(UserEntity user);
  FResult<Unit> delete(String id);
}
