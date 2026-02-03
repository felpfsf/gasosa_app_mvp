# Estratégia de Testes - Gasosa App MVP

## 📋 Visão Geral

Este documento define a estratégia completa de testes do Gasosa App, organizada por domínio e seguindo os princípios de Clean Architecture. O objetivo é garantir qualidade, testabilidade e evolução segura do produto.

---

## 🎯 Objetivos e Métricas

### Cobertura Mínima Esperada

| Camada | Cobertura | Status |
| -------- | ----------- | --------------- |
| **Validators** | 100% | ✅ **124/124 testes** (Fase 1) |
| **Mappers** | 100% | ✅ **35/35 testes** (Fase 2) - 96.67% cobertura |
| **Auth Commands** | 100% | ✅ **55/55 testes** (Fase 3) - 100% cobertura |
| **Vehicle Commands** | 100% | ✅ **57/57 testes** (Fase 4) - 100% cobertura |
| **Refuel Commands** | 80%+ | ⏳ Pendente (Fase 5) |
| **UI/Widgets** | 50%+ | ⏳ Pendente |

**Total até agora:** 271 testes passando (Fase 1: 124 + Fase 2: 35 + Fase 3: 55 + Fase 4: 57)

### Princípios de Teste

1. **Testes rápidos**: Unit tests devem executar em < 5s
2. **Isolamento**: Cada teste é independente, usa mocks
3. **Arrange-Act-Assert**: Estrutura clara em todos os testes
4. **Nomes descritivos**: `deve_retornar_Right_quando_email_valido`
5. **Um conceito por teste**: Evitar testes que validam múltiplos cenários

---

## 📁 Estrutura de Pastas

A estrutura de testes espelha `lib/`, facilitando navegação e manutenção:

```bash
test/
├─ core/                          # Domínio Core (infraestrutura compartilhada)
│  ├─ validators/
│  │  ├─ email_validator_test.dart
│  │  ├─ password_validator_test.dart
│  │  └─ plate_validator_test.dart
│  ├─ extensions/
│  │  ├─ string_extension_test.dart
│  │  └─ datetime_extension_test.dart
│  └─ helpers/
│     ├─ currency_helper_test.dart
│     └─ date_helper_test.dart
│
├─ domain/                        # Entidades (se houver lógica)
│  └─ entities/
│     ├─ vehicle_entity_test.dart
│     └─ refuel_entity_test.dart
│
├─ data/                          # Mappers e Repositories
│  ├─ mappers/
│  │  ├─ vehicle_mapper_test.dart
│  │  ├─ refuel_mapper_test.dart
│  │  └─ user_mapper_test.dart
│  └─ repositories/
│     ├─ auth_repository_impl_test.dart
│     ├─ vehicle_repository_impl_test.dart
│     ├─ refuel_repository_impl_test.dart
│     └─ user_repository_impl_test.dart
│
├─ application/                   # Commands (casos de uso)
│  └─ commands/
│     ├─ auth/
│     │  ├─ login_email_password_command_test.dart
│     │  ├─ login_with_google_command_test.dart
│     │  └─ register_command_test.dart
│     ├─ vehicles/
│     │  ├─ create_or_update_vehicle_command_test.dart
│     │  ├─ delete_vehicle_command_test.dart
│     │  └─ load_vehicles_command_test.dart
│     └─ refuel/
│        ├─ create_or_update_refuel_command_test.dart
│        ├─ delete_refuel_command_test.dart
│        ├─ load_refuels_by_vehicle_command_test.dart
│        └─ calculate_consumption_command_test.dart
│
└─ helpers/                       # Mocks e Factories reutilizáveis
   ├─ mock_repositories.dart      # Todos os mock repositories
   ├─ mock_services.dart          # Mock de serviços (Auth, Storage)
   ├─ factories/
   │  ├─ vehicle_factory.dart     # Cria VehicleEntity fake para testes
   │  ├─ refuel_factory.dart      # Cria RefuelEntity fake
   │  └─ user_factory.dart        # Cria UserEntity fake
   └─ test_helpers.dart           # Helpers gerais (matchers customizados)
```

---

## 🔄 Ordem de Implementação

### Fase 1: Fundação (Core)

**Prioridade:** 🔴 ALTA  
**Duração estimada:** 2-3 dias  
**Por quê primeiro?** Core é usado por todos os domínios. Validators, extensions e helpers são dependências críticas.

#### Checklist

- [ ] `email_validator_test.dart`
- [ ] `password_validator_test.dart`
- [ ] `plate_validator_test.dart`
- [ ] `string_extension_test.dart`
- [ ] `datetime_extension_test.dart`
- [ ] `currency_helper_test.dart`
- [ ] `date_helper_test.dart`

**Cobertura esperada:** 100%

---

### Fase 2: Mappers (Data Layer)

**Prioridade:** 🟠 MÉDIA-ALTA  
**Duração estimada:** 1-2 dias  
**Por quê agora?** Conversões puras, sem I/O, 100% testáveis.

**Status:** ✅ **COMPLETA** (35 testes passando, 96.67% cobertura)

#### Checklist

- [x] `user_mapper_test.dart` (15 testes)
- [x] `vehicle_mapper_test.dart` (11 testes)
- [x] `refuel_mapper_test.dart` (9 testes)

**Casos testados:**

- ✅ Conversão `toDomain()` (Row → Entity)
- ✅ Conversão `toCompanion()` (Entity → Companion)
- ✅ Conversão `toData()` (Entity → Row) - UserMapper
- ✅ Valores nulos e defaults
- ✅ Mapeamento de enums (FuelType: gasoline, ethanol, diesel, gnv, flex)
- ✅ Case-insensitive em enums
- ✅ Conversão bidirecional (round-trip)
- ✅ Edge cases (valores extremos, strings vazias, caracteres especiais)

**Cobertura alcançada:** 96.67% (linha 20 de VehicleMapper não executável - null check desnecessário)

---

### Fase 3: Auth (Fluxo Crítico)

**Prioridade:** 🔴 ALTA  
**Duração estimada:** 2-3 dias  
**Por quê agora?** Autenticação é ponto de entrada obrigatório no app.

**Status:** ✅ **COMPLETA** (55 testes passando, 100% cobertura)

#### Commands testados

##### `login_email_password_command_test.dart` (24 testes)

- ✅ Login com sucesso (retorna Right com AuthUser)
- ✅ Login com sucesso incluindo photoUrl
- ✅ Credenciais inválidas (retorna Left com AuthFailure)
- ✅ Email não verificado (retorna Left com AuthFailure)
- ✅ Conta desabilitada (retorna Left com AuthFailure)
- ✅ Usuário não existe (retorna Left com AuthFailure)
- ✅ Email vazio (retorna Left com BusinessFailure)
- ✅ Password vazio (retorna Left com BusinessFailure)
- ✅ Email inválido (retorna Left com BusinessFailure)
- ✅ Erro de rede (retorna Left com AuthFailure)
- ✅ Timeout (retorna Left com AuthFailure)
- ✅ Erro inesperado (retorna Left com AuthFailure)
- ✅ Edge cases (email/senha com espaços, caracteres especiais, maiúsculas)
- ✅ Isolamento (verifica chamadas únicas ao AuthService)

##### `login_with_google_command_test.dart` (17 testes)

- ✅ Login Google com sucesso (com e sem photoUrl)
- ✅ Nomes compostos
- ✅ Usuário cancela fluxo (retorna Left com AuthFailure)
- ✅ Erro de rede (retorna Left com AuthFailure)
- ✅ Timeout (retorna Left com AuthFailure)
- ✅ Conta Google não autorizada (retorna Left com AuthFailure)
- ✅ Conta desabilitada (retorna Left com AuthFailure)
- ✅ Permissões negadas (retorna Left com AuthFailure)
- ✅ Erro inesperado (retorna Left com AuthFailure)
- ✅ Servidores Google indisponíveis (retorna Left com AuthFailure)
- ✅ Google Play Services desatualizado (Android)
- ✅ App não configurado no Firebase
- ✅ Isolamento e múltiplas chamadas

##### `register_command_test.dart` (14 testes)

- ✅ Registro com sucesso
- ✅ Nomes compostos e caracteres especiais
- ✅ Senha forte e email com subdomínio
- ✅ Email já cadastrado (retorna Left com AuthFailure)
- ✅ Senha fraca (retorna Left com BusinessFailure)
- ✅ Email inválido (retorna Left com BusinessFailure)
- ✅ Nome/email/senha vazios (retorna Left com BusinessFailure)
- ✅ Senha menor que 6 caracteres (retorna Left com BusinessFailure)
- ✅ Nome muito curto (retorna Left com BusinessFailure)
- ✅ Domínio bloqueado (retorna Left com AuthFailure)
- ✅ Muitas tentativas (retorna Left com AuthFailure)
- ✅ Erro de rede, timeout, erro inesperado (AuthFailure)
- ✅ Edge cases (espaços em branco, caracteres especiais)
- ✅ Múltiplos registros sequenciais

**Cobertura alcançada:** 100% nos 3 comandos

---

### Fase 4: Vehicle (CRUD Completo) ✅ CONCLUÍDA

**Prioridade:** 🟠 MÉDIA-ALTA  
**Duração estimada:** 2-3 dias → **Concluída em 2 dias**  
**Por quê agora?** Base para relacionamento com Refuels.

#### Commands testados ✅

##### `create_or_update_vehicle_command_test.dart` ✅

- ✅ Criar veículo novo (id vazio → chama repository.create())
- ✅ Atualizar veículo existente (id preenchido → chama repository.update())
- ✅ Retornar Right(unit) em caso de sucesso
- ✅ Retornar Left(DatabaseFailure) em caso de erro
- ✅ Criar com dados mínimos obrigatórios
- ✅ Criar com todos campos opcionais preenchidos
- ✅ Atualizar mudando placa
- ✅ Atualizar removendo foto (photoPath vazio)
- ✅ Preservar timestamps
- ✅ Edge cases: tankCapacity = 0, múltiplos veículos

**10 testes passando**

##### `delete_vehicle_command_test.dart` ✅

- ✅ Deletar veículo com sucesso
- ✅ Retornar Right(unit) quando deletar
- ✅ Deletar com ID UUID válido
- ✅ Retornar Left(DatabaseFailure) quando repository falhar
- ✅ Retornar Left(NotFoundFailure) quando veículo não existe
- ✅ Retornar Left(BusinessFailure) quando regra de negócio impedir
- ✅ Aceitar ID vazio (validação no repository)
- ✅ Passar ID exatamente como recebido
- ✅ Aguardar conclusão antes de retornar
- ✅ Deletar múltiplos veículos em paralelo
- ✅ Tratar ID muito longo
- ✅ Tratar caracteres especiais no ID

**12 testes passando**

##### `load_vehicles_command_test.dart` ✅

- ✅ Retornar Stream com lista de veículos
- ✅ Retornar Stream vazia quando usuário não tem veículos
- ✅ Emitir múltiplas atualizações quando dados mudam
- ✅ Manter stream aberto para múltiplas emissões
- ✅ Retornar Stream com Left(DatabaseFailure) quando falhar
- ✅ Propagar erros do Stream
- ✅ Retornar Left após erro e Right quando recuperar
- ✅ Passar userId correto para repository
- ✅ Aceitar userId vazio
- ✅ Permitir múltiplos listeners (broadcast)
- ✅ Cancelar stream quando listener é cancelado
- ✅ Emitir done quando stream termina
- ✅ Lidar com lista grande de veículos (100)
- ✅ Preservar ordem dos veículos retornados

**14 testes passando**

#### Repository testado ✅

##### `vehicle_repository_impl_test.dart` ✅

- ✅ Mock do `VehicleDao`
- ✅ `createVehicle()` chama DAO.upsert com VehiclesCompanion correto
- ✅ Retornar Right(unit) ao criar com sucesso
- ✅ Retornar Left(DatabaseFailure) quando dao lançar exceção
- ✅ Incluir causa do erro no DatabaseFailure
- ✅ `updateVehicle()` chama DAO.upsert
- ✅ Retornar Right(unit) ao atualizar com sucesso
- ✅ `deleteVehicle()` chama DAO.deleteById
- ✅ Retornar Right(unit) ao deletar com sucesso
- ✅ `getVehicleById()` retorna entity quando encontrado
- ✅ `getVehicleById()` retorna Right(null) quando não encontrado
- ✅ `getAllByUserId()` retorna lista de entities
- ✅ `getAllByUserId()` retorna Right([]) quando vazio
- ✅ Mapear corretamente todos os veículos
- ✅ `watchAllByUserId()` retorna Stream com Right(List)
- ✅ Stream emite múltiplas atualizações
- ✅ Stream vazio quando usuário não tem veículos
- ✅ Stream retorna Left(DatabaseFailure) em caso de erro
- ✅ Mapear corretamente VehicleRow → VehicleEntity no stream
- ✅ Preservar todos os campos ao mapear Entity → Companion
- ✅ Converter Entity → VehicleRow → Entity corretamente

**21 testes passando**

**Resultado Fase 4:** ✅ **57 testes passando** (10 + 12 + 14 + 21)  
**Cobertura:** Commands 100%, Repository 100%

---

### Fase 5: Refuel (Lógica de Negócio)
- ✅ `getVehiclesByUserId()` retorna Stream mapeado
- ✅ Mapear exceções Drift → Failures

**Cobertura esperada:** Commands 85%, Repository 70%

---

### Fase 5: Refuel (Lógica de Negócio)

**Prioridade:** 🟡 MÉDIA  
**Duração estimada:** 3-4 dias  
**Por quê agora?** Lógica de cálculo de consumo é crítica e complexa.

#### Commands a testar

##### `create_or_update_refuel_command_test.dart`

- ✅ Criar abastecimento válido
- ✅ Quilometragem maior que último abastecimento (sucesso)
- ✅ Quilometragem menor que último (retorna Left com ValidationFailure)
- ✅ Quilometragem igual ao último (retorna Left com ValidationFailure)
- ✅ Primeiro abastecimento do veículo (sem validação de km anterior)
- ✅ Salvar foto de recibo (mock LocalPhotoStorage)
- ✅ Litros negativo (retorna Left com ValidationFailure)
- ✅ Valor negativo (retorna Left com ValidationFailure)

##### `calculate_consumption_command_test.dart`

- ✅ Calcular consumo médio correto: (km atual - km anterior) / litros
- ✅ Dois abastecimentos completos: consumo = (50000 - 49500) / 40 = 12.5 km/L
- ✅ Abastecimento parcial (ignorar no cálculo)
- ✅ Apenas 1 abastecimento (retorna Right com consumo 0.0)
- ✅ Sem abastecimentos (retorna Right com consumo 0.0)
- ✅ Divisão por zero (litros = 0 → retorna consumo 0.0)

##### `delete_refuel_command_test.dart`

- ✅ Deletar abastecimento com sucesso
- ✅ Deletar + remover foto de recibo
- ✅ Refuel não encontrado (retorna Left com NotFoundFailure)

##### `load_refuels_by_vehicle_command_test.dart`

- ✅ Carregar histórico ordenado DESC por data
- ✅ Filtrar por vehicleId
- ✅ Retornar lista vazia se sem abastecimentos
- ✅ Mapear corretamente TableData → Entity

#### Repository a testar

##### `refuel_repository_impl_test.dart`

- ✅ Mock do `RefuelDao`
- ✅ `createRefuel()` chama DAO.insert
- ✅ `updateRefuel()` chama DAO.update
- ✅ `deleteRefuel()` chama DAO.delete
- ✅ `getRefuelsByVehicleId()` retorna Stream ordenado
- ✅ Mapear exceções Drift → Failures

**Cobertura esperada:** Commands 85% (foco em cálculo), Repository 70%

---

## 🧰 Dependências Necessárias

Adicionar ao `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0           # Mocks sem code generation
  faker: ^2.1.0              # Dados fake para factories
  integration_test:          # (Fase 6 - opcional)
    sdk: flutter
```

---

## 📝 Templates e Exemplos

### Template: Validator Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/validators/validators.dart';
import 'package:gasosa_app/core/errors/failures.dart';

void main() {
  group('EmailValidator', () {
    test('deve retornar Right quando email válido', () {
      // Arrange
      const email = 'test@example.com';

      // Act
      final result = Validators.email(email);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Não deveria retornar Left'),
        (validEmail) => expect(validEmail, email),
      );
    });

    test('deve retornar ValidationFailure quando email inválido', () {
      // Arrange
      const invalidEmail = 'invalid-email';

      // Act
      final result = Validators.email(invalidEmail);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Deveria retornar Left'),
      );
    });

    test('deve retornar ValidationFailure quando email nulo', () {
      final result = Validators.email(null);
      expect(result.isLeft(), true);
    });

    test('deve retornar ValidationFailure quando email vazio', () {
      final result = Validators.email('');
      expect(result.isLeft(), true);
    });
  });
}
```

---

### Template: Mapper Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/data/mappers/vehicle_mapper.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';

void main() {
  group('VehicleMapper', () {
    test('deve converter TableData para Entity corretamente', () {
      // Arrange
      final tableData = VehicleTableData(
        id: '1',
        userId: 'user-123',
        name: 'Honda Civic',
        plate: 'ABC-1234',
        tankCapacity: 50.0,
        fuelType: 'gasoline',
        photoPath: '/path/to/photo.jpg',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Act
      final entity = VehicleMapper.toDomain(tableData);

      // Assert
      expect(entity.id, '1');
      expect(entity.userId, 'user-123');
      expect(entity.name, 'Honda Civic');
      expect(entity.plate, 'ABC-1234');
      expect(entity.tankCapacity, 50.0);
      expect(entity.fuelType, FuelType.gasoline);
      expect(entity.photoPath, '/path/to/photo.jpg');
    });

    test('deve converter Entity para TableData corretamente', () {
      // Arrange
      final entity = VehicleEntity(
        id: '1',
        userId: 'user-123',
        name: 'Honda Civic',
        plate: 'ABC-1234',
        tankCapacity: 50.0,
        fuelType: FuelType.gasoline,
        photoPath: '/path/to/photo.jpg',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Act
      final tableData = VehicleMapper.toTableData(entity);

      // Assert
      expect(tableData.id, '1');
      expect(tableData.name, 'Honda Civic');
      expect(tableData.fuelType, 'gasoline');
    });

    test('deve mapear corretamente FuelType enum', () {
      final gasoline = VehicleMapper.toDomain(
        VehicleTableData(/* ... fuelType: 'gasoline' */),
      );
      expect(gasoline.fuelType, FuelType.gasoline);

      final ethanol = VehicleMapper.toDomain(
        VehicleTableData(/* ... fuelType: 'ethanol' */),
      );
      expect(ethanol.fuelType, FuelType.ethanol);
    });
  });
}
```

---

### Template: Command Test (com Mock)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:gasosa_app/application/commands/vehicles/create_or_update_vehicle_command.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/core/errors/failures.dart';

// Mock
class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late MockVehicleRepository mockRepository;
  late CreateOrUpdateVehicleCommand command;

  setUp(() {
    mockRepository = MockVehicleRepository();
    command = CreateOrUpdateVehicleCommand(repository: mockRepository);
  });

  group('CreateOrUpdateVehicleCommand', () {
    final vehicle = VehicleEntity(
      id: '',
      userId: 'user-123',
      name: 'Honda Civic',
      plate: 'ABC-1234',
      tankCapacity: 50.0,
      fuelType: FuelType.gasoline,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('deve criar veículo com sucesso', () async {
      // Arrange
      when(() => mockRepository.createVehicle(any()))
          .thenAnswer((_) async => right(unit));

      // Act
      final result = await command(vehicle);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createVehicle(any())).called(1);
    });

    test('deve retornar ValidationFailure quando nome vazio', () async {
      // Arrange
      final invalidVehicle = vehicle.copyWith(name: '');

      // Act
      final result = await command(invalidVehicle);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('nome'));
        },
        (_) => fail('Deveria retornar Left'),
      );
      verifyNever(() => mockRepository.createVehicle(any()));
    });

    test('deve retornar DatabaseFailure quando erro ao salvar', () async {
      // Arrange
      when(() => mockRepository.createVehicle(any()))
          .thenAnswer((_) async => left(DatabaseFailure('Erro ao salvar')));

      // Act
      final result = await command(vehicle);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Deveria retornar Left'),
      );
    });
  });
}
```

---

### Template: Factory (Test Helper)

```dart
import 'package:faker/faker.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';

class VehicleFactory {
  static final _faker = Faker();

  static VehicleEntity create({
    String? id,
    String? userId,
    String? name,
    String? plate,
    double? tankCapacity,
    FuelType? fuelType,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleEntity(
      id: id ?? _faker.guid.guid(),
      userId: userId ?? _faker.guid.guid(),
      name: name ?? _faker.vehicle.model(),
      plate: plate ?? 'ABC-${_faker.randomGenerator.integer(9999, min: 1000)}',
      tankCapacity: tankCapacity ?? 50.0,
      fuelType: fuelType ?? FuelType.gasoline,
      photoPath: photoPath,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static List<VehicleEntity> createList(int count) {
    return List.generate(count, (_) => create());
  }
}
```

---

## 🚀 Comandos Úteis

### Executar todos os testes

```bash
flutter test
```

### Executar teste específico

```bash
flutter test test/core/validators/email_validator_test.dart
```

### Executar com cobertura

```bash
flutter test --coverage
```

### Gerar relatório de cobertura (HTML)

```bash
# macOS/Linux
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Windows
perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

### Executar testes em watch mode (com entr)

```bash
find test -name "*.dart" | entr flutter test
```

---

## ✅ Checklist Geral de Implementação

### Setup Inicial

- [x] Criar pasta `test/` na raiz do projeto
- [x] Adicionar dependências (`mocktail`, `faker`) ao `pubspec.yaml`
- [x] Criar estrutura de pastas espelhando `lib/`
- [x] Criar `test/helpers/` com mocks e factories base
  - [x] mock_repositories.dart (VehicleRepository, RefuelRepository, UserRepository)
  - [x] mock_services.dart (AuthService)
  - [x] test_helpers.dart (matchers customizados para Either)
  - [x] factories/user_factory.dart
  - [x] factories/vehicle_factory.dart
  - [x] factories/refuel_factory.dart
- [x] Validar infraestrutura (10 testes passando)

### Fase 1: Core (2-3 dias)

- [x] Validators (email, password, plate)
- [x] Extensions (String, DateTime)
- [x] Helpers (currency, date)
- [x] **Meta:** 100% de cobertura
- **Status:** ✅ **COMPLETO** - 124 testes passando

### Fase 2: Mappers (1-2 dias)

- [ ] UserMapper
- [ ] VehicleMapper
- [ ] RefuelMapper
- [ ] **Meta:** 100% de cobertura

### Fase 3: Auth (2-3 dias)

- [ ] LoginEmailPasswordCommand
- [ ] LoginWithGoogleCommand
- [ ] RegisterCommand
- [ ] AuthRepositoryImpl
- [ ] **Meta:** 80%+ Commands, 70%+ Repository

### Fase 4: Vehicle (2-3 dias)

- [ ] CreateOrUpdateVehicleCommand
- [ ] DeleteVehicleCommand
- [ ] LoadVehiclesCommand
- [ ] VehicleRepositoryImpl
- [ ] **Meta:** 80%+ Commands, 70%+ Repository

### Fase 5: Refuel (3-4 dias)

- [ ] CreateOrUpdateRefuelCommand (com validação de km)
- [ ] CalculateConsumptionCommand (lógica crítica)
- [ ] DeleteRefuelCommand
- [ ] LoadRefuelsByVehicleCommand
- [ ] RefuelRepositoryImpl
- [ ] **Meta:** 85%+ Commands, 70%+ Repository

### Fase 6: Integration (opcional - 2-3 dias)

- [ ] Fluxo completo: Login → Criar Veículo → Adicionar Abastecimento
- [ ] Cálculo de consumo end-to-end
- [ ] Deletar veículo em cascata

---

## 🔍 Boas Práticas

### ✅ Faça

- Nomeie testes com `deve_[ação]_quando_[condição]`
- Use `Arrange-Act-Assert` em todos os testes
- Isole testes com mocks (não dependa de I/O real)
- Teste casos edge (null, vazio, negativo, zero)
- Verifique chamadas com `verify()` e `verifyNever()`
- Use factories para criar dados fake consistentes
- Mantenha testes rápidos (< 5s total)

### ❌ Não faça

- Testar código gerado (`.g.dart`, `.freezed.dart`)
- Acessar banco/rede/filesystem real em unit tests
- Criar testes que dependem de ordem de execução
- Testar múltiplos conceitos em um único teste
- Ignorar falhas intermitentes ("flaky tests")
- Duplicar setup em cada teste (use `setUp()`)

---

## 📊 Monitoramento de Progresso

### Dashboards Sugeridos

**Cobertura por Domínio:**

| Domínio | Validators | Mappers   | Commands  | Repositories | Total  |
|---------|----------- | --------- | ----------|--------------|------- |
| Core    | ✅ 7/7     |  -        |  -        | -            | ✅ 100%|
| Auth    | -          |  0/1      |  0/3      | 0/1          | 0%     |
| Vehicle | -          |  0/1      |  0/3      | 0/1          | 0%     |
| Refuel  | -          |  0/1      |  0/4      | 0/1          | 0%     |

**Total geral:** 124 testes passando (Fase 1 completa)

**Atualizar após cada fase completada.**

**Atualizar após cada fase completada.**

---

## 🎯 Critérios de Sucesso

### Fase 1 (Core) - Completa quando

- ✅ Todos os validators têm 100% cobertura
- ✅ Extensions testadas com casos válidos e inválidos
- ✅ Helpers testados com edge cases (null, zero, negativo)

### Fase 2 (Mappers) - Completa quando

- ✅ Conversão bidirecional testada (Entity ↔ TableData)
- ✅ Enums mapeados corretamente
- ✅ Valores null tratados

### Fase 3 (Auth) - Completa quando

- ✅ Todos os fluxos de autenticação testados
- ✅ Erros Firebase mapeados para Failures
- ✅ Validações impedem inputs inválidos

### Fase 4 (Vehicle) - Completa quando

- ✅ CRUD completo testado
- ✅ Cascade delete (foto) verificado
- ✅ Validações impedem dados inválidos

### Fase 5 (Refuel) - Completa quando

- ✅ Lógica de cálculo de consumo validada
- ✅ Validação de quilometragem crescente funciona
- ✅ Casos edge (primeiro abastecimento, parcial) cobertos

---

## 📚 Referências

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Clean Architecture Testing Strategies](https://blog.cleancoder.com/uncle-bob/2017/10/03/TestContravariance.html)

---

## 🤝 Contribuindo

Ao adicionar novos testes:

1. Siga a estrutura de pastas existente
2. Use templates fornecidos neste documento
3. Atualize checklist e dashboard de progresso
4. Garanta 80%+ de cobertura em Commands
5. Execute `flutter test` antes de commit
6. Documente casos edge importantes

---

**Última atualização:** 27/01/2026  
**Versão:** 1.0  
**Responsável:** Equipe de Engenharia Gasosa App
