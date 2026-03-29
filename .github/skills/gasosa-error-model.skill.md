# Skill — Gasosa Error Model

**Modelo de tratamento de erros com Either e Failures**

---

## Visão Geral

O Gasosa App usa **tratamento funcional de erros** com:
- **Either monad** (pacote `dartz`) para tornar erros explícitos
- **Failure hierarchy** para categorizar erros semanticamente
- **Nunca lançar exceptions** em camadas de domínio/aplicação

---

## Either Monad

### Conceito

`Either<L, R>` representa um valor que pode ser **Left** (erro) ou **Right** (sucesso).

```dart
import 'package:dartz/dartz.dart';

// Left = Failure
// Right = Success

Either<Failure, VehicleEntity> result = Right(vehicle); // Sucesso
Either<Failure, VehicleEntity> result = Left(NotFoundFailure('...')); // Erro
```

### Pattern Matching

```dart
final result = await repository.getById(id);

result.fold(
  (failure) {
    // Left: Tratar erro
    print('Erro: ${failure.message}');
  },
  (vehicle) {
    // Right: Sucesso
    print('Veículo: ${vehicle.name}');
  },
);
```

### Métodos Úteis

```dart
// isLeft() / isRight()
if (result.isLeft()) {
  print('Deu erro');
}

// getOrElse() - pega valor ou default
final vehicle = result.getOrElse(() => VehicleEntity.empty());

// map() - transforma Right (mantém Left)
final nameResult = result.map((vehicle) => vehicle.name);
// Se result é Right(vehicle), retorna Right(vehicle.name)
// Se result é Left(failure), retorna Left(failure)

// flatMap() / bind() - encadear operações
final result = await repository.getById(id);
final updateResult = result.flatMap((vehicle) {
  vehicle = vehicle.copyWith(name: 'Novo Nome');
  return repository.save(vehicle);
});
```

---

## Hierarchy de Failures

### Estrutura Base

```dart
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  Failure(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'Failure(message: $message, code: $code)';
}
```

### Failures Específicos

```dart
// 1. Validação (entrada inválida)
class ValidationFailure extends Failure {
  ValidationFailure(String message) 
      : super(message, code: 'VALIDATION_ERROR');
}

// 2. Persistência local (Drift)
class DatabaseFailure extends Failure {
  DatabaseFailure(String message, {dynamic originalError})
      : super(message, code: 'DATABASE_ERROR', originalError: originalError);
}

// 3. Rede/Firebase
class NetworkFailure extends Failure {
  NetworkFailure(String message, {dynamic originalError})
      : super(message, code: 'NETWORK_ERROR', originalError: originalError);
}

// 4. Autenticação/Autorização
class AuthFailure extends Failure {
  AuthFailure(String message) 
      : super(message, code: 'AUTH_ERROR');
}

// 5. Recurso não encontrado
class NotFoundFailure extends Failure {
  NotFoundFailure(String message) 
      : super(message, code: 'NOT_FOUND');
}

// 6. Permissões
class PermissionFailure extends Failure {
  PermissionFailure(String message)
      : super(message, code: 'PERMISSION_DENIED');
}

// 7. Erro desconhecido
class UnknownFailure extends Failure {
  UnknownFailure({String message = 'Erro desconhecido', dynamic originalError})
      : super(message, code: 'UNKNOWN_ERROR', originalError: originalError);
}
```

---

## Quando Usar Cada Failure

### 1. ValidationFailure

**Quando:** Entrada do usuário é inválida.

```dart
ValidationFailure? _validate(String name, String plate) {
  if (name.isEmpty) return ValidationFailure('Nome é obrigatório');
  if (plate.length < 7) return ValidationFailure('Placa inválida');
  return null;
}
```

### 2. DatabaseFailure

**Quando:** Erro ao persistir/recuperar dados localmente (Drift).

```dart
@override
Future<Either<Failure, VehicleEntity>> save(VehicleEntity vehicle) async {
  try {
    final companion = VehicleMapper.toCompanion(vehicle);
    await _dao.insertOrUpdate(companion);
    return Right(vehicle);
  } catch (e, stack) {
    return Left(DatabaseFailure('Erro ao salvar veículo', originalError: e));
  }
}
```

### 3. NetworkFailure

**Quando:** Erro de rede (timeout, sem internet, HTTP error).

```dart
Future<Either<Failure, List<VehicleEntity>>> syncFromCloud() async {
  try {
    final response = await _http.get('/vehicles');
    if (response.statusCode != 200) {
      return Left(NetworkFailure('Erro ao sincronizar: ${response.statusCode}'));
    }
    // ...
  } on SocketException {
    return Left(NetworkFailure('Sem conexão com a internet'));
  } on TimeoutException {
    return Left(NetworkFailure('Timeout ao conectar ao servidor'));
  }
}
```

### 4. AuthFailure

**Quando:** Credenciais inválidas, sessão expirada, usuário não autenticado.

```dart
Future<Either<Failure, UserEntity>> signIn(String email, String password) async {
  try {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // ...
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'user-not-found':
        return Left(AuthFailure('Usuário não encontrado'));
      case 'wrong-password':
        return Left(AuthFailure('Senha incorreta'));
      default:
        return Left(AuthFailure('Erro de autenticação'));
    }
  }
}
```

### 5. NotFoundFailure

**Quando:** Entidade não existe (getById retorna null).

```dart
@override
Future<Either<Failure, VehicleEntity>> getById(String id) async {
  try {
    final vehicleDb = await _dao.getById(id);
    if (vehicleDb == null) {
      return Left(NotFoundFailure('Veículo não encontrado'));
    }
    return Right(VehicleMapper.toEntity(vehicleDb));
  } catch (e) {
    return Left(DatabaseFailure('Erro ao buscar veículo'));
  }
}
```

### 6. PermissionFailure

**Quando:** Usuário não tem permissão (ex: tentar deletar veículo de outro usuário).

```dart
Future<Either<Failure, Unit>> delete(String vehicleId, String userId) async {
  final vehicleResult = await _repository.getById(vehicleId);
  
  return vehicleResult.flatMap((vehicle) {
    if (vehicle.userId != userId) {
      return Left(PermissionFailure('Você não tem permissão para deletar este veículo'));
    }
    return _repository.delete(vehicleId);
  });
}
```

---

## Padrões de Uso

### 1. Command Retorna Either

```dart
class CreateVehicleCommand {
  Future<Either<Failure, VehicleEntity>> execute({...}) async {
    // Validação
    final validation = _validate(name, plate);
    if (validation != null) return Left(validation);

    // Criação
    final vehicle = VehicleEntity(...);

    // Persistência
    return _repository.save(vehicle);
  }
}
```

### 2. ViewModel Trata Either

```dart
class VehicleFormViewModel extends ChangeNotifier {
  final CreateVehicleCommand _createCommand;

  Future<void> saveVehicle({...}) async {
    final result = await _createCommand.execute(...);

    result.fold(
      (failure) {
        // Tratar erro na UI
        _showError(failure.message);
      },
      (vehicle) {
        // Sucesso
        _showSuccess('Veículo salvo com sucesso');
        _navigateBack();
      },
    );
  }
}
```

### 3. Repository Converte Exceptions em Failures

```dart
@override
Future<Either<Failure, VehicleEntity>> save(VehicleEntity vehicle) async {
  try {
    // Lógica de persistência
    await _dao.insertOrUpdate(...);
    return Right(vehicle);
  } on SqliteException catch (e) {
    if (e.code == 19) { // CONSTRAINT violation
      return Left(DatabaseFailure('Placa já cadastrada'));
    }
    return Left(DatabaseFailure('Erro ao salvar veículo', originalError: e));
  } catch (e) {
    return Left(UnknownFailure(originalError: e));
  }
}
```

---

## Composição de Either

### Encadeamento com flatMap

```dart
Future<Either<Failure, RefuelEntity>> createRefuel({...}) async {
  // 1. Verificar se veículo existe
  final vehicleResult = await _vehicleRepository.getById(vehicleId);

  // 2. Se veículo existe, criar abastecimento
  return vehicleResult.flatMap((vehicle) async {
    final refuel = RefuelEntity(...);
    return _refuelRepository.save(refuel);
  });

  // Se vehicleResult é Left, retorna Left (não executa flatMap)
  // Se vehicleResult é Right, executa flatMap
}
```

### Combinar Múltiplos Either

```dart
Future<Either<Failure, SyncResult>> syncAll() async {
  final vehiclesResult = await syncVehicles();
  final refuelsResult = await syncRefuels();

  if (vehiclesResult.isLeft()) return vehiclesResult.flatMap((_) => Left(UnknownFailure()));
  if (refuelsResult.isLeft()) return refuelsResult.flatMap((_) => Left(UnknownFailure()));

  return Right(SyncResult(
    vehicles: vehiclesResult.getOrElse(() => []),
    refuels: refuelsResult.getOrElse(() => []),
  ));
}
```

---

## UI Display de Failures

```dart
String getErrorMessage(Failure failure) {
  if (failure is ValidationFailure) {
    return failure.message; // Mensagem já é user-friendly
  }
  
  if (failure is DatabaseFailure) {
    return 'Erro ao salvar dados. Tente novamente.';
  }
  
  if (failure is NetworkFailure) {
    return 'Erro de conexão. Verifique sua internet.';
  }
  
  if (failure is AuthFailure) {
    return failure.message;
  }
  
  if (failure is NotFoundFailure) {
    return 'Recurso não encontrado.';
  }
  
  return 'Erro inesperado. Tente novamente.';
}
```

---

## Logging de Failures

```dart
void logFailure(Failure failure) {
  final crashlytics = getIt<CrashlyticsService>();

  crashlytics.log('[${failure.code}] ${failure.message}');

  if (failure.originalError != null) {
    crashlytics.recordError(
      failure.originalError,
      StackTrace.current,
      reason: failure.message,
      fatal: false,
    );
  }
}
```

---

## Checklist de Qualidade

- [ ] Métodos de domínio/aplicação retornam `Either<Failure, Result>`?
- [ ] Failures são específicos (ValidationFailure, DatabaseFailure, etc.)?
- [ ] Exceptions são capturadas e convertidas em Left(Failure)?
- [ ] UI trata Left e Right no fold()?
- [ ] Mensagens de erro são user-friendly?
- [ ] Failures são logados no Crashlytics (se necessário)?

---

**Referências:**
- Pacote: `dartz` (https://pub.dev/packages/dartz)
- `lib/core/failures/` → Implementação de Failures
