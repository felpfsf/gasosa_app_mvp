# Test Helpers

Infraestrutura reutilizável para testes do Gasosa App.

## 📁 Estrutura

```
test/helpers/
├── mock_repositories.dart    # Mocks de repositories
├── mock_services.dart         # Mocks de services  
├── test_helpers.dart          # Matchers customizados e utilitários
└── factories/
    ├── user_factory.dart      # Cria UserEntity fake
    ├── vehicle_factory.dart   # Cria VehicleEntity fake
    └── refuel_factory.dart    # Cria RefuelEntity fake
```

## 🔧 Mocks

### Repositories

```dart
import 'package:test/helpers/mock_repositories.dart';

final mockVehicleRepo = MockVehicleRepository();
final mockRefuelRepo = MockRefuelRepository();
final mockUserRepo = MockUserRepository();
```

### Services

```dart
import 'package:test/helpers/mock_services.dart';

final mockAuthService = MockAuthService();
```

## 🏭 Factories

### UserFactory

```dart
import 'package:test/helpers/factories/user_factory.dart';

// Usuário com valores fake
final user = UserFactory.create();

// Usuário sem foto
final userNoPhoto = UserFactory.createWithoutPhoto();

// Usuário válido para testes específicos
final validUser = UserFactory.createValid(
  id: 'user-123',
  name: 'João Silva',
  email: 'joao@example.com',
);

// Lista de usuários
final users = UserFactory.createList(5);
```

### VehicleFactory

```dart
import 'package:test/helpers/factories/vehicle_factory.dart';

// Veículo com valores fake
final vehicle = VehicleFactory.create();

// Veículo completo (todos os campos opcionais preenchidos)
final fullVehicle = VehicleFactory.createFull();

// Veículo mínimo (sem plate, tankCapacity, photoPath)
final minimalVehicle = VehicleFactory.createMinimal();

// Veículo válido para testes específicos
final validVehicle = VehicleFactory.createValid(
  id: 'vehicle-123',
  name: 'Honda Civic',
  plate: 'ABC1234',
);

// Veículo novo (id vazio para criação)
final newVehicle = VehicleFactory.createNew(
  userId: 'user-123',
  name: 'Fiat Uno',
);

// Lista de veículos do mesmo usuário
final vehicles = VehicleFactory.createList(5, userId: 'user-123');
```

### RefuelFactory

```dart
import 'package:test/helpers/factories/refuel_factory.dart';

// Abastecimento com valores fake
final refuel = RefuelFactory.create();

// Abastecimento completo (com cold start e recibo)
final fullRefuel = RefuelFactory.createFull();

// Abastecimento sem cold start
final refuelNoCold = RefuelFactory.createWithoutColdStart();

// Abastecimento válido para testes específicos
final validRefuel = RefuelFactory.createValid(
  id: 'refuel-123',
  mileage: 50000,
  liters: 45.5,
);

// Abastecimento novo (id vazio para criação)
final newRefuel = RefuelFactory.createNew(
  vehicleId: 'vehicle-123',
  mileage: 50000,
);

// Lista de abastecimentos ordenados por data
final refuels = RefuelFactory.createList(5, vehicleId: 'vehicle-123');

// Sequência para teste de consumo (ordenada cronologicamente)
final sequence = RefuelFactory.createSequenceForConsumption(
  vehicleId: 'vehicle-123',
  count: 5,
  startMileage: 50000,
  avgConsumption: 12.0, // km/l
);

// Par consecutivo para cálculo
final pair = RefuelFactory.createConsecutivePair(
  mileage1: 50000,
  mileage2: 50500,
  liters2: 40.0,
); // Consumo esperado: 500km / 40L = 12.5 km/l
```

## ✅ Matchers Customizados

### Matchers para Either

```dart
import 'package:test/helpers/test_helpers.dart';

test('deve retornar Right', () {
  final result = repository.getById('123');
  
  expect(result, isRight());
});

test('deve retornar Left', () {
  final result = repository.getById('invalid');
  
  expect(result, isLeft());
});

test('deve retornar Right com valor específico', () {
  final result = repository.getById('123');
  
  expect(result, isRightWith(expectedUser));
});

test('deve retornar Left com AuthFailure', () {
  final result = authService.login('email', 'pass');
  
  expect(result, isLeftWith<AuthFailure>());
});

test('deve retornar Left com mensagem específica', () {
  final result = repository.create(invalidEntity);
  
  expect(result, isLeftWithMessage('já existe'));
});
```

### Helpers de Extração

```dart
import 'package:test/helpers/test_helpers.dart';

test('extrair valor Right', () {
  final result = repository.getById('123');
  
  final user = rightValue(result);
  expect(user.id, '123');
});

test('extrair Failure de Left', () {
  final result = repository.getById('invalid');
  
  final failure = leftFailure(result);
  expect(failure, isA<NotFoundFailure>());
});
```

### Delay Assíncrono

```dart
import 'package:test/helpers/test_helpers.dart';

test('aguardar antes de verificar', () async {
  service.startAsyncOperation();
  
  await delay(); // 100ms default
  
  verify(() => repository.save(any())).called(1);
});

test('aguardar tempo customizado', () async {
  service.startAsyncOperation();
  
  await delay(Duration(milliseconds: 500));
  
  expect(service.isComplete, true);
});
```

## 📝 Exemplos de Uso

### Teste com Mock Repository

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:test/helpers/mock_repositories.dart';
import 'package:test/helpers/factories/vehicle_factory.dart';
import 'package:test/helpers/test_helpers.dart';

void main() {
  late MockVehicleRepository mockRepo;
  
  setUp(() {
    mockRepo = MockVehicleRepository();
  });
  
  test('deve criar veículo', () async {
    // Arrange
    final vehicle = VehicleFactory.createNew(userId: 'user-123');
    when(() => mockRepo.createVehicle(any()))
        .thenAnswer((_) async => right(unit));
    
    // Act
    final result = await mockRepo.createVehicle(vehicle);
    
    // Assert
    expect(result, isRight());
    verify(() => mockRepo.createVehicle(vehicle)).called(1);
  });
}
```

### Teste com Factory

```dart
test('calcular consumo médio', () {
  // Arrange - cria sequência de 3 abastecimentos com consumo de 12 km/l
  final refuels = RefuelFactory.createSequenceForConsumption(
    vehicleId: 'vehicle-123',
    count: 3,
    avgConsumption: 12.0,
  );
  
  // Act
  final consumption = calculateAverageConsumption(refuels);
  
  // Assert
  expect(consumption, closeTo(12.0, 0.5));
});
```

### Teste com Matchers Customizados

```dart
test('validar email', () {
  // Arrange
  final result = Validators.email('invalid-email');
  
  // Assert
  expect(result, isLeft());
  expect(result, isLeftWith<BusinessFailure>());
  expect(result, isLeftWithMessage('inválido'));
  
  final failure = leftFailure(result);
  expect(failure.message, contains('Email'));
});
```

## 🎯 Boas Práticas

1. **Use factories** para criar dados de teste consistentes
2. **Use matchers customizados** para tornar testes mais legíveis
3. **Reutilize mocks** através do `setUp()` e `tearDown()`
4. **Registre fallbacks** com `registerFallbackValue()` quando necessário
5. **Verifique chamadas** com `verify()` e `verifyNever()`

## 🔗 Referências

- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Faker Documentation](https://pub.dev/packages/faker)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
