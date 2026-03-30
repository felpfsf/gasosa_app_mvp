import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteRefuelCommand {
  DeleteRefuelCommand({required RefuelRepository repository}) : _repository = repository;

  final RefuelRepository _repository;

  Future<Either<Failure, Unit>> call(String id) async => _repository.deleteRefuel(id);
}
