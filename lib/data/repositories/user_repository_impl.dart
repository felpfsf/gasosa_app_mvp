import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/data/local/dao/user_dao.dart';
import 'package:gasosa_app/data/mappers/user_mapper.dart';
import 'package:gasosa_app/domain/entities/user.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(UserDao dao) : _dao = dao;
  final UserDao _dao;

  @override
  FResult<Unit> save(UserEntity user) async {
    try {
      await _dao.insert(UserMapper.toCompanion(user));
      return right(unit);
    } catch (e, s) {
      return left(DatabaseFailure('Erro ao salvar usuário', cause: e, stackTrace: s));
    }
  }

  @override
  FResult<UserEntity?> getById(String id) async {
    try {
      final row = await _dao.getById(id);
      if (row == null) {
        return left(const NotFoundFailure('Usuário não encontrado'));
      }

      return right(UserMapper.fromData(row));
    } catch (e, s) {
      return left(DatabaseFailure('Erro ao buscar usuário', cause: e, stackTrace: s));
    }
  }

  @override
  FResult<UserEntity?> getByEmail(String email) async {
    try {
      final row = await _dao.getByEmail(email);
      if (row == null) {
        return left(const NotFoundFailure('Usuário não encontrado'));
      }

      return right(UserMapper.fromData(row));
    } catch (e, s) {
      return left(DatabaseFailure('Erro ao buscar usuário', cause: e, stackTrace: s));
    }
  }

  @override
  FResult<Unit> update(UserEntity user) async {
    try {
      final updated = await _dao.updateUser(UserMapper.toData(user));
      if (!updated) {
        return left(const DatabaseFailure('Erro ao atualizar usuário'));
      }

      return right(unit);
    } catch (e, s) {
      return left(DatabaseFailure('Erro ao atualizar usuário', cause: e, stackTrace: s));
    }
  }

  @override
  FResult<Unit> delete(String id) async {
    try {
      await _dao.deleteById(id);
      return right(unit);
    } catch (e, s) {
      return left(DatabaseFailure('Erro ao deletar usuário', cause: e, stackTrace: s));
    }
  }
}
