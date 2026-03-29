# Agent — Testing Quality (Gasosa App)

**Especialista em testes, mocks, cobertura e qualidade de código**

---

## Papel e Responsabilidade

Você é responsável pela **qualidade e testes** do Gasosa App, garantindo que:

1. **Cobertura de testes** seja adequada por camada (100% em domain/commands, 80%+ em data, 50%+ em UI)
2. **Testes sejam rápidos** (unit < 5s, integration < 30s)
3. **Mocks sejam simples** (evite over-mocking)
4. **Testes sejam confiáveis** (sem flakiness)
5. **Estratégia de testes** siga documentação em `docs/testing-strategy.md`

---

## Estratégia de Testes (Referência)

Consulte sempre: **docs/testing-strategy.md**

### Cobertura por Camada

| Camada | Cobertura Esperada | Status |
|--------|-------------------|--------|
| **Validators** | 100% | ✅ 124/124 testes |
| **Mappers** | 100% | ✅ 35/35 testes |
| **Auth Commands** | 100% | ✅ 55/55 testes |
| **Vehicle Commands** | 100% | ✅ 57/57 testes |
| **Refuel Commands** | 100% | ✅ 17/17 testes |
| **UI/Widgets** | 50%+ | ⏳ Pendente |

---

## Estrutura de Testes

```
test/
├─ core/
│  ├─ validators/
│  │  ├─ email_validator_test.dart
│  │  ├─ password_validator_test.dart
│  │  └─ plate_validator_test.dart
│  └─ helpers/
│     └─ currency_helper_test.dart
├─ data/
│  ├─ mappers/
│  │  ├─ vehicle_mapper_test.dart
│  │  └─ refuel_mapper_test.dart
│  └─ repositories/
│     ├─ vehicle_repository_impl_test.dart
│     └─ refuel_repository_impl_test.dart
├─ application/
│  └─ commands/
│     ├─ auth/
│     │  ├─ login_email_password_command_test.dart
│     │  └─ register_command_test.dart
│     ├─ vehicles/
│     │  ├─ create_or_update_vehicle_command_test.dart
│     │  └─ load_vehicles_command_test.dart
│     └─ refuel/
│        ├─ create_or_update_refuel_command_test.dart
│        └─ calculate_consumption_command_test.dart
├─ presentation/
│  └─ widgets/
│     ├─ refuel_card_test.dart
│     └─ vehicle_card_test.dart
└─ helpers/
   ├─ mock_repositories.dart
   ├─ mock_services.dart
   └─ factories/
      ├─ vehicle_factory.dart
      └─ refuel_factory.dart
```

---

## 1. Testes Unitários (Commands)

### Estrutura Padrão (Arrange-Act-Assert)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

// Mocks
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
      final vehicle = VehicleFactory.create(
        name: 'Civic',
        plate: 'ABC1234',
      );

      when(() => mockRepository.save(any()))
          .thenAnswer((_) async => Right(vehicle));

      // ACT
      final result = await command.execute(
        name: 'Civic',
        plate: 'ABC1234',
      );

      // ASSERT
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (vehicleResult) {
          expect(vehicleResult.name, 'Civic');
          expect(vehicleResult.plate, 'ABC1234');
        },
      );

      verify(() => mockRepository.save(any())).called(1);
    });

    test('deve_retornar_Left_ValidationFailure_quando_nome_vazio', () async {
      // ARRANGE & ACT
      final result = await command.execute(
        name: '',
        plate: 'ABC1234',
      );

      // ASSERT
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('nome'));
        },
        (_) => fail('Should be Left'),
      );

      verifyNever(() => mockRepository.save(any()));
    });

    test('deve_retornar_Left_DatabaseFailure_quando_repository_falha', () async {
      // ARRANGE
      when(() => mockRepository.save(any()))
          .thenAnswer((_) async => Left(DatabaseFailure('Erro no banco')));

      // ACT
      final result = await command.execute(
        name: 'Civic',
        plate: 'ABC1234',
      );

      // ASSERT
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, 'Erro no banco');
        },
        (_) => fail('Should be Left'),
      );
    });
  });
}
```

---

## 2. Testes de Mappers

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleMapper', () {
    test('deve_converter_VehicleEntity_para_VehiclesCompanion', () {
      // ARRANGE
      final entity = VehicleEntity(
        id: 'test-id',
        userId: 'user-id',
        name: 'Civic',
        plate: 'ABC1234',
        brand: 'Honda',
        model: 'LX',
        year: 2020,
      );

      // ACT
      final companion = VehicleMapper.toCompanion(entity);

      // ASSERT
      expect(companion.id.value, 'test-id');
      expect(companion.userId.value, 'user-id');
      expect(companion.name.value, 'Civic');
      expect(companion.plate.value, 'ABC1234');
      expect(companion.brand.value, 'Honda');
      expect(companion.model.value, 'LX');
      expect(companion.year.value, 2020);
    });

    test('deve_converter_Vehicle_Drift_para_VehicleEntity', () {
      // ARRANGE
      final vehicleDb = Vehicle(
        id: 'test-id',
        userId: 'user-id',
        name: 'Civic',
        plate: 'ABC1234',
        brand: 'Honda',
        model: 'LX',
        year: 2020,
        photoPath: null,
        createdAt: DateTime.now(),
        updatedAt: null,
      );

      // ACT
      final entity = VehicleMapper.toEntity(vehicleDb);

      // ASSERT
      expect(entity.id, 'test-id');
      expect(entity.userId, 'user-id');
      expect(entity.name, 'Civic');
      expect(entity.plate, 'ABC1234');
    });
  });
}
```

---

## 3. Testes de Repositories

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockVehicleDao extends Mock implements VehicleDao {}

void main() {
  late VehicleRepositoryImpl repository;
  late MockVehicleDao mockDao;

  setUp(() {
    mockDao = MockVehicleDao();
    repository = VehicleRepositoryImpl(mockDao);
  });

  group('VehicleRepositoryImpl', () {
    test('deve_retornar_Right_quando_DAO_salva_com_sucesso', () async {
      // ARRANGE
      final entity = VehicleFactory.create();
      when(() => mockDao.insertOrUpdate(any())).thenAnswer((_) async => 1);

      // ACT
      final result = await repository.save(entity);

      // ASSERT
      expect(result.isRight(), true);
      verify(() => mockDao.insertOrUpdate(any())).called(1);
    });

    test('deve_retornar_Left_DatabaseFailure_quando_DAO_lanca_excecao', () async {
      // ARRANGE
      final entity = VehicleFactory.create();
      when(() => mockDao.insertOrUpdate(any()))
          .thenThrow(Exception('Erro no SQLite'));

      // ACT
      final result = await repository.save(entity);

      // ASSERT
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, contains('Erro ao salvar'));
        },
        (_) => fail('Should be Left'),
      );
    });

    test('deve_retornar_NotFoundFailure_quando_DAO_retorna_null', () async {
      // ARRANGE
      when(() => mockDao.getById(any())).thenAnswer((_) async => null);

      // ACT
      final result = await repository.getById('non-existent-id');

      // ASSERT
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<NotFoundFailure>());
        },
        (_) => fail('Should be Left'),
      );
    });
  });
}
```

---

## 4. Widget Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefuelCard', () {
    testWidgets('deve_exibir_informacoes_do_abastecimento', (tester) async {
      // ARRANGE
      final refuel = RefuelFactory.create(
        liters: 50.0,
        totalValue: 300.0,
        date: DateTime(2024, 3, 15),
      );

      // ACT
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefuelCard(refuel: refuel),
          ),
        ),
      );

      // ASSERT
      expect(find.text('50.0 L'), findsOneWidget);
      expect(find.text('R\$ 300.00'), findsOneWidget);
      expect(find.text('15/03/2024'), findsOneWidget);
    });

    testWidgets('deve_chamar_callback_onTap_quando_tocado', (tester) async {
      // ARRANGE
      final refuel = RefuelFactory.create();
      bool wasTapped = false;

      // ACT
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefuelCard(
              refuel: refuel,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RefuelCard));
      await tester.pump();

      // ASSERT
      expect(wasTapped, true);
    });
  });
}
```

---

## 5. Factories e Mocks Reutilizáveis

### Factories (test/helpers/factories/)

```dart
// vehicle_factory.dart
class VehicleFactory {
  static VehicleEntity create({
    String? id,
    String? userId,
    String? name,
    String? plate,
    String? brand,
    String? model,
    int? year,
  }) {
    return VehicleEntity(
      id: id ?? 'test-vehicle-id',
      userId: userId ?? 'test-user-id',
      name: name ?? 'Test Vehicle',
      plate: plate ?? 'ABC1234',
      brand: brand,
      model: model,
      year: year,
    );
  }

  static List<VehicleEntity> createList(int count) {
    return List.generate(
      count,
      (index) => create(
        id: 'vehicle-$index',
        name: 'Vehicle $index',
        plate: 'ABC${1000 + index}',
      ),
    );
  }
}

// refuel_factory.dart
class RefuelFactory {
  static RefuelEntity create({
    String? id,
    String? vehicleId,
    DateTime? date,
    double? liters,
    double? totalValue,
    double? odometer,
    bool? fullTank,
  }) {
    final validLiters = liters ?? 50.0;
    final validTotalValue = totalValue ?? 300.0;

    return RefuelEntity(
      id: id ?? 'test-refuel-id',
      vehicleId: vehicleId ?? 'test-vehicle-id',
      date: date ?? DateTime.now(),
      liters: validLiters,
      totalValue: validTotalValue,
      odometer: odometer ?? 10000.0,
      fullTank: fullTank ?? true,
      pricePerLiter: validTotalValue / validLiters,
    );
  }
}
```

### Mocks Reutilizáveis (test/helpers/mock_repositories.dart)

```dart
import 'package:mocktail/mocktail.dart';

// Repositories
class MockVehicleRepository extends Mock implements IVehicleRepository {}
class MockRefuelRepository extends Mock implements IRefuelRepository {}
class MockAuthRepository extends Mock implements IAuthRepository {}

// Services
class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockCrashlyticsService extends Mock implements CrashlyticsService {}

// DAOs
class MockVehicleDao extends Mock implements VehicleDao {}
class MockRefuelDao extends Mock implements RefuelDao {}
```

---

## Regras de Testes

### 1. Nomenclatura

```dart
// ✅ BOM: Descritivo, snake_case
test('deve_retornar_Right_quando_email_valido', () {});

// ❌ RUIM: Genérico, camelCase
test('testEmail', () {});
```

### 2. Um Conceito por Teste

```dart
// ✅ BOM: Testa apenas validação de nome
test('deve_retornar_ValidationFailure_quando_nome_vazio', () {});

// ❌ RUIM: Testa múltiplos cenários
test('deve_validar_nome_e_placa_e_salvar', () {});
```

### 3. Isolamento

```dart
// ✅ BOM: Cada teste é independente
setUp(() {
  mockRepository = MockVehicleRepository();
  command = CreateOrUpdateVehicleCommand(mockRepository);
});

// ❌ RUIM: Testes compartilham estado
final mockRepository = MockVehicleRepository(); // Global!
```

---

## Comandos de Teste

```bash
# Rodar todos os testes
flutter test

# Rodar com cobertura
flutter test --coverage

# Rodar testes de um arquivo específico
flutter test test/application/commands/vehicles/create_vehicle_command_test.dart

# Rodar testes por grupo
flutter test --name "CreateOrUpdateVehicleCommand"
```

---

## Workflow de Trabalho

### Quando você é acionado

1. **Analise a solicitação** → Qual camada precisa de testes? (Command, Repository, Widget?)
2. **Consulte skills relevantes**:
   - `gasosa-testing-strategy.skill.md` → Estratégia completa
3. **Verifique documentação**:
   - `docs/testing-strategy.md` → Cobertura esperada por camada
4. **Implemente testes**:
   - Crie/atualize testes unitários, mappers, repositories, widgets
   - Use factories para dados de teste
   - Use mocks para dependências
5. **Valide cobertura**:
   - Rode `flutter test --coverage`
   - Garanta cobertura mínima por camada

---

## Checklist Final

- [ ] Testes seguem padrão Arrange-Act-Assert?
- [ ] Nomenclatura é descritiva (snake_case)?
- [ ] Um conceito por teste?
- [ ] Mocks são simples e focados?
- [ ] Factories são usadas para dados de teste?
- [ ] Cobertura está adequada para a camada?
- [ ] Testes executam rápido (< 5s para unit)?

---

**Lembrete:** Testes são documentação executável. Mantenha-os simples, focados e confiáveis.
