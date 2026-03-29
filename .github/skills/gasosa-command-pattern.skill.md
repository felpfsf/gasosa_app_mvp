# Skill — Gasosa Command Pattern

**Padrão Command (Use Cases) do Gasosa App**

---

## Visão Geral

Commands representam **casos de uso** (use cases) no Gasosa App. São a ponte entre a camada de apresentação e o domínio, orquestrando regras de negócio sem implementar infraestrutura.

---

## Estrutura Padrão

### Anatomia de um Command

```dart
import 'package:dartz/dartz.dart';
import '../../core/failures/failure.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/i_vehicle_repository.dart';

class CreateOrUpdateVehicleCommand {
  // 1. DEPENDÊNCIAS (injetadas via constructor)
  final IVehicleRepository _repository;

  CreateOrUpdateVehicleCommand(this._repository);

  // 2. MÉTODO EXECUTE (entry point)
  Future<Either<Failure, VehicleEntity>> execute({
    String? id,
    required String userId,
    required String name,
    required String plate,
    String? brand,
    String? model,
    int? year,
  }) async {
    // 3. VALIDAÇÃO (fail fast)
    final validation = _validate(name, plate);
    if (validation != null) return Left(validation);

    // 4. CRIAÇÃO DA ENTIDADE
    final vehicle = VehicleEntity(
      id: id ?? _generateId(),
      userId: userId,
      name: name,
      plate: plate,
      brand: brand,
      model: model,
      year: year,
    );

    // 5. PERSISTÊNCIA (delega para Repository)
    return _repository.save(vehicle);
  }

  // 6. VALIDAÇÕES PRIVADAS
  ValidationFailure? _validate(String name, String plate) {
    if (name.isEmpty) return ValidationFailure('Nome é obrigatório');
    if (plate.isEmpty) return ValidationFailure('Placa é obrigatória');
    if (plate.length < 7) return ValidationFailure('Placa inválida');
    return null;
  }

  String _generateId() => Uuid().v4();
}
```

---

## Responsabilidades de um Command

### ✅ O que Commands DEVEM fazer

1. **Validar entradas** (fail fast)
2. **Orquestrar regras de negócio**
3. **Chamar Repositories**
4. **Retornar `Either<Failure, Result>`**
5. **Logar analytics** (se aplicável)

### ❌ O que Commands NÃO DEVEM fazer

1. **Implementar persistência** (delegar para Repository)
2. **Conhecer Drift/Firebase** (usar abstrações)
3. **Manipular UI** (sem BuildContext)
4. **Lançar exceptions** (retornar Left(Failure))

---

## Padrões por Tipo de Operação

### 1. Create/Update (CRUD)

```dart
class CreateOrUpdateRefuelCommand {
  final IRefuelRepository _repository;
  final IVehicleRepository _vehicleRepository;

  CreateOrUpdateRefuelCommand(this._repository, this._vehicleRepository);

  Future<Either<Failure, RefuelEntity>> execute({
    String? id,
    required String vehicleId,
    required DateTime date,
    required double liters,
    required double totalValue,
    required double odometer,
    bool fullTank = true,
  }) async {
    // 1. Validação
    final validation = _validate(liters, totalValue, odometer);
    if (validation != null) return Left(validation);

    // 2. Verificar se veículo existe
    final vehicleResult = await _vehicleRepository.getById(vehicleId);
    if (vehicleResult.isLeft()) return Left(NotFoundFailure('Veículo não encontrado'));

    // 3. Criar entidade
    final refuel = RefuelEntity(
      id: id ?? Uuid().v4(),
      vehicleId: vehicleId,
      date: date,
      liters: liters,
      totalValue: totalValue,
      odometer: odometer,
      fullTank: fullTank,
      pricePerLiter: totalValue / liters,
    );

    // 4. Salvar
    return _repository.save(refuel);
  }

  ValidationFailure? _validate(double liters, double totalValue, double odometer) {
    if (liters <= 0) return ValidationFailure('Litros deve ser maior que zero');
    if (totalValue <= 0) return ValidationFailure('Valor total deve ser maior que zero');
    if (odometer < 0) return ValidationFailure('Km inválido');
    return null;
  }
}
```

### 2. Read (Load/Query)

```dart
class LoadRefuelsByVehicleCommand {
  final IRefuelRepository _repository;

  LoadRefuelsByVehicleCommand(this._repository);

  Future<Either<Failure, List<RefuelEntity>>> execute({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _repository.getByVehicle(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
```

### 3. Delete

```dart
class DeleteVehicleCommand {
  final IVehicleRepository _vehicleRepository;
  final IRefuelRepository _refuelRepository;

  DeleteVehicleCommand(this._vehicleRepository, this._refuelRepository);

  Future<Either<Failure, Unit>> execute({required String vehicleId}) async {
    // 1. Verificar se veículo existe
    final vehicleResult = await _vehicleRepository.getById(vehicleId);
    if (vehicleResult.isLeft()) return Left(NotFoundFailure('Veículo não encontrado'));

    // 2. Deletar abastecimentos associados (cascade)
    await _refuelRepository.deleteByVehicle(vehicleId);

    // 3. Deletar veículo
    return _vehicleRepository.delete(vehicleId);
  }
}
```

### 4. Cálculos/Business Logic

```dart
class CalculateConsumptionCommand {
  final IRefuelRepository _repository;

  CalculateConsumptionCommand(this._repository);

  Future<Either<Failure, double>> execute({required String vehicleId}) async {
    // 1. Buscar abastecimentos (tanque cheio apenas)
    final refuelsResult = await _repository.getByVehicle(
      vehicleId: vehicleId,
      fullTankOnly: true,
    );

    if (refuelsResult.isLeft()) return refuelsResult.fold((f) => Left(f), (_) => Left(UnknownFailure()));

    final refuels = refuelsResult.getOrElse(() => []);

    // 2. Validar dados suficientes
    if (refuels.length < 2) {
      return Left(ValidationFailure('Necessário pelo menos 2 abastecimentos completos'));
    }

    // 3. Calcular consumo médio
    refuels.sort((a, b) => a.date.compareTo(b.date));

    final firstRefuel = refuels.first;
    final lastRefuel = refuels.last;

    final totalKm = lastRefuel.odometer - firstRefuel.odometer;
    final totalLiters = refuels.skip(1).fold<double>(0, (sum, r) => sum + r.liters);

    if (totalLiters == 0) return Left(ValidationFailure('Total de litros inválido'));

    final consumption = totalKm / totalLiters;

    return Right(consumption);
  }
}
```

### 5. Commands com Analytics

```dart
class LoginEmailPasswordCommand {
  final IAuthRepository _authRepository;
  final AnalyticsService _analytics;

  LoginEmailPasswordCommand(this._authRepository, this._analytics);

  Future<Either<Failure, UserEntity>> execute({
    required String email,
    required String password,
  }) async {
    // 1. Validação
    final emailValidation = Validators.email(email);
    if (emailValidation != null) return Left(ValidationFailure(emailValidation));

    final passwordValidation = Validators.password(password);
    if (passwordValidation != null) return Left(ValidationFailure(passwordValidation));

    // 2. Login
    final result = await _authRepository.signInWithEmailPassword(email, password);

    // 3. Log analytics (somente se sucesso)
    result.fold(
      (_) {}, // Não loga se falhou
      (_) => _analytics.logLogin('email'),
    );

    return result;
  }
}
```

---

## Composição de Commands

```dart
// Command que usa outros Commands
class SyncVehiclesCommand {
  final LoadVehiclesCommand _loadCommand;
  final CreateOrUpdateVehicleCommand _saveCommand;
  final IFirebaseService _firebase;

  SyncVehiclesCommand(this._loadCommand, this._saveCommand, this._firebase);

  Future<Either<Failure, Unit>> execute({required String userId}) async {
    // 1. Buscar veículos remotos
    final remoteVehicles = await _firebase.getVehicles(userId);

    // 2. Salvar localmente
    for (final vehicle in remoteVehicles) {
      final result = await _saveCommand.execute(
        id: vehicle.id,
        userId: vehicle.userId,
        name: vehicle.name,
        plate: vehicle.plate,
      );

      if (result.isLeft()) {
        return result.fold((f) => Left(f), (_) => Right(unit));
      }
    }

    return Right(unit);
  }
}
```

---

## Testes de Commands

### Estrutura de Teste

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockVehicleRepository extends Mock implements IVehicleRepository {}

void main() {
  late CreateOrUpdateVehicleCommand command;
  late MockVehicleRepository mockRepository;

  setUp(() {
    mockRepository = MockVehicleRepository();
    command = CreateOrUpdateVehicleCommand(mockRepository);
  });

  group('CreateOrUpdateVehicleCommand', () {
    test('deve_retornar_Right_quando_dados_validos', () async {
      // ARRANGE
      final vehicle = VehicleFactory.create(name: 'Civic', plate: 'ABC1234');
      when(() => mockRepository.save(any())).thenAnswer((_) async => Right(vehicle));

      // ACT
      final result = await command.execute(
        userId: 'user-id',
        name: 'Civic',
        plate: 'ABC1234',
      );

      // ASSERT
      expect(result.isRight(), true);
      verify(() => mockRepository.save(any())).called(1);
    });

    test('deve_retornar_Left_ValidationFailure_quando_nome_vazio', () async {
      // ACT
      final result = await command.execute(
        userId: 'user-id',
        name: '',
        plate: 'ABC1234',
      );

      // ASSERT
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should be Left'),
      );
      verifyNever(() => mockRepository.save(any()));
    });
  });
}
```

---

## Checklist de Qualidade

- [ ] Command retorna `Either<Failure, Result>`?
- [ ] Validações no início (fail fast)?
- [ ] Sem lógica de UI (sem BuildContext)?
- [ ] Sem lógica de persistência (delega para Repository)?
- [ ] Testável com mocks?
- [ ] Nome descritivo (verbo + substantivo)?
- [ ] Analytics logado após sucesso (se aplicável)?

---

**Referências:**
- `docs/domain-*.md` → Documentação de domínios com Commands
- `test/application/commands/` → Exemplos de testes de Commands
