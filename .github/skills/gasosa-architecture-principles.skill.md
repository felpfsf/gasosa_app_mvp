# Skill — Gasosa Architecture Principles

**Princípios de arquitetura Clean Architecture + DDD light do Gasosa App**

---

## Visão Geral

Esta skill documenta os princípios arquiteturais fundamentais do Gasosa App, baseados em **Clean Architecture** e **DDD light**, priorizando:

- **Separação clara de responsabilidades**
- **Baixo acoplamento** entre camadas
- **Alta testabilidade**
- **Offline-first**
- **Evolução sustentável**

---

## Estrutura de Camadas

```
┌──────────────────────────────────────────────┐
│         Presentation Layer                   │
│  (UI, Screens, Widgets, ViewModels)          │
│  - Não contém regras de negócio              │
│  - Observa estado (Provider, Bloc, etc.)     │
│  - Chama Commands                            │
└──────────────────┬───────────────────────────┘
                   │ depende
┌──────────────────▼───────────────────────────┐
│         Application Layer                    │
│  (Commands / Use Cases)                      │
│  - Orquestra regras de negócio               │
│  - Chama Repositories                        │
│  - Retorna Either<Failure, Result>           │
└──────────────────┬───────────────────────────┘
                   │ usa
┌──────────────────▼───────────────────────────┐
│         Domain Layer                         │
│  (Entities, Repository Interfaces)           │
│  - Puro, sem dependências de frameworks      │
│  - Imutável                                  │
│  - Validações básicas                        │
└──────────────────┬───────────────────────────┘
                   │ implementado por
┌──────────────────▼───────────────────────────┐
│         Data Layer                           │
│  (Repository Implementations, Mappers, DAOs) │
│  - Drift (SQLite)                            │
│  - Firebase                                  │
│  - Mappers (Entity ↔ DTO)                    │
└──────────────────────────────────────────────┘
```

### Regras de Dependência

1. **Presentation** → depende de **Application**
2. **Application** → depende de **Domain**
3. **Domain** → **não depende de ninguém** (puro)
4. **Data** → implementa interfaces de **Domain**

---

## Princípios Fundamentais

### 1. Domain é Produto

**Regra:** Domínio não conhece frameworks, UI ou infraestrutura.

```dart
// ✅ BOM: Domínio puro
class RefuelEntity {
  final String id;
  final String vehicleId;
  final double liters;
  final double totalValue;
  final DateTime date;

  RefuelEntity({...});

  // Regra de negócio no domínio
  double get pricePerLiter => totalValue / liters;
}

// ❌ RUIM: Domínio dependendo de framework
class RefuelEntity extends ChangeNotifier { // ChangeNotifier é do Flutter!
  // ...
}
```

### 2. Commands Orquestram, Não Implementam

**Regra:** Commands coordenam, mas delegam lógica complexa.

```dart
// ✅ BOM: Command delega para Repository
class CreateRefuelCommand {
  final IRefuelRepository _repository;

  Future<Either<Failure, RefuelEntity>> execute({...}) async {
    // Validação
    if (liters <= 0) return Left(ValidationFailure('Litros inválidos'));

    // Criação
    final refuel = RefuelEntity(...);

    // Persistência (delega)
    return _repository.save(refuel);
  }
}

// ❌ RUIM: Command implementa persistência diretamente
class CreateRefuelCommand {
  final AppDatabase _database;

  Future<Either<Failure, RefuelEntity>> execute({...}) async {
    // Validação
    if (liters <= 0) return Left(ValidationFailure('Litros inválidos'));

    // ❌ Command não deve saber sobre Drift!
    await _database.into(_database.refuels).insert(...);
  }
}
```

### 3. UI Não Decide Regras de Negócio

**Regra:** Lógica de negócio fica em Commands, não em Widgets/ViewModels.

```dart
// ✅ BOM: UI chama Command, não implementa lógica
class RefuelFormViewModel extends ChangeNotifier {
  final CreateRefuelCommand _createRefuelCommand;

  Future<void> saveRefuel({...}) async {
    final result = await _createRefuelCommand.execute(...);
    
    result.fold(
      (failure) => _showError(failure.message),
      (refuel) => _showSuccess(),
    );
  }
}

// ❌ RUIM: UI implementa lógica de negócio
class RefuelFormViewModel extends ChangeNotifier {
  Future<void> saveRefuel({...}) async {
    // ❌ Lógica de validação na UI
    if (liters <= 0) {
      _showError('Litros inválidos');
      return;
    }

    // ❌ Cálculo de regra de negócio na UI
    final pricePerLiter = totalValue / liters;

    // ❌ UI não deve chamar Repository diretamente
    await _repository.save(...);
  }
}
```

### 4. Either para Tratamento de Erros

**Regra:** Use `Either<Failure, Result>` para tornar erros explícitos.

```dart
// ✅ BOM: Either torna erros explícitos
Future<Either<Failure, VehicleEntity>> getById(String id) async {
  try {
    final vehicleDb = await _dao.getById(id);
    if (vehicleDb == null) return Left(NotFoundFailure('Veículo não encontrado'));
    return Right(VehicleMapper.toEntity(vehicleDb));
  } catch (e) {
    return Left(DatabaseFailure('Erro ao buscar veículo'));
  }
}

// ❌ RUIM: Exceptions escondidas
Future<VehicleEntity> getById(String id) async {
  final vehicleDb = await _dao.getById(id);
  if (vehicleDb == null) throw Exception('Veículo não encontrado'); // ❌
  return VehicleMapper.toEntity(vehicleDb);
}
```

### 5. Entidades Imutáveis

**Regra:** Entidades não devem ter estado mutável.

```dart
// ✅ BOM: Entidade imutável com copyWith
class VehicleEntity {
  final String id;
  final String name;
  final String plate;

  const VehicleEntity({
    required this.id,
    required this.name,
    required this.plate,
  });

  VehicleEntity copyWith({String? name, String? plate}) {
    return VehicleEntity(
      id: id,
      name: name ?? this.name,
      plate: plate ?? this.plate,
    );
  }
}

// ❌ RUIM: Entidade mutável
class VehicleEntity {
  String id;
  String name; // ❌ Mutável
  String plate;

  VehicleEntity({required this.id, required this.name, required this.plate});

  void updateName(String newName) { // ❌
    name = newName;
  }
}
```

### 6. Repository é Interface no Domain

**Regra:** Interface no domínio, implementação em data.

```dart
// Domain: domain/repositories/i_vehicle_repository.dart
abstract class IVehicleRepository {
  Future<Either<Failure, VehicleEntity>> save(VehicleEntity vehicle);
  Future<Either<Failure, VehicleEntity>> getById(String id);
  Future<Either<Failure, List<VehicleEntity>>> getAll(String userId);
  Future<Either<Failure, Unit>> delete(String id);
}

// Data: data/repositories/vehicle_repository_impl.dart
class VehicleRepositoryImpl implements IVehicleRepository {
  final VehicleDao _dao;

  VehicleRepositoryImpl(this._dao);

  @override
  Future<Either<Failure, VehicleEntity>> save(VehicleEntity vehicle) async {
    try {
      final companion = VehicleMapper.toCompanion(vehicle);
      await _dao.insertOrUpdate(companion);
      return Right(vehicle);
    } catch (e) {
      return Left(DatabaseFailure('Erro ao salvar veículo'));
    }
  }

  // ... outras implementações
}
```

---

## Offline-First

### Estratégia

1. **Drift como fonte primária** (SQLite local)
2. **Firebase como sync** (quando online)
3. **Stream de dados** para UI reativa
4. **Conflict resolution** simples (last-write-wins)

### Exemplo

```dart
class VehicleRepositoryImpl implements IVehicleRepository {
  final VehicleDao _localDao;
  final FirebaseFirestore _firestore;

  @override
  Future<Either<Failure, VehicleEntity>> save(VehicleEntity vehicle) async {
    // 1. Salvar local (sempre)
    final localResult = await _saveLocal(vehicle);
    if (localResult.isLeft()) return localResult;

    // 2. Sync com Firebase (se online)
    _syncToFirebase(vehicle); // Fire and forget

    return localResult;
  }

  @override
  Stream<Either<Failure, List<VehicleEntity>>> watchAll(String userId) {
    // Retorna stream do Drift (local)
    return _localDao.watchAllByUser(userId).map((vehiclesDb) {
      final entities = vehiclesDb.map(VehicleMapper.toEntity).toList();
      return Right(entities);
    });
  }
}
```

---

## Injeção de Dependências

### Estrutura

```
lib/core/di/
├─ injection.dart          # Setup de DI com GetIt
└─ injection.config.dart   # Gerado por injectable (se usar)
```

### Exemplo com GetIt

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // DAOs
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);
  getIt.registerSingleton<VehicleDao>(database.vehicleDao);
  getIt.registerSingleton<RefuelDao>(database.refuelDao);

  // Repositories
  getIt.registerLazySingleton<IVehicleRepository>(
    () => VehicleRepositoryImpl(getIt<VehicleDao>()),
  );
  getIt.registerLazySingleton<IRefuelRepository>(
    () => RefuelRepositoryImpl(getIt<RefuelDao>()),
  );

  // Commands
  getIt.registerFactory(
    () => CreateOrUpdateVehicleCommand(getIt<IVehicleRepository>()),
  );
  getIt.registerFactory(
    () => LoadVehiclesCommand(getIt<IVehicleRepository>()),
  );
}
```

---

## Quando Aplicar

Use esta skill quando:
- Criar novas features/domínios
- Refatorar código existente
- Validar separação de camadas
- Revisar PRs
- Tomar decisões arquiteturais

---

## Checklist de Validação

- [ ] Domínio não depende de Flutter/Firebase/Drift?
- [ ] Commands orquestram, mas delegam?
- [ ] UI não decide regras de negócio?
- [ ] Either<Failure, Result> é usado para erros?
- [ ] Entidades são imutáveis?
- [ ] Repository é interface no domain, implementação em data?

---

**Referências:**
- `docs/README.md` → Visão geral da arquitetura
- `docs/domain-*.md` → Documentação por domínio
