# Guia de Contribuição - Gasosa App

Obrigado por considerar contribuir com o Gasosa App! Este guia fornece diretrizes para manter o código consistente e a arquitetura saudável.

---

## 📋 Antes de Contribuir

1. **Leia a documentação:**
   - [README Principal](./README.md)
   - [Guia de Início Rápido](./quick-start.md)
   - [ADR - Decisões Arquiteturais](./adr.md)
   - Documentação do domínio relevante

2. **Entenda os princípios:**
   - Clean Architecture
   - Command Pattern
   - Either monad para error handling
   - Offline-first

3. **Configure o ambiente:**
   - Siga o [Guia de Início Rápido](./quick-start.md)

---

## 🔀 Workflow de Contribuição

### 1. Criar Branch

```bash
# Feature
git checkout -b feature/nome-da-feature

# Bugfix
git checkout -b fix/nome-do-bug

# Refactor
git checkout -b refactor/nome-do-refactor
```

### 2. Desenvolver

Siga os padrões descritos neste guia (veja seções abaixo).

### 3. Testar

```bash
# Executar testes
flutter test

# Verificar cobertura
flutter test --coverage

# Análise de código
flutter analyze

# Formatar
dart format lib/ test/
```

### 4. Commit

Use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Feature
git commit -m "feat(vehicle): adicionar campo cor ao veículo"

# Bugfix
git commit -m "fix(refuel): corrigir cálculo de consumo médio"

# Refactor
git commit -m "refactor(auth): extrair validação de email para Core"

# Docs
git commit -m "docs(readme): atualizar guia de instalação"

# Tests
git commit -m "test(vehicle): adicionar testes para CreateVehicleCommand"
```

### 5. Push e Pull Request

```bash
git push origin feature/nome-da-feature
```

Abra PR com:
- Título descritivo
- Descrição do que foi feito e por quê
- Referência a issues (se houver)
- Screenshots (se UI)

---

## 🏗️ Padrões de Código

### Clean Architecture

Sempre respeite a separação de camadas:

```
Presentation → Application → Domain → Data
```

✅ **Correto:**
- UI chama Command
- Command chama Repository (interface)
- Repository implementado em Data

❌ **Incorreto:**
- UI chama Repository diretamente
- Domain importa Drift ou Firebase
- Data conhece detalhes de UI

---

### Nomenclatura

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| **Entity** | `<Nome>Entity` | `VehicleEntity` |
| **Repository (interface)** | `<Nome>Repository` | `VehicleRepository` |
| **Repository (impl)** | `<Nome>RepositoryImpl` | `VehicleRepositoryImpl` |
| **Command** | `<Verbo><Nome>Command` | `CreateVehicleCommand` |
| **DAO** | `<Nome>Dao` | `VehicleDao` |
| **Mapper** | `<Nome>Mapper` | `VehicleMapper` |
| **Screen** | `<Nome>Screen` | `VehicleListScreen` |
| **Widget** | `<Nome>Widget` ou `<Nome>` | `VehicleCard` |
| **Failure** | `<Tipo>Failure` | `DatabaseFailure` |

---

### Estrutura de Arquivos

#### Adicionar nova entidade

```dart
// lib/domain/entities/vehicle.dart
class VehicleEntity {
  final String id;
  final String name;
  // Sempre imutável (final)
  // Sem lógica de negócio
  
  const VehicleEntity({required this.id, required this.name});
}
```

#### Adicionar novo Repository

```dart
// 1. Interface em Domain
// lib/domain/repositories/vehicle_repository.dart
abstract interface class VehicleRepository {
  Future<Either<Failure, Unit>> createVehicle(VehicleEntity vehicle);
}

// 2. Implementação em Data
// lib/data/repositories/vehicle_repository_impl.dart
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleDao _dao;
  
  @override
  Future<Either<Failure, Unit>> createVehicle(VehicleEntity vehicle) async {
    try {
      await _dao.upsert(VehicleMapper.toCompanion(vehicle));
      return right(unit);
    } catch (e) {
      return left(DatabaseFailure('Erro ao criar veículo', cause: e));
    }
  }
}
```

#### Adicionar novo Command

```dart
// lib/application/commands/vehicles/create_vehicle_command.dart
class CreateVehicleCommand {
  final VehicleRepository _repository;
  
  CreateVehicleCommand({required VehicleRepository repository})
      : _repository = repository;
  
  Future<Either<Failure, Unit>> call(VehicleEntity entity) async {
    // 1. Validações
    final validationResult = _validate(entity);
    if (validationResult.isLeft()) {
      return validationResult;
    }
    
    // 2. Lógica de negócio
    // 3. Persistência
    return _repository.createVehicle(entity);
  }
  
  Either<Failure, Unit> _validate(VehicleEntity entity) {
    if (entity.name.trim().isEmpty) {
      return left(ValidationFailure('Nome é obrigatório'));
    }
    return right(unit);
  }
}
```

#### Registrar no DI

```dart
// lib/core/di/injection.dart
void setupDI() {
  // DAOs
  getIt.registerSingleton<VehicleDao>(VehicleDao(getIt<AppDatabase>()));
  
  // Repositories
  getIt.registerFactory<VehicleRepository>(
    () => VehicleRepositoryImpl(getIt<VehicleDao>()),
  );
  
  // Commands
  getIt.registerFactory(
    () => CreateVehicleCommand(repository: getIt<VehicleRepository>()),
  );
}
```

---

### Error Handling

✅ **Sempre use Either:**

```dart
Future<Either<Failure, VehicleEntity>> getVehicle(String id) async {
  try {
    final data = await _dao.getById(id);
    if (data == null) {
      return left(DatabaseFailure('Veículo não encontrado'));
    }
    return right(VehicleMapper.toDomain(data));
  } catch (e) {
    return left(DatabaseFailure('Erro ao buscar veículo', cause: e));
  }
}
```

❌ **Não use throw para controle de fluxo:**

```dart
// ❌ EVITE
if (name.isEmpty) {
  throw ValidationException('Nome obrigatório');
}
```

---

### Testes

#### Testar Command

```dart
// test/application/commands/create_vehicle_command_test.dart
void main() {
  late MockVehicleRepository mockRepo;
  late CreateVehicleCommand command;

  setUp(() {
    mockRepo = MockVehicleRepository();
    command = CreateVehicleCommand(repository: mockRepo);
  });

  group('CreateVehicleCommand', () {
    test('deve criar veículo com sucesso', () async {
      // Arrange
      final vehicle = VehicleEntity(id: '1', name: 'Civic', ...);
      when(() => mockRepo.createVehicle(vehicle))
          .thenAnswer((_) async => right(unit));

      // Act
      final result = await command.call(vehicle);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepo.createVehicle(vehicle)).called(1);
    });

    test('deve retornar ValidationFailure quando nome vazio', () async {
      // Arrange
      final vehicle = VehicleEntity(id: '1', name: '', ...);

      // Act
      final result = await command.call(vehicle);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Deveria retornar Left'),
      );
    });
  });
}
```

#### Testar Mapper

```dart
// test/data/mappers/vehicle_mapper_test.dart
void main() {
  group('VehicleMapper', () {
    test('deve converter TableData para Entity', () {
      // Arrange
      final tableData = VehicleTableData(
        id: '1',
        name: 'Civic',
        ...
      );

      // Act
      final entity = VehicleMapper.toDomain(tableData);

      // Assert
      expect(entity.id, '1');
      expect(entity.name, 'Civic');
    });
  });
}
```

---

## 📏 Code Style

### Formatação

```bash
# Formatar automaticamente
dart format lib/ test/
```

### Lint Rules

O projeto usa `flutter_lints`. Sempre execute:

```bash
flutter analyze
```

Corrija todos os warnings antes de fazer PR.

---

### Imports

Organize imports em 3 grupos:

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Packages externos
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';

// 4. Imports internos (relativos)
import '../domain/entities/vehicle.dart';
import '../core/errors/failure.dart';
```

---

## 🧪 Cobertura de Testes

### Mínimo Esperado

- **Commands**: 80%+
- **Mappers**: 100%
- **Validators**: 100%
- **Repositories**: 70%+
- **UI**: 50%+ (testes de widgets críticos)

### Executar

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🚫 Anti-padrões (Não Faça)

### 1. Lógica de negócio na UI

❌ **Incorreto:**
```dart
class VehicleFormScreen extends StatelessWidget {
  void saveVehicle() {
    if (name.isEmpty) {
      showError('Nome obrigatório');
      return;
    }
    final repo = getIt<VehicleRepository>();
    repo.createVehicle(VehicleEntity(...));
  }
}
```

✅ **Correto:**
```dart
class VehicleFormScreen extends StatelessWidget {
  void saveVehicle() {
    final command = getIt<CreateVehicleCommand>();
    final result = await command.call(VehicleEntity(...));
    result.fold(
      (failure) => showError(failure.message),
      (_) => navigateBack(),
    );
  }
}
```

---

### 2. Expor tipos de Data para Presentation

❌ **Incorreto:**
```dart
// VehicleTableData (Drift) exposto para UI
Stream<List<VehicleTableData>> watchVehicles();
```

✅ **Correto:**
```dart
// Retornar Entity (Domain)
Stream<Either<Failure, List<VehicleEntity>>> watchVehicles();
```

---

### 3. Usar throw para controle de fluxo

❌ **Incorreto:**
```dart
if (name.isEmpty) throw ValidationException('Nome obrigatório');
```

✅ **Correto:**
```dart
if (name.isEmpty) return left(ValidationFailure('Nome obrigatório'));
```

---

### 4. Repository direto da UI

❌ **Incorreto:**
```dart
final repo = getIt<VehicleRepository>();
await repo.createVehicle(vehicle);
```

✅ **Correto:**
```dart
final command = getIt<CreateVehicleCommand>();
await command.call(vehicle);
```

---

## 📝 Checklist de PR

Antes de abrir PR, verifique:

- [ ] Código segue Clean Architecture
- [ ] Testes adicionados/atualizados
- [ ] `flutter analyze` sem warnings
- [ ] `dart format` aplicado
- [ ] Documentação atualizada (se necessário)
- [ ] Commit messages seguem Conventional Commits
- [ ] PR description é clara
- [ ] Sem TODOs ou código comentado

---

## 🎯 Boas Práticas

### 1. Começar pelo Domain

Ao adicionar feature:
1. Criar/atualizar Entity (Domain)
2. Definir contrato Repository (Domain)
3. Implementar Repository (Data)
4. Criar Command (Application)
5. Desenvolver UI (Presentation)

### 2. Testar primeiro (TDD)

Considere escrever teste antes da implementação:
1. Escrever teste que falha
2. Implementar feature
3. Teste passa
4. Refatorar

### 3. Commits pequenos e frequentes

```bash
# ✅ Bom
git commit -m "feat(vehicle): adicionar entidade VehicleEntity"
git commit -m "feat(vehicle): adicionar VehicleRepository"
git commit -m "feat(vehicle): adicionar CreateVehicleCommand"

# ❌ Ruim
git commit -m "feat(vehicle): implementar tudo"
```

---

## 🤝 Code Review

### Como Revisor

- Verifique arquitetura (camadas respeitadas)
- Valide testes (cobertura e qualidade)
- Sugira melhorias de nomenclatura
- Aponte violações de padrões

### Como Autor

- Responda a todos os comentários
- Faça alterações solicitadas
- Agradeça feedbacks construtivos
- Peça esclarecimentos se necessário

---

## 📚 Recursos

- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Documentation](https://flutter.dev/docs)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

## ❓ Dúvidas

- Abra issue para discutir dúvidas técnicas
- Consulte documentação dos domínios
- Pergunte no chat do time

---

**Obrigado por contribuir! 🚀**
