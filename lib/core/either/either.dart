import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';

typedef FResult<T> = Future<Either<Failure, T>>;
typedef Result<T> = Either<Failure, T>;