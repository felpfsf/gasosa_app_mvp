# Skill — Gasosa Drift Conventions

**Convenções para persistência local com Drift (SQLite)**

---

## Visão Geral

Esta skill documenta as convenções do Gasosa App para **Drift** (SQLite), garantindo:
- **Schema consistente** (tables, columns, constraints)
- **Migrations seguras** e versionadas
- **DAOs otimizados** (queries, streams, transactions)
- **Performance** (índices, paginação, evitar N+1)

---

## Estrutura de Arquivos

```
lib/data/local/
├─ database.dart              # Database principal (AppDatabase)
├─ database.g.dart            # Gerado pelo Drift
├─ tables/
│  ├─ vehicles_table.dart
│  ├─ refuels_table.dart
│  └─ users_table.dart
└─ daos/
   ├─ vehicle_dao.dart
   ├─ refuel_dao.dart
   └─ user_dao.dart
```

---

## Convenções de Nomenclatura

### 1. Tables

```dart
// ✅ BOM: Plural, PascalCase
class Vehicles extends Table { ... }
class Refuels extends Table { ... }

// ❌ RUIM: Singular, snake_case
class Vehicle extends Table { ... }
class vehicle extends Table { ... }
```

### 2. Columns

```dart
// ✅ BOM: camelCase, nomes descritivos
TextColumn get vehicleId => text()();
DateTimeColumn get createdAt => dateTime()();

// ❌ RUIM: snake_case, abreviações
TextColumn get vehicle_id => text()();
DateTimeColumn get created_at => dateTime()();
TextColumn get vId => text()();
```

### 3. DAOs

```dart
// ✅ BOM: Singular + Dao, PascalCase
class VehicleDao extends DatabaseAccessor<IAppDatabase> { ... }

// ❌ RUIM: Plural, sem Dao
class VehiclesDao extends DatabaseAccessor<AppDatabase> { ... }
class VehicleRepository extends DatabaseAccessor<AppDatabase> { ... }
```

---

## Definição de Tables

### Template Padrão

```dart
import 'package:drift/drift.dart';

class Vehicles extends Table {
  // 1. PRIMARY KEY (sempre primeiro)
  TextColumn get id => text()();

  // 2. FOREIGN KEYS (se houver)
  TextColumn get userId => text()
      .customConstraint('REFERENCES users(id) ON DELETE CASCADE')();

  // 3. CAMPOS OBRIGATÓRIOS (não nullable)
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get plate => text().withLength(min: 7, max: 8)();

  // 4. CAMPOS OPCIONAIS (nullable)
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get photoPath => text().nullable()();

  // 5. METADATA (timestamps)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // 6. CONSTRAINTS
  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {plate}, // Placa única
  ];

  // 7. ÍNDICES (se necessário)
  @override
  List<String> get customConstraints => [
    'CREATE INDEX vehicles_user_id_idx ON vehicles(user_id)',
  ];
}
```

### Tipos de Colunas

```dart
// Texto
TextColumn get name => text()();

// Inteiro
IntColumn get year => integer()();

// Real (double)
RealColumn get liters => real()();
DoubleColumn get totalValue => doublePrecision()(); // Alternativa

// Boolean
BoolColumn get fullTank => boolean().withDefault(const Constant(true))();

// DateTime
DateTimeColumn get date => dateTime()();

// Blob (bytes)
BlobColumn get image => blob().nullable()();
```

### Constraints

```dart
// NOT NULL (padrão)
TextColumn get name => text()();

// NULLABLE
TextColumn get brand => text().nullable()();

// DEFAULT
BoolColumn get active => boolean().withDefault(const Constant(true))();
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

// LENGTH
TextColumn get name => text().withLength(min: 1, max: 100)();

// UNIQUE
@override
List<Set<Column>> get uniqueKeys => [{plate}];

// FOREIGN KEY
TextColumn get vehicleId => text()
    .customConstraint('REFERENCES vehicles(id) ON DELETE CASCADE')();
```

---

## Database Principal

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

@DriftDatabase(
  tables: [Vehicles, Refuels, Users],
  daos: [VehicleDao, RefuelDao, UserDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migrations futuras
        if (from < 2) {
          await m.addColumn(vehicles, vehicles.color);
        }
      },
      beforeOpen: (details) async {
        // Habilitar foreign keys (importante!)
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gasosa.db'));
    return NativeDatabase(file);
  });
}
```

---

## DAOs

### Template Padrão

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/vehicles_table.dart';

part 'vehicle_dao.g.dart';

@DriftAccessor(tables: [Vehicles])
class VehicleDao extends DatabaseAccessor<AppDatabase> with _$VehicleDaoMixin {
  VehicleDao(AppDatabase db) : super(db);

  // CREATE or UPDATE
  Future<int> insertOrUpdate(VehiclesCompanion vehicle) {
    return into(vehicles).insertOnConflictUpdate(vehicle);
  }

  // READ (single)
  Future<Vehicle?> getById(String id) {
    return (select(vehicles)..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  // READ (list)
  Future<List<Vehicle>> getAllByUser(String userId) {
    return (select(vehicles)
          ..where((v) => v.userId.equals(userId))
          ..orderBy([(v) => OrderingTerm.asc(v.name)]))
        .get();
  }

  // READ (stream)
  Stream<List<Vehicle>> watchAllByUser(String userId) {
    return (select(vehicles)
          ..where((v) => v.userId.equals(userId))
          ..orderBy([(v) => OrderingTerm.asc(v.name)]))
        .watch();
  }

  // DELETE
  Future<int> deleteById(String id) {
    return (delete(vehicles)..where((v) => v.id.equals(id))).go();
  }

  // UPDATE específico
  Future<int> updateName(String id, String newName) {
    return (update(vehicles)..where((v) => v.id.equals(id)))
        .write(VehiclesCompanion(name: Value(newName)));
  }
}
```

### Queries Complexas (JOINs)

```dart
// Query com JOIN
Future<List<RefuelWithVehicle>> getRefuelsWithVehicle(String userId) {
  final query = select(refuels).join([
    innerJoin(vehicles, vehicles.id.equalsExp(refuels.vehicleId)),
  ])..where(vehicles.userId.equals(userId));

  return query.map((row) {
    return RefuelWithVehicle(
      refuel: row.readTable(refuels),
      vehicle: row.readTable(vehicles),
    );
  }).get();
}

// Agregação
Future<double?> calculateAverageConsumption(String vehicleId) async {
  final query = selectOnly(refuels)
    ..addColumns([refuels.liters.sum(), refuels.odometer.max()])
    ..where(refuels.vehicleId.equals(vehicleId));

  final result = await query.getSingle();
  final totalLiters = result.read(refuels.liters.sum());
  final maxOdometer = result.read(refuels.odometer.max());

  if (totalLiters == null || maxOdometer == null) return null;
  return maxOdometer / totalLiters;
}
```

---

## Migrations

### Versionamento

```dart
@override
int get schemaVersion => 2; // Incrementar +1 a cada migration
```

### Tipos de Migration

#### 1. Adicionar Coluna

```dart
if (from < 2) {
  await m.addColumn(vehicles, vehicles.color);
}
```

#### 2. Criar Índice

```dart
if (from < 3) {
  await customStatement(
    'CREATE INDEX refuels_date_idx ON refuels(date DESC)',
  );
}
```

#### 3. Adicionar Table

```dart
if (from < 4) {
  await m.createTable(users);
}
```

#### 4. Migration Complexa (com dados)

```dart
if (from < 5) {
  // 1. Criar nova coluna
  await m.addColumn(vehicles, vehicles.fuelType);

  // 2. Migrar dados
  await customStatement(
    'UPDATE vehicles SET fuel_type = "gasoline" WHERE fuel_type IS NULL',
  );
}
```

---

## Performance

### 1. Índices

```dart
@override
List<String> get customConstraints => [
  'CREATE INDEX refuels_vehicle_date ON refuels(vehicle_id, date DESC)',
  'CREATE INDEX vehicles_user_id ON vehicles(user_id)',
];
```

### 2. Paginação

```dart
Future<List<Refuel>> getRefuelsPaginated(
  String vehicleId,
  int limit,
  int offset,
) {
  return (select(refuels)
        ..where((r) => r.vehicleId.equals(vehicleId))
        ..orderBy([(r) => OrderingTerm.desc(r.date)])
        ..limit(limit, offset: offset))
      .get();
}
```

### 3. Evitar N+1 Queries

```dart
// ❌ RUIM: N+1 queries
final vehicles = await vehicleDao.getAllByUser(userId);
for (final vehicle in vehicles) {
  final refuels = await refuelDao.getByVehicleId(vehicle.id); // N queries!
}

// ✅ BOM: 1 query com JOIN
final vehiclesWithRefuels = await refuelDao.getVehiclesWithRefuels(userId);
```

### 4. Transações

```dart
Future<void> deleteVehicleWithRefuels(String vehicleId) async {
  await transaction(() async {
    await (delete(refuels)..where((r) => r.vehicleId.equals(vehicleId))).go();
    await (delete(vehicles)..where((v) => v.id.equals(vehicleId))).go();
  });
}
```

---

## Testes de Drift

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Database em memória para testes
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('deve_inserir_e_buscar_vehicle', () async {
    final vehicle = VehiclesCompanion(
      id: Value('test-id'),
      userId: Value('user-id'),
      name: Value('Civic'),
      plate: Value('ABC1234'),
    );

    await database.vehicleDao.insertOrUpdate(vehicle);

    final result = await database.vehicleDao.getById('test-id');
    expect(result, isNotNull);
    expect(result!.name, 'Civic');
  });
}
```

---

## Checklist de Qualidade

- [ ] Tables usam plural (Vehicles, Refuels)?
- [ ] Columns usam camelCase?
- [ ] Primary key está definida?
- [ ] Foreign keys têm ON DELETE CASCADE (se aplicável)?
- [ ] Timestamps (createdAt, updatedAt) estão presentes?
- [ ] Índices estão criados para queries frequentes?
- [ ] DAOs retornam Stream para UI reativa?
- [ ] Transações são usadas para operações atômicas?
- [ ] Migrations estão versionadas corretamente?

---

**Referências:**
- Drift docs: https://drift.simonbinder.eu/
- `lib/data/local/` → Implementação de Drift
