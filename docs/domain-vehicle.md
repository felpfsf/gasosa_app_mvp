# Domínio: Vehicle (Veículos)

## 1. Visão geral do domínio "Vehicle"

### Responsabilidade

O domínio **Vehicle** gerencia o cadastro, edição, listagem e exclusão de veículos pertencentes aos usuários do Gasosa App. Cada veículo registra informações como nome, placa, tipo de combustível, capacidade do tanque e foto.

### Problemas que resolve

- Cadastro de múltiplos veículos por usuário
- Vínculo entre veículos e seus abastecimentos
- Armazenamento local com Drift (SQLite) para suporte offline-first
- Upload e armazenamento de fotos dos veículos
- Atualização e exclusão de veículos com sincronização reativa (Streams)

### Relacionamento com outros domínios

- **Auth**: Depende do `userId` autenticado para vincular veículos ao proprietário
- **Refuel**: Fornece o `vehicleId` necessário para registrar abastecimentos
- **User**: Indiretamente relacionado via `userId`
- **Core**: Utiliza infraestrutura compartilhada (Failure, Either, validators, DI)

---

## 2. Arquitetura utilizada no domínio

### Camadas

```md
Presentation Layer (UI + State Management)
       ↓
Application Layer (Commands)
       ↓
Domain Layer (Entities + Repository Contracts)
       ↓
Data Layer (Repository Impl + DAO + Mappers)
       ↓
Infrastructure (Drift Database + Local Storage)
```

### Padrões aplicados

- **Clean Architecture**: Inversão de dependência, Domain no centro
- **Command Pattern**: `CreateOrUpdateVehicleCommand`, `DeleteVehicleCommand`, `LoadVehiclesCommand`
- **Repository Pattern**: Abstração de persistência (Drift)
- **DAO Pattern**: Acesso direto ao banco de dados via Drift
- **Mapper Pattern**: Conversão entre `VehicleEntity` (domain) ↔ `VehicleTableData` (data) ↔ `VehicleCompanion` (insert/update)
- **Offline-first**: Drift como source of truth local, suporte a Streams reativos
- **Either monad (dartz)**: Tratamento explícito de erros

### Fluxo típico

```md
┌──────────────────┐
│ VehicleListScreen│  (UI)
└────────┬─────────┘
         │ 1. Carrega lista de veículos
         ↓
┌─────────────────────┐
│ LoadVehiclesCommand │ (Application)
└────────┬────────────┘
         │ 2. Chama repository com userId
         ↓
┌──────────────────┐
│ VehicleRepository│ (Domain - Interface)
└────────┬─────────┘
         │ 3. Contract abstrato
         ↓
┌───────────────────────┐
│ VehicleRepositoryImpl │ (Data)
└────────┬──────────────┘
         │ 4. Usa VehicleDao
         ↓
┌─────────────┐
│ VehicleDao  │ (Data - Drift DAO)
└────────┬────┘
         │ 5. Query SQL no Drift
         ↓
┌─────────────┐
│ SQLite DB   │ (Infrastructure)
└─────────────┘
```

**Regras de separação de responsabilidades:**

- **Presentation**: Exibe lista, formulário, estados (loading/error/success)
- **Commands**: Orquestram lógica (ex: validar antes de salvar, deletar + limpar foto)
- **Domain**: Define contratos (`VehicleRepository`) e entidade (`VehicleEntity`)
- **Data**: Implementa persistência com Drift, mapeia entre camadas
- **Drift DAO**: Executa queries SQL diretamente

---

## 3. Estrutura de pastas do domínio

```bash
lib/
├─ domain/
│  ├─ entities/
│  │  ├─ vehicle.dart              # Entidade de domínio pura
│  │  └─ fuel_type.dart            # Enum de tipos de combustível
│  └─ repositories/
│     └─ vehicle_repository.dart   # Contrato (interface)
│
├─ data/
│  ├─ local/
│  │  ├─ dao/
│  │  │  ├─ vehicle_dao.dart       # Drift DAO para veículos
│  │  │  └─ vehicle_dao.g.dart     # Gerado pelo build_runner
│  │  ├─ db/
│  │  │  └─ database.dart          # Drift Database principal
│  │  └─ tables/
│  │     └─ vehicle_table.dart     # Definição da tabela
│  ├─ mappers/
│  │  └─ vehicle_mapper.dart       # VehicleEntity ↔ VehicleTableData
│  └─ repositories/
│     └─ vehicle_repository_impl.dart  # Implementação do repositório
│
├─ application/
│  └─ commands/
│     └─ vehicles/
│        ├─ create_or_update_vehicle_command.dart
│        ├─ delete_vehicle_command.dart
│        └─ load_vehicles_command.dart
│
└─ presentation/
   └─ screens/
      └─ vehicle/
         ├─ vehicle_list_screen.dart
         ├─ vehicle_form_screen.dart
         └─ widgets/
            └─ vehicle_card.dart
```

### Papel de cada pasta

- **domain/entities**: Objetos de domínio puros (`VehicleEntity`, `FuelType`)
- **domain/repositories**: Contratos que a camada de dados deve implementar
- **data/local/dao**: DAOs do Drift (acesso ao banco SQLite)
- **data/local/tables**: Definições de tabelas Drift
- **data/mappers**: Conversão entre Entity (domain) e TableData (Drift)
- **data/repositories**: Implementações concretas dos contratos de domínio
- **application/commands**: Casos de uso da aplicação
- **presentation/screens**: Telas e widgets da UI

### Boas práticas ao adicionar arquivos

✅ **Faça:**

- Mantenha `VehicleEntity` imutável e sem lógica
- Crie queries no DAO (`vehicle_dao.dart`), não no Repository
- Use Mappers para toda conversão entre camadas
- Nomeie Commands com verbos claros
- Retorne `Either<Failure, T>` em operações que podem falhar
- Use `Stream` para dados reativos (lista atualiza em tempo real)

❌ **Não faça:**

- Referenciar Drift diretamente na UI
- Colocar SQL no Repository (isso é responsabilidade do DAO)
- Misturar lógica de fotos (storage) com lógica de veículo (use Commands para orquestrar)
- Fazer validações apenas na UI (valide também no Command)

---

## 4. Dependências utilizadas no domínio

### `drift` (^2.28.1)

**Por quê:** ORM SQLite type-safe para persistência local  
**Quando usar:** Definir tabelas, DAOs, queries  
**Quando não usar:** Diretamente na UI ou Domain (apenas em Data)

### `drift_flutter` (^0.2.5)

**Por quê:** Integração do Drift com Flutter (path do DB)  
**Quando usar:** Inicialização do banco na camada Data  
**Quando não usar:** Em qualquer outra camada

### `path_provider` (^2.1.5)

**Por quê:** Obter diretórios do sistema para salvar DB e fotos  
**Quando usar:** Inicialização do Drift, salvar fotos localmente  
**Quando não usar:** Diretamente na UI

### `uuid` (^4.5.1)

**Por quê:** Gerar IDs únicos para veículos (offline-first)  
**Quando usar:** Criar novos veículos antes de persistir  
**Quando não usar:** Para IDs que vêm do backend (se houver sync futura)

### `image_picker` (^1.2.0)

**Por quê:** Capturar ou selecionar foto do veículo  
**Quando usar:** Encapsulado em `LocalPhotoStorage` ou Command  
**Quando não usar:** Diretamente na UI (use abstração)

### `dartz` (^0.10.1)

**Por quê:** Either monad para tratamento de erros  
**Quando usar:** Retornos de Commands e Repositories  
**Quando não usar:** Em entidades ou DAOs

### `get_it` (^8.2.0)

**Por quê:** Injeção de dependências  
**Quando usar:** Registro de Commands, Repositories, DAOs  
**Quando não usar:** Para passar estado entre telas

---

## 5. Módulo "Commands" dentro do domínio "Vehicle"

### O que oferece

Os Commands de Vehicle oferecem **casos de uso testáveis** para gerenciar veículos:

- **CreateOrUpdateVehicleCommand**: Cria ou atualiza veículo (lógica unificada)
- **DeleteVehicleCommand**: Deleta veículo e limpa foto associada
- **LoadVehiclesCommand**: Carrega lista de veículos do usuário

### Abstrações expostas

Cada Command expõe:

- Método `call(...)` que executa a ação
- Retorno `Either<Failure, T>` para tratamento de erro
- Dependências injetadas (`VehicleRepository`, `LocalPhotoStorage`)

### Como consumir

✅ **Correto:**

```dart
final command = getIt<CreateOrUpdateVehicleCommand>();
final vehicle = VehicleEntity(
  id: '', // vazio = create, preenchido = update
  userId: currentUserId,
  name: 'Civic',
  fuelType: FuelType.gasoline,
  createdAt: DateTime.now(),
);

final result = await command.call(vehicle);

result.fold(
  (failure) => showError(failure.message),
  (_) => navigateToList(),
);
```

❌ **Incorreto:**

```dart
// ❌ Nunca acessar repository direto da UI
final repo = getIt<VehicleRepository>();
await repo.createVehicle(vehicle);

// ❌ Nunca fazer validação apenas na UI
if (name.isEmpty) return; // validação deveria estar no Command
```

### Exemplos práticos

**Criar veículo com foto:**

```dart
class VehicleFormCubit extends Cubit<VehicleFormState> {
  final CreateOrUpdateVehicleCommand _saveCommand;
  final LocalPhotoStorage _photoStorage;

  Future<void> saveVehicle({
    required String name,
    required FuelType fuelType,
    String? photoPath,
  }) async {
    emit(VehicleFormLoading());

    // 1. Upload da foto (se houver)
    String? savedPhotoPath;
    if (photoPath != null) {
      final photoResult = await _photoStorage.save(photoPath);
      photoResult.fold(
        (failure) => emit(VehicleFormError(failure.message)),
        (path) => savedPhotoPath = path,
      );
    }

    // 2. Criar entidade
    final vehicle = VehicleEntity(
      id: const Uuid().v4(),
      userId: currentUserId,
      name: name,
      fuelType: fuelType,
      photoPath: savedPhotoPath,
      createdAt: DateTime.now(),
    );

    // 3. Salvar
    final result = await _saveCommand(vehicle);
    result.fold(
      (failure) => emit(VehicleFormError(failure.message)),
      (_) => emit(VehicleFormSuccess()),
    );
  }
}
```

---

## 6. Regras de negócio importantes

### Validações

- Nome do veículo é obrigatório (mínimo 2 caracteres)
- Tipo de combustível é obrigatório (`FuelType` enum)
- Placa é opcional (mas deve seguir formato brasileiro se fornecida)
- Capacidade do tanque é opcional (se fornecida, deve ser > 0)

### Restrições de fluxo

- Usuário não autenticado não pode criar veículos
- Veículo pertence a um único usuário (`userId`)
- Deletar veículo deve deletar também:
  - Foto local (se houver)
  - Abastecimentos vinculados (cascade delete)
- ID do veículo é gerado localmente (UUID) para suportar offline-first

### Decisões arquiteturais

- **Drift é a única fonte de verdade local** (não há sincronização com backend ainda)
- **Streams reativos**: UI escuta `watchAllByUserId` para atualizar automaticamente
- **Fotos salvas localmente**: Usar `path_provider` + diretório de documentos do app
- **Mapper sempre explícito**: Nunca expor `VehicleTableData` fora de Data

### O que NÃO deve ser feito

❌ **Nunca:**

- Expor `VehicleTableData` (Drift) para Presentation ou Domain
- Fazer queries SQL fora do DAO
- Deletar veículo sem deletar foto associada
- Criar veículo sem `userId`
- Usar `throw` para controle de fluxo (use Either)
- Referenciar `VehicleDao` fora de `VehicleRepositoryImpl`

---

## 7. Agente de IA especializado no domínio "Vehicle"

# Agente Gasosa Vehicle Specialist

Você é um **desenvolvedor mobile Flutter sênior**, especialista no **domínio de Veículos (Vehicle)** do **Gasosa App**.

## Conhecimento profundo

### Arquitetura

- Clean Architecture: Presentation → Application (Commands) → Domain → Data → Infrastructure
- Offline-first com Drift (SQLite)
- Streams reativos para UI (`watchAllByUserId`)
- Command Pattern para orquestração de lógica complexa
- Mapper Pattern para isolamento de camadas

### Regras de negócio

- Veículo pertence a um único usuário (`userId`)
- ID gerado com UUID (suporte offline)
- Drift é a fonte de verdade local
- Foto salva localmente com `path_provider`
- Deletar veículo = deletar foto + abastecimentos (cascade)
- Validações: nome obrigatório, fuelType obrigatório, tankCapacity > 0 (se fornecida)

### Padrões adotados

- Entidades imutáveis (`VehicleEntity`)
- Contratos em Domain (`VehicleRepository`)
- Implementação em Data (`VehicleRepositoryImpl`)
- DAOs para queries SQL (`VehicleDao`)
- Mappers explícitos (`VehicleMapper`)
- Either para tratamento de erro
- GetIt para DI

## Responsabilidades

### Desenvolvimento

- Implementar CRUD completo de veículos
- Adicionar campos novos (ex: ano, modelo, cor)
- Criar queries otimizadas no DAO
- Integrar upload de fotos
- Suporte a filtros e ordenação

### Refatoração

- Mover lógica de negócio da UI para Commands
- Garantir uso consistente de Mappers
- Consolidar queries complexas no DAO
- Otimizar Streams (evitar rebuild desnecessário)

### Testes

- Testar Commands com mock de Repository
- Testar Mappers (Entity ↔ TableData)
- Testar DAO com Drift in-memory
- Validar cascade delete

### Alertas

- ⚠️ Drift sendo importado fora de `data/`
- ⚠️ SQL inline no Repository (deveria estar no DAO)
- ⚠️ `VehicleTableData` exposta para Presentation
- ⚠️ Falta de tratamento de erro com Either
- ⚠️ Foto não sendo deletada ao deletar veículo
- ⚠️ Validação apenas na UI

## Prioridades

1. **Clareza**: Separação clara entre camadas
2. **Testabilidade**: DAOs testáveis, Commands mockáveis
3. **Baixo acoplamento**: Domain não conhece Drift
4. **Consistência**: Sempre usar Mappers, sempre usar Either

## Comportamento

- **Quando solicitado a adicionar campo no veículo:**
  1. Atualizar `VehicleEntity` (domain)
  2. Atualizar tabela Drift (`vehicle_table.dart`)
  3. Atualizar `VehicleMapper`
  4. Rodar `build_runner` para gerar código
  5. Atualizar UI conforme necessário

- **Quando identificar query lenta:**
  1. Analisar índices no Drift
  2. Sugerir otimização no DAO
  3. Considerar paginação se lista for grande

- **Nunca:**
  - Expor Drift para fora de Data
  - Fazer queries SQL fora do DAO
  - Quebrar cascade delete

---

Você é um **copilot técnico interno do Gasosa App**, focado em manter a integridade do domínio Vehicle e garantir performance com Drift.
