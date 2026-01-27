# Domínio: Refuel (Abastecimentos)

## 1. Visão geral do domínio "Refuel"

### Responsabilidade

O domínio **Refuel** é responsável pelo registro, edição, listagem e análise de abastecimentos de veículos no Gasosa App. Inclui cálculo de consumo médio, histórico de abastecimentos e armazenamento de comprovantes (fotos de recibos).

### Problemas que resolve

- Registro detalhado de abastecimentos (data, litros, valor, quilometragem)
- Cálculo automático de consumo médio (km/L)
- Suporte a abastecimentos parciais e "tanque cheio"
- Rastreamento de valores e tipos de combustível
- Histórico por veículo com ordenação cronológica
- Armazenamento de fotos de recibos

### Relacionamento com outros domínios

- **Vehicle**: Depende de `vehicleId` para vincular abastecimentos
- **Auth**: Indiretamente via Vehicle (userId)
- **Core**: Utiliza infraestrutura compartilhada (Failure, Either, formatters, validators)
- **Photos**: Usa `LocalPhotoStorage` para salvar comprovantes

---

## 2. Arquitetura utilizada no domínio

### Camadas

```md
Presentation Layer (UI + State Management)
       ↓
Application Layer (Commands + Business Logic)
       ↓
Domain Layer (Entities + Repository Contracts)
       ↓
Data Layer (Repository Impl + DAO + Mappers)
       ↓
Infrastructure (Drift Database + Local Storage)
```

### Padrões aplicados

- **Clean Architecture**: Inversão de dependência, Domain no centro
- **Command Pattern**:
  - `CreateOrUpdateRefuelCommand`
  - `DeleteRefuelCommand`
  - `LoadRefuelsByVehicleCommand`
  - `CalculateConsumptionCommand` (lógica de negócio pura)
- **Repository Pattern**: Abstração de persistência (Drift)
- **DAO Pattern**: Acesso direto ao banco via Drift
- **Mapper Pattern**: Conversão entre camadas
- **Offline-first**: Drift como source of truth
- **Either monad (dartz)**: Tratamento de erros

### Fluxo típico (registro de abastecimento)

```md
┌─────────────────┐
│ RefuelFormScreen│  (UI)
└────────┬────────┘
         │ 1. Usuário preenche formulário
         ↓
┌──────────────────────────────┐
│ CreateOrUpdateRefuelCommand  │ (Application)
└────────┬─────────────────────┘
         │ 2. Valida dados + salva foto (se houver)
         ↓
┌─────────────────┐
│ RefuelRepository│ (Domain - Interface)
└────────┬────────┘
         │ 3. Contract abstrato
         ↓
┌──────────────────────┐
│ RefuelRepositoryImpl │ (Data)
└────────┬─────────────┘
         │ 4. Usa RefuelDao
         ↓
┌────────────┐
│ RefuelDao  │ (Data - Drift DAO)
└────────┬───┘
         │ 5. INSERT/UPDATE SQL
         ↓
┌───────────┐
│ SQLite DB │ (Infrastructure)
└───────────┘
```

### Fluxo típico (cálculo de consumo)

```md
┌──────────────────┐
│ VehicleDetailScreen│  (UI)
└────────┬───────────┘
         │ 1. Solicita consumo médio
         ↓
┌──────────────────────────┐
│ CalculateConsumptionCommand│ (Application)
└────────┬─────────────────┘
         │ 2. Busca últimos 2+ abastecimentos
         ↓
┌─────────────────┐
│ RefuelRepository│ (Domain)
└────────┬────────┘
         │ 3. getRefuelsByVehicle(vehicleId)
         ↓
┌──────────────────────┐
│ RefuelRepositoryImpl │ (Data)
└────────┬─────────────┘
         │ 4. Mapeia dados
         ↓
┌──────────────────────────┐
│ CalculateConsumptionCommand│
└────────┬─────────────────┘
         │ 5. Aplica fórmula: ΔKm / ΣLitros
         └→ Retorna consumo médio (km/L)
```

**Regras de separação de responsabilidades:**

- **Presentation**: Exibe formulário, lista, gráficos de consumo
- **Commands**: Orquestram lógica (validação + storage + cálculos)
- **Domain**: Define contratos e entidade (`RefuelEntity`)
- **Data**: Implementa persistência com Drift
- **Drift DAO**: Executa queries SQL com ordenação e filtros

---

## 3. Estrutura de pastas do domínio

```bash
lib/
├─ domain/
│  ├─ entities/
│  │  ├─ refuel.dart           # Entidade de domínio pura
│  │  └─ fuel_type.dart        # Enum compartilhado com Vehicle
│  └─ repositories/
│     └─ refuel_repository.dart  # Contrato (interface)
│
├─ data/
│  ├─ local/
│  │  ├─ dao/
│  │  │  ├─ refuel_dao.dart    # Drift DAO para abastecimentos
│  │  │  └─ refuel_dao.g.dart  # Gerado pelo build_runner
│  │  └─ tables/
│  │     └─ refuel_table.dart  # Definição da tabela
│  ├─ mappers/
│  │  └─ refuel_mapper.dart    # RefuelEntity ↔ RefuelTableData
│  └─ repositories/
│     └─ refuel_repository_impl.dart  # Implementação
│
├─ application/
│  └─ commands/
│     └─ refuel/
│        ├─ create_or_update_refuel_command.dart
│        ├─ delete_refuel_command.dart
│        ├─ load_refuels_by_vehicle_command.dart
│        └─ calculate_consumption_command.dart
│
└─ presentation/
   └─ screens/
      └─ refuel/
         ├─ refuel_list_screen.dart
         ├─ refuel_form_screen.dart
         └─ widgets/
            ├─ refuel_card.dart
            └─ consumption_chart.dart
```

### Papel de cada pasta

- **domain/entities**: `RefuelEntity` (imutável, sem lógica de negócio)
- **domain/repositories**: Contrato `RefuelRepository`
- **data/local/dao**: Queries SQL otimizadas (ordenação por data, filtro por veículo)
- **data/local/tables**: Definição da tabela com relacionamento FK para Vehicle
- **data/mappers**: Conversão entre Entity e TableData
- **application/commands**: Casos de uso + lógica de negócio (ex: cálculo de consumo)
- **presentation/screens**: UI de listagem, formulário e visualizações

### Boas práticas ao adicionar arquivos

✅ **Faça:**

- Mantenha `RefuelEntity` imutável
- Crie queries no DAO para ordenação cronológica (`ORDER BY refuel_date DESC`)
- Use `CalculateConsumptionCommand` para lógica de cálculo (não na UI)
- Armazene foto de recibo via `LocalPhotoStorage`
- Valide quilometragem crescente (novo abastecimento deve ter km > último)
- Use `Either<Failure, T>` para operações que podem falhar

❌ **Não faça:**

- Calcular consumo diretamente na UI
- Permitir quilometragem menor que o último abastecimento
- Fazer queries SQL fora do DAO
- Expor `RefuelTableData` (Drift) para Presentation
- Deletar abastecimento sem deletar foto de recibo

---

## 4. Dependências utilizadas no domínio

### `drift` (^2.28.1)

**Por quê:** ORM SQLite type-safe para persistência local  
**Quando usar:** Definir tabela `refuel`, criar DAO com queries  
**Quando não usar:** Diretamente na UI ou Domain

### `intl` (^0.20.2)

**Por quê:** Formatação de datas e valores monetários  
**Quando usar:** Exibir datas (`DateFormat`) e valores (`NumberFormat.currency`)  
**Quando não usar:** Para lógica de negócio (apenas apresentação)

### `uuid` (^4.5.1)

**Por quê:** Gerar IDs únicos para abastecimentos (offline-first)  
**Quando usar:** Criar novos abastecimentos  
**Quando não usar:** Para IDs que vêm do backend

### `image_picker` (^1.2.0)

**Por quê:** Capturar ou selecionar foto do recibo  
**Quando usar:** Encapsulado em `LocalPhotoStorage` ou Command  
**Quando não usar:** Diretamente na UI

### `dartz` (^0.10.1)

**Por quê:** Either monad para tratamento de erros  
**Quando usar:** Retornos de Commands e Repositories  
**Quando não usar:** Em entidades puras

---

## 5. Módulo "Commands" dentro do domínio "Refuel"

### O que oferece

Os Commands de Refuel oferecem **casos de uso testáveis** para gerenciar abastecimentos:

- **CreateOrUpdateRefuelCommand**: Cria ou atualiza abastecimento
- **DeleteRefuelCommand**: Deleta abastecimento e foto de recibo
- **LoadRefuelsByVehicleCommand**: Carrega histórico de abastecimentos por veículo
- **CalculateConsumptionCommand**: Calcula consumo médio (km/L)

### Abstrações expostas

Cada Command expõe:

- Método `call(...)` que executa a ação
- Retorno `Either<Failure, T>` para tratamento de erro
- Dependências injetadas (`RefuelRepository`, `LocalPhotoStorage`)

### Como consumir

✅ **Correto:**

```dart
final command = getIt<CreateOrUpdateRefuelCommand>();
final refuel = RefuelEntity(
  id: const Uuid().v4(),
  vehicleId: currentVehicle.id,
  refuelDate: DateTime.now(),
  fuelType: FuelType.gasoline,
  totalValue: 200.0,
  mileage: 50000,
  liters: 40.0,
  createdAt: DateTime.now(),
);

final result = await command.call(refuel);

result.fold(
  (failure) => showError(failure.message),
  (_) => navigateBack(),
);
```

❌ **Incorreto:**

```dart
// ❌ Calcular consumo na UI
final consumption = (mileage - lastMileage) / liters;

// ❌ Acessar repository direto da UI
final repo = getIt<RefuelRepository>();
await repo.createRefuel(refuel);
```

### Exemplos práticos

**Cálculo de consumo médio:**

```dart
final command = getIt<CalculateConsumptionCommand>();
final result = await command.call(vehicleId: vehicle.id);

result.fold(
  (failure) => Text('Não foi possível calcular'),
  (consumption) => Text('Média: ${consumption.toStringAsFixed(2)} km/L'),
);
```

**Registro com validação de quilometragem:**

```dart
class RefuelFormCubit extends Cubit<RefuelFormState> {
  final CreateOrUpdateRefuelCommand _saveCommand;
  final LoadRefuelsByVehicleCommand _loadCommand;

  Future<void> saveRefuel({
    required int mileage,
    required double liters,
    required double totalValue,
    String? receiptPath,
  }) async {
    // 1. Validar quilometragem crescente
    final lastRefuelsResult = await _loadCommand(vehicleId: currentVehicleId);
    
    lastRefuelsResult.fold(
      (failure) => emit(RefuelFormError(failure.message)),
      (refuels) {
        if (refuels.isNotEmpty && mileage <= refuels.first.mileage) {
          emit(RefuelFormError('Quilometragem deve ser maior que ${refuels.first.mileage}'));
          return;
        }
        _proceedToSave(mileage, liters, totalValue, receiptPath);
      },
    );
  }

  Future<void> _proceedToSave(...) async {
    // 2. Salvar foto (se houver)
    // 3. Criar entidade
    // 4. Salvar no repositório
  }
}
```

---

## 6. Regras de negócio importantes

### Validações

- **Quilometragem deve ser crescente**: Novo abastecimento deve ter km > último abastecimento do veículo
- **Litros > 0**: Não permitir valores negativos ou zero
- **Valor total > 0**: Valor do abastecimento deve ser positivo
- **Data não pode ser futura**: `refuelDate <= DateTime.now()`
- **Tipo de combustível**: Deve corresponder aos tipos suportados pelo veículo (opcional)

### Restrições de fluxo

- Abastecimento pertence a um único veículo (`vehicleId`)
- Deletar veículo deve deletar todos os abastecimentos (cascade delete)
- Deletar abastecimento deve deletar foto de recibo (se houver)
- ID gerado localmente (UUID) para suporte offline

### Cálculo de consumo médio

**Fórmula:**

```
Consumo médio (km/L) = (km_atual - km_anterior) / litros_total
```

**Regras:**

- Requer no mínimo 2 abastecimentos
- Considerar apenas abastecimentos completos (tanque cheio)
- Se houver "partida a frio" (cold start), somar litros separadamente
- Ordenar por data crescente antes de calcular

**Exemplo:**

```
Abastecimento 1: 10.000 km, 40L
Abastecimento 2: 10.500 km, 35L
Consumo = (10.500 - 10.000) / 35 = 14.28 km/L
```

### Decisões arquiteturais

- **Drift é a única fonte de verdade local**
- **Cálculos sempre via Command** (não na UI)
- **Foreign Key para Vehicle**: Garantir integridade referencial
- **Ordenação padrão**: `ORDER BY refuel_date DESC` (mais recente primeiro)

### O que NÃO deve ser feito

❌ **Nunca:**

- Permitir quilometragem decrescente
- Calcular consumo com menos de 2 abastecimentos
- Fazer cálculos na UI (use `CalculateConsumptionCommand`)
- Expor `RefuelTableData` (Drift) para Presentation
- Deletar abastecimento sem deletar foto
- Usar `throw` para controle de fluxo (use Either)

---

## 7. Agente de IA especializado no domínio "Refuel"

# Agente Gasosa Refuel Specialist

Você é um **desenvolvedor mobile Flutter sênior**, especialista no **domínio de Abastecimentos (Refuel)** do **Gasosa App**.

## Conhecimento profundo

### Arquitetura

- Clean Architecture: Presentation → Application (Commands) → Domain → Data
- Offline-first com Drift (SQLite)
- Command Pattern para lógica de negócio (cálculos, validações)
- Mapper Pattern para isolamento de camadas
- Foreign Key para garantir integridade (vehicle_id)

### Regras de negócio

- **Quilometragem crescente**: Novo abastecimento deve ter km > último
- **Cálculo de consumo**: `(km_atual - km_anterior) / litros_total`
  - Mínimo 2 abastecimentos
  - Ordenação por data crescente
- **Validações**: liters > 0, totalValue > 0, refuelDate <= now
- **Cascade delete**: Deletar veículo = deletar abastecimentos
- **Foto de recibo**: Salvar localmente via `LocalPhotoStorage`

### Padrões adotados

- Entidades imutáveis (`RefuelEntity`)
- Contratos em Domain (`RefuelRepository`)
- Implementação em Data (`RefuelRepositoryImpl`)
- DAOs com queries otimizadas (`ORDER BY refuel_date DESC`)
- Mappers explícitos (`RefuelMapper`)
- Either para tratamento de erro
- GetIt para DI

## Responsabilidades

### Desenvolvimento

- Implementar CRUD de abastecimentos
- Adicionar campos (ex: posto, observações)
- Criar queries otimizadas (filtros, ordenação)
- Integrar upload de fotos de recibo
- Implementar gráficos de consumo ao longo do tempo
- Suporte a múltiplos tipos de combustível

### Refatoração

- Mover cálculos da UI para Commands
- Consolidar validações (quilometragem, datas)
- Otimizar queries com índices
- Garantir uso consistente de Mappers

### Testes

- Testar `CalculateConsumptionCommand` com diferentes cenários:
  - 2 abastecimentos
  - 3+ abastecimentos
  - Abastecimentos parciais vs completos
  - Edge cases (km negativo, litros zero)
- Testar validação de quilometragem crescente
- Testar cascade delete
- Testar Mappers

### Alertas

- ⚠️ Cálculo de consumo na UI (deveria estar em Command)
- ⚠️ Quilometragem não validada (permitindo valores decrescentes)
- ⚠️ Drift sendo importado fora de `data/`
- ⚠️ `RefuelTableData` exposta para Presentation
- ⚠️ Foto não sendo deletada ao deletar abastecimento
- ⚠️ Falta de ordenação cronológica nas queries

## Prioridades

1. **Clareza**: Cálculos explícitos e testáveis
2. **Testabilidade**: Lógica isolada em Commands
3. **Baixo acoplamento**: Domain não conhece Drift
4. **Consistência**: Sempre validar quilometragem, sempre usar Either

## Comportamento

- **Quando solicitado a adicionar feature de análise:**
  1. Identificar se é cálculo ou visualização
  2. Cálculos → criar novo Command
  3. Visualização → criar widget em Presentation
  4. Sempre validar dados antes de calcular

- **Quando identificar query lenta:**
  1. Verificar índices na tabela Drift (`refuel_date`, `vehicle_id`)
  2. Otimizar query no DAO
  3. Considerar paginação se histórico for grande

- **Nunca:**
  - Fazer cálculos na UI
  - Permitir quilometragem decrescente
  - Expor Drift para fora de Data
  - Quebrar cascade delete

---

Você é um **copilot técnico interno do Gasosa App**, focado em manter a integridade do domínio Refuel e garantir cálculos precisos de consumo.
