# Documentação do Gasosa App

**Aplicativo mobile Flutter para registro e análise de abastecimentos de veículos pessoais**

---

## Visão Geral

O **Gasosa App** é um aplicativo desenvolvido em **Flutter** seguindo os princípios de **Clean Architecture** e **DDD light**. A arquitetura prioriza:

- **Separação clara de responsabilidades** (Presentation → Application → Domain → Data)
- **Offline-first** com Drift (SQLite)
- **Testabilidade** (Commands mockáveis, repositórios abstratos)
- **Baixo acoplamento** (Domain não conhece frameworks)
- **Tratamento funcional de erros** (Either monad com dartz)

---

## Estrutura do Projeto

```bash
lib/
├─ domain/           # Entidades e contratos (interfaces)
├─ data/             # Implementações (Drift, Firebase, etc.)
├─ application/      # Commands (casos de uso)
├─ presentation/     # UI (screens, widgets, state management)
├─ core/             # Infraestrutura compartilhada
└─ theme/            # Tema e estilos
```

---

## Domínios Documentados

### 1. [Auth (Autenticação)](./domain-auth.md)

Gerencia autenticação de usuários (email/senha, Google Sign-In), sessão e logout.

**Principais responsabilidades:**

- Login e registro de usuários
- Autenticação social (Google)
- Gerenciamento de sessão com Firebase Auth

**Commands principais:**

- `LoginEmailPasswordCommand`
- `LoginWithGoogleCommand`
- `RegisterCommand`

---

### 2. [Vehicle (Veículos)](./domain-vehicle.md)

Gerencia CRUD de veículos (cadastro, edição, listagem, exclusão) e armazenamento de fotos.

**Principais responsabilidades:**

- Cadastro de múltiplos veículos por usuário
- Persistência offline-first com Drift
- Upload e armazenamento de fotos locais
- Listagem reativa com Streams

**Commands principais:**

- `CreateOrUpdateVehicleCommand`
- `DeleteVehicleCommand`
- `LoadVehiclesCommand`

---

### 3. [Refuel (Abastecimentos)](./domain-refuel.md)

Gerencia registro de abastecimentos, cálculo de consumo médio e armazenamento de comprovantes.

**Principais responsabilidades:**

- Registro detalhado de abastecimentos (data, litros, valor, km)
- Cálculo automático de consumo médio (km/L)
- Histórico por veículo com ordenação cronológica
- Armazenamento de fotos de recibos

**Commands principais:**

- `CreateOrUpdateRefuelCommand`
- `DeleteRefuelCommand`
- `LoadRefuelsByVehicleCommand`
- `CalculateConsumptionCommand`

---

### 4. [Core (Infraestrutura Compartilhada)](./domain-core.md)

Fornece infraestrutura compartilhada, utilitários e abstrações fundamentais.

**Principais responsabilidades:**

- Tratamento de erros (`Failure` hierarchy)
- Validações reutilizáveis (`Validators`)
- Extensions para tipos nativos
- Injeção de dependências (GetIt)
- Helpers e formatters

**Módulos principais:**

- `errors/` - Hierarquia de Failures
- `validators/` - Validações reutilizáveis
- `extensions/` - Extensions para String, DateTime, num
- `di/` - Configuração de injeção de dependências

---

## Princípios Arquiteturais

### 1. Clean Architecture

```md
┌─────────────────────────────────────────┐
│         Presentation Layer              │  ← UI, State Management
│  (Screens, Widgets, Cubits/BLoCs)       │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│         Application Layer               │  ← Use Cases (Commands)
│          (Commands)                     │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│           Domain Layer                  │  ← Entidades + Contratos
│   (Entities, Repositories)              │
└───────────────┬─────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│            Data Layer                   │  ← Implementações
│  (Repository Impl, DAOs, Mappers)       │
└─────────────────────────────────────────┘
```

**Regra de dependência:** Camadas externas dependem de camadas internas. Domain não depende de ninguém.

---

### 2. Command Pattern

Cada ação de negócio é encapsulada em um **Command**:

```dart
class CreateVehicleCommand {
  final VehicleRepository _repository;
  
  Future<Either<Failure, Unit>> call(VehicleEntity entity) async {
    // Validações, lógica de negócio, orquestração
    return _repository.createVehicle(entity);
  }
}
```

**Benefícios:**

- Testável (mock do repository)
- Reutilizável
- Isolado da UI

---

### 3. Repository Pattern

Abstração de persistência:

```dart
// Domain (contrato)
abstract interface class VehicleRepository {
  Future<Either<Failure, Unit>> createVehicle(VehicleEntity vehicle);
  Future<Either<Failure, List<VehicleEntity>>> getAllByUserId(String userId);
}

// Data (implementação)
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleDao _dao;
  
  @override
  Future<Either<Failure, Unit>> createVehicle(VehicleEntity vehicle) async {
    // Implementação com Drift
  }
}
```

---

### 4. Either Monad (Error Handling)

Tratamento funcional de erros sem exceptions:

```dart
final result = await command.call(entity);

result.fold(
  (failure) => showError(failure.message),  // Left = erro
  (data) => navigateToSuccess(data),        // Right = sucesso
);
```

---

### 5. Offline-first com Drift

- **Drift (SQLite)** é a fonte de verdade local
- Suporte a Streams reativos
- Queries type-safe
- Migrations automáticas

---

## Stack Tecnológica

### Principais Dependências

| Dependência | Versão | Uso |
| ------------ | -------- | ----- |
| `drift` | ^2.28.1 | ORM SQLite (persistência local) |
| `firebase_auth` | ^6.0.1 | Autenticação (email/senha, Google) |
| `google_sign_in` | ^7.1.1 | Autenticação Google OAuth |
| `go_router` | ^16.2.0 | Navegação declarativa |
| `get_it` | ^8.2.0 | Injeção de dependências (Service Locator) |
| `dartz` | ^0.10.1 | Either monad (error handling) |
| `uuid` | ^4.5.1 | Geração de IDs únicos (offline-first) |
| `image_picker` | ^1.2.0 | Captura/seleção de fotos |
| `intl` | ^0.20.2 | Formatação (datas, valores) |

---

## Padrões de Código

### ✅ Boas Práticas

1. **Sempre use Either para operações que podem falhar**

   ```dart
   Future<Either<Failure, VehicleEntity>> getVehicle(String id);
   ```

2. **Entidades imutáveis**

   ```dart
   class VehicleEntity {
     final String id;
     final String name;
     // Sem setters, apenas final fields
   }
   ```

3. **Commands para orquestração**

   ```dart
   // ✅ Command orquestra validação + storage + persistência
   final result = await CreateVehicleCommand(repository, photoStorage).call(entity);
   ```

4. **Mappers explícitos entre camadas**

   ```dart
   // VehicleEntity (domain) ↔ VehicleTableData (Drift)
   class VehicleMapper {
     static VehicleEntity toDomain(VehicleTableData data) { ... }
     static VehicleCompanion toCompanion(VehicleEntity entity) { ... }
   }
   ```

5. **Validators reutilizáveis**

   ```dart
   final emailResult = Validators.email(emailController.text);
   ```

---

### ❌ Anti-padrões

1. **Lógica de negócio na UI**

   ```dart
   // ❌ Calcular consumo na UI
   final consumption = (mileage - lastMileage) / liters;
   
   // ✅ Usar Command
   final result = await CalculateConsumptionCommand().call(vehicleId);
   ```

2. **Acessar repositório direto da UI**

   ```dart
   // ❌ Repository na UI
   final repo = getIt<VehicleRepository>();
   await repo.createVehicle(vehicle);
   
   // ✅ Usar Command
   final command = getIt<CreateVehicleCommand>();
   await command.call(vehicle);
   ```

3. **Expor tipos de Data para Presentation**

   ```dart
   // ❌ Expor VehicleTableData (Drift) para UI
   Stream<List<VehicleTableData>> watchVehicles();
   
   // ✅ Retornar Entity (domain)
   Stream<Either<Failure, List<VehicleEntity>>> watchVehicles();
   ```

4. **Usar throw para controle de fluxo**

   ```dart
   // ❌ Lançar exception
   if (name.isEmpty) throw ValidationException('Nome obrigatório');
   
   // ✅ Retornar Either
   if (name.isEmpty) return left(ValidationFailure('Nome obrigatório'));
   ```

---

## Testes

### Estratégia de Testes

| Tipo | O que testar | Ferramenta |
| ------ | ------------- | ------------ |
| **Unit** | Commands, Validators, Mappers, Helpers | `flutter_test` + `mocktail` |
| **Widget** | Widgets isolados, estados | `flutter_test` |
| **Integration** | Fluxos completos (ex: criar veículo + abastecimento) | `integration_test` |

### Exemplo: Testar Command

```dart
void main() {
  late MockVehicleRepository mockRepo;
  late CreateVehicleCommand command;

  setUp(() {
    mockRepo = MockVehicleRepository();
    command = CreateVehicleCommand(repository: mockRepo);
  });

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
}
```

---

## Contribuindo

### Adicionando novo domínio

1. Criar entidades em `domain/entities/`
2. Definir contratos (repositories) em `domain/repositories/`
3. Implementar em `data/repositories/`
4. Criar Commands em `application/commands/`
5. Desenvolver UI em `presentation/screens/`
6. Documentar seguindo template dos domínios existentes

### Adicionando nova feature em domínio existente

1. Identificar camadas afetadas
2. Atualizar entidades (se necessário)
3. Criar/atualizar Commands
4. Atualizar Repository (contrato + implementação)
5. Atualizar UI
6. Adicionar testes

---

## Flavors (Ambientes)

O projeto suporta **2 flavors**:

- **dev**: Ambiente de desenvolvimento (Firebase Dev)
- **prod**: Ambiente de produção (Firebase Prod)

### Comandos para build

```bash
# Dev
flutter run --flavor dev -t lib/main_dev.dart

# Prod
flutter run --flavor prod -t lib/main_prod.dart
```

---

## Agentes de IA Especializados

Cada domínio possui um **agente de IA especializado** que atua como **copilot técnico**:

- **[Auth Specialist](./domain-auth.md#7-agente-de-ia-especializado-no-domínio-auth)**: Especialista em autenticação
- **[Vehicle Specialist](./domain-vehicle.md#7-agente-de-ia-especializado-no-domínio-vehicle)**: Especialista em veículos
- **[Refuel Specialist](./domain-refuel.md#7-agente-de-ia-especializado-no-domínio-refuel)**: Especialista em abastecimentos
- **[Core Specialist](./domain-core.md#9-agente-de-ia-especializado-no-domínio-core)**: Especialista em infraestrutura compartilhada

Esses agentes conhecem profundamente a arquitetura, regras de negócio e padrões adotados, podendo:

- Desenvolver novas funcionalidades
- Refatorar código
- Sugerir testes
- Alertar sobre violações arquiteturais

---

## Licença

Este projeto está sob licença MIT. Veja o arquivo [LICENSE](../LICENSE) para mais detalhes.

---

## Contato

Para dúvidas ou sugestões, entre em contato com o time de desenvolvimento.
