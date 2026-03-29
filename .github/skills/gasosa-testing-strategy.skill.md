# Skill — Gasosa Testing Strategy

**Estratégia de testes do Gasosa App**

---

## Visão Geral

Esta skill documenta a estratégia completa de testes do Gasosa App, garantindo:
- **Cobertura adequada** por camada (100% em domain, 80%+ em data, 50%+ em UI)
- **Testes rápidos** (unit < 5s, integration < 30s)
- **Mocks simples** (evite over-mocking)
- **Confiabilidade** (sem flakiness)

---

## Pirâmide de Testes

```
           /\
          /  \  E2E / Integration (poucos)
         /____\
        /      \
       / Widget \ (moderado)
      /  Tests  \
     /___________\
    /             \
   /  Unit Tests   \ (muitos)
  /_________________\
```

**Regra 70-20-10:**
- 70% Unit Tests (Commands, Mappers, Validators)
- 20% Widget Tests (UI states)
- 10% Integration/E2E (fluxos críticos)

---

## Cobertura por Camada

| Camada | Cobertura Esperada | Status |
|--------|-------------------|--------|
| **Validators** | 100% | ✅ 124/124 testes |
| **Mappers** | 100% | ✅ 35/35 testes |
| **Auth Commands** | 100% | ✅ 55/55 testes |
| **Vehicle Commands** | 100% | ✅ 57/57 testes |
| **Refuel Commands** | 100% | ✅ 17/17 testes |
| **Repositories** | 80%+ | ⏳ Pendente |
| **UI/Widgets** | 50%+ | ⏳ Pendente |

---

## Estrutura de Pastas

```
test/
├─ core/
│  ├─ validators/
│  ├─ helpers/
│  └─ extensions/
├─ data/
│  ├─ mappers/
│  └─ repositories/
├─ application/
│  └─ commands/
│     ├─ auth/
│     ├─ vehicles/
│     └─ refuel/
├─ presentation/
│  └─ widgets/
└─ helpers/
   ├─ mock_repositories.dart
   ├─ mock_services.dart
   └─ factories/
      ├─ vehicle_factory.dart
      └─ refuel_factory.dart
```

---

## 1. Unit Tests (Commands)

### Template Padrão (Arrange-Act-Assert)

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
      final result = await command.execute(name: 'Civic', plate: 'ABC1234');

      // ASSERT
      expect(result.isRight(), true);
      verify(() => mockRepository.save(any())).called(1);
    });

    test('deve_retornar_Left_ValidationFailure_quando_nome_vazio', () async {
      // ACT
      final result = await command.execute(name: '', plate: 'ABC1234');

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

### Cenários Obrigatórios para Commands

Todo Command deve ter testes para:
- [ ] **Happy path** (dados válidos, sucesso)
- [ ] **Validação falhando** (entrada inválida por campo)
- [ ] **Repository falhando** (DatabaseFailure, NetworkFailure, etc.)
- [ ] **Entidade não encontrada** (NotFoundFailure)

---

## 2. Widget Tests

### Template Padrão

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

### Testes de Estados (Loading/Error/Empty)

```dart
testWidgets('deve_exibir_loading_quando_state_loading', (tester) async {
  final viewModel = MockRefuelViewModel();
  when(() => viewModel.state).thenReturn(UiState.loading());

  await tester.pumpWidget(
    MaterialApp(
      home: Provider.value(
        value: viewModel,
        child: RefuelListScreen(),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('deve_exibir_erro_quando_state_error', (tester) async {
  final viewModel = MockRefuelViewModel();
  when(() => viewModel.state).thenReturn(UiState.error('Erro ao carregar'));

  await tester.pumpWidget(
    MaterialApp(
      home: Provider.value(
        value: viewModel,
        child: RefuelListScreen(),
      ),
    ),
  );

  expect(find.text('Erro ao carregar'), findsOneWidget);
});
```

---

## 3. Testes de Mappers

```dart
test('deve_converter_VehicleEntity_para_VehiclesCompanion', () {
  // ARRANGE
  final entity = VehicleEntity(
    id: 'test-id',
    userId: 'user-id',
    name: 'Civic',
    plate: 'ABC1234',
  );

  // ACT
  final companion = VehicleMapper.toCompanion(entity);

  // ASSERT
  expect(companion.id.value, 'test-id');
  expect(companion.name.value, 'Civic');
  expect(companion.plate.value, 'ABC1234');
});

test('deve_converter_Vehicle_Drift_para_VehicleEntity', () {
  // ARRANGE
  final vehicleDb = Vehicle(
    id: 'test-id',
    userId: 'user-id',
    name: 'Civic',
    plate: 'ABC1234',
    createdAt: DateTime.now(),
  );

  // ACT
  final entity = VehicleMapper.toEntity(vehicleDb);

  // ASSERT
  expect(entity.id, 'test-id');
  expect(entity.name, 'Civic');
});
```

---

## 4. Testes de Repositories

```dart
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
  when(() => mockDao.insertOrUpdate(any())).thenThrow(Exception('Erro SQLite'));

  // ACT
  final result = await repository.save(entity);

  // ASSERT
  expect(result.isLeft(), true);
  result.fold(
    (failure) => expect(failure, isA<DatabaseFailure>()),
    (_) => fail('Should be Left'),
  );
});
```

---

## 5. Factories (Test Helpers)

### VehicleFactory

```dart
class VehicleFactory {
  static VehicleEntity create({
    String? id,
    String? userId,
    String? name,
    String? plate,
  }) {
    return VehicleEntity(
      id: id ?? 'test-vehicle-id',
      userId: userId ?? 'test-user-id',
      name: name ?? 'Test Vehicle',
      plate: plate ?? 'ABC1234',
    );
  }

  static List<VehicleEntity> createList(int count) {
    return List.generate(count, (i) => create(id: 'vehicle-$i'));
  }
}
```

### RefuelFactory

```dart
class RefuelFactory {
  static RefuelEntity create({
    String? id,
    String? vehicleId,
    double? liters,
    double? totalValue,
  }) {
    final validLiters = liters ?? 50.0;
    final validTotalValue = totalValue ?? 300.0;

    return RefuelEntity(
      id: id ?? 'test-refuel-id',
      vehicleId: vehicleId ?? 'test-vehicle-id',
      date: DateTime.now(),
      liters: validLiters,
      totalValue: validTotalValue,
      odometer: 10000.0,
      fullTank: true,
      pricePerLiter: validTotalValue / validLiters,
    );
  }
}
```

---

## 6. Mocks Reutilizáveis

```dart
// test/helpers/mock_repositories.dart
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements IVehicleRepository {}
class MockRefuelRepository extends Mock implements IRefuelRepository {}
class MockAuthRepository extends Mock implements IAuthRepository {}

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockVehicleDao extends Mock implements VehicleDao {}
class MockRefuelDao extends Mock implements RefuelDao {}
```

---

## Regras de Ouro

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
test('deve_validar_dados_e_salvar_veiculo', () {});
```

### 3. Isolamento

```dart
// ✅ BOM: setUp cria novos mocks
setUp(() {
  mockRepository = MockVehicleRepository();
});

// ❌ RUIM: Mock compartilhado entre testes
final mockRepository = MockVehicleRepository(); // Global!
```

### 4. Arrange-Act-Assert

```dart
test('exemplo', () {
  // ARRANGE (preparar dados)
  final vehicle = VehicleFactory.create();

  // ACT (executar ação)
  final result = command.execute(...);

  // ASSERT (verificar resultado)
  expect(result.isRight(), true);
});
```

---

## Comandos Úteis

```bash
# Rodar todos os testes
flutter test

# Com cobertura
flutter test --coverage

# Arquivo específico
flutter test test/application/commands/vehicles/create_vehicle_command_test.dart

# Por grupo
flutter test --name "CreateOrUpdateVehicleCommand"

# Gerar relatório de cobertura (HTML)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Checklist de Qualidade

- [ ] Testes seguem padrão Arrange-Act-Assert?
- [ ] Nomenclatura é descritiva (snake_case)?
- [ ] Um conceito por teste?
- [ ] Mocks são criados no setUp() (isolamento)?
- [ ] Factories são usadas para dados de teste?
- [ ] Cobertura está adequada para a camada?
- [ ] Testes executam rápido (<5s para unit)?
- [ ] Sem testes flaky (passam/falham aleatoriamente)?

---

**Referências:**
- `docs/testing-strategy.md` → Estratégia completa
- `test/helpers/` → Mocks e Factories reutilizáveis
