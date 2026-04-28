import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/data/local/dao/user_dao.dart';
import 'package:gasosa_app/data/mappers/user_mapper.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._dao);

  final UserDao _dao;

  @override
  Future<Either<Failure, Unit>> saveUser(AuthUser user) async {
    try {
      await _dao.insert(UserMapper.toCompanion(user));
      return right(unit);
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao salvar usuário', e, st));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getUserById(String id) async {
    try {
      final row = await _dao.getById(id);
      return right(row == null ? null : UserMapper.toDomain(row));
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao buscar usuário', e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePhotoPath(String userId, String? photoPath) async {
    try {
      await _dao.updatePhotoUrl(userId, photoPath);
      return right(unit);
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao atualizar foto do usuário', e, st));
    }
  }

  @override
  Stream<Either<Failure, AuthUser?>> watchUser(String userId) {
    return _dao
        .watchById(userId)
        .map((row) => right<Failure, AuthUser?>(row == null ? null : UserMapper.toDomain(row)))
        .handleError(
          (Object e, StackTrace st) => left<Failure, AuthUser?>(DatabaseFailure('Stream usuário falhou', e, st)),
        );
  }
}
