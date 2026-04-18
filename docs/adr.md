# Decisões Arquiteturais (ADR)

**Architecture Decision Records do Gasosa App**

Este documento registra as principais decisões arquiteturais tomadas no projeto, o contexto de cada decisão, alternativas consideradas e consequências.

---

## ADR-001: Clean Architecture como padrão arquitetural

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos de uma arquitetura que garanta:

- Testabilidade alta
- Baixo acoplamento entre camadas
- Facilidade de manutenção a longo prazo
- Independência de frameworks (Firebase, Drift, etc.)

### Decisão

Adotar **Clean Architecture** com 4 camadas:

1. **Presentation**: UI e state management
2. **Application**: Commands (casos de uso)
3. **Domain**: Entidades e contratos
4. **Data**: Implementações concretas

### Alternativas consideradas

- **MVC tradicional**: Descartado por falta de separação clara
- **MVVM puro**: Insuficiente para lógica de negócio complexa
- **Feature-first sem camadas**: Dificulta reutilização e testes

### Consequências

✅ **Positivas:**

- Código altamente testável (Commands mockáveis)
- Domain isolado de frameworks
- Fácil trocar implementações (ex: Drift → Hive)

❌ **Negativas:**

- Mais arquivos e boilerplate inicial
- Curva de aprendizado para novos desenvolvedores

---

## ADR-002: Command Pattern para casos de uso

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos orquestrar lógica de negócio (validações, múltiplas chamadas de repositório, etc.) de forma reutilizável e testável, sem poluir a UI.

### Decisão

Criar **Commands** na camada Application:

```dart
class CreateVehicleCommand {
  final VehicleRepository _repository;
  
  Future<Either<Failure, Unit>> call(VehicleEntity entity) async {
    // Validações + lógica + persistência
  }
}
```

### Alternativas consideradas

- **Use Cases diretos**: Similar, mas nome menos descritivo
- **Services**: Tendência a acumular muitas responsabilidades
- **Lógica na UI**: Dificulta testes e reutilização

### Consequências

✅ **Positivas:**

- Lógica isolada e testável
- Reutilização entre diferentes telas
- Naming claro e descritivo

❌ **Negativas:**

- Mais arquivos (1 por ação)

---

## ADR-003: Drift (SQLite) como fonte de verdade local

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

App precisa funcionar **offline-first**. Usuário deve conseguir registrar abastecimentos sem conexão.

### Decisão

Usar **Drift** como ORM e SQLite como banco local:

- Queries type-safe
- Suporte a Streams reativos
- Migrations automáticas
- Geração de código com `build_runner`

### Alternativas consideradas

- **Hive**: Mais simples, mas sem SQL e relações complexas
- **sqflite**: Muito boilerplate, queries string-based
- **Isar**: Performance alta, mas menos maduro

### Consequências

✅ **Positivas:**

- Queries type-safe (erros em compile-time)
- Suporte a relações (FK, JOIN)
- Streams reativos para UI
- Performance excelente

❌ **Negativas:**

- Build time mais lento (code generation)
- Curva de aprendizado (sintaxe Drift)

---

## ADR-004: Either monad (dartz) para error handling

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos de tratamento de erros previsível e explícito, sem `try/catch` espalhados por todo código.

### Decisão

Usar **Either<Failure, T>** (dartz) para operações que podem falhar:

```dart
Future<Either<Failure, VehicleEntity>> getVehicle(String id);
```

### Alternativas consideradas

- **Exceptions tradicionais**: Fluxo implícito, dificulta rastreamento
- **Result class custom**: Reinventar a roda
- **Nullable + error codes**: Não force erro handling

### Consequências

✅ **Positivas:**

- Erros explícitos na assinatura
- Força tratamento (não dá pra ignorar)
- Padrão funcional consistente

❌ **Negativas:**

- Dependência externa (dartz)
- Curva de aprendizado (fold, map, flatMap)

---

## ADR-005: Failure hierarchy para erros semânticos

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos diferenciar tipos de erro para tratamento específico na UI (ex: erro de rede vs validação).

### Decisão

Criar hierarquia de **Failures**:

```dart
abstract class Failure { ... }
class DatabaseFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
class AuthFailure extends Failure { ... }
```

### Alternativas consideradas

- **Exception hierarchy**: Similar, mas usa throw/catch
- **Error codes**: Menos type-safe
- **Failure genérico**: Não permite tratamento específico

### Consequências

✅ **Positivas:**

- Tratamento específico por tipo de erro
- Type-safe (pattern matching)
- Mensagens de erro semânticas

❌ **Negativas:**

- Mais classes a manter

---

## ADR-006: GetIt para Dependency Injection

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos de DI para desacoplar dependências e facilitar testes (mocks).

### Decisão

Usar **GetIt** (Service Locator):

```dart
getIt.registerFactory(() => CreateVehicleCommand(
  repository: getIt<VehicleRepository>(),
));
```

### Alternativas consideradas

- **Provider**: Mais acoplado à UI
- **Riverpod**: Requer refactor grande
- **Injectable**: Code generation, overhead adicional
- **Manual DI**: Muito boilerplate

### Consequências

✅ **Positivas:**

- Simples e direto
- Suporte a singleton, factory, lazy
- Fácil mockar para testes

❌ **Negativas:**

- Não detecta dependências circulares em compile-time
- Service Locator é anti-pattern para alguns (preferem Constructor Injection)

---

## ADR-007: Firebase Auth como provedor de autenticação

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos de autenticação confiável com suporte a email/senha e OAuth (Google).

### Decisão

Usar **Firebase Auth**:

- Email/senha nativo
- Google Sign-In
- Sessão gerenciada automaticamente

### Alternativas consideradas

- **Supabase**: Mais controle, mas requer backend
- **Auth custom**: Muito trabalho, risco de segurança
- **AWS Amplify**: Mais complexo

### Consequências

✅ **Positivas:**

- Autenticação robusta e segura
- Suporte a múltiplos providers
- Sessão gerenciada automaticamente
- Gratuito até certo uso

❌ **Negativas:**

- Vendor lock-in (Firebase)
- Limites de quota no free tier

---

## ADR-008: Offline-first com sincronização futura

**Data:** 2026-01  
**Status:** ✅ Aceito (parcial)

### Contexto

App deve funcionar sem internet, mas no futuro precisará sincronizar dados entre dispositivos.

### Decisão

- **Fase 1 (atual)**: Offline-first puro (Drift local)
- **Fase 2 (futura)**: Sync com backend (Firebase/Supabase)

IDs gerados localmente (UUID) para preparar sync.

### Alternativas consideradas

- **Cloud-first**: Não funciona offline
- **Firestore offline**: Sync automático, mas menos controle

### Consequências

✅ **Positivas:**

- Funciona 100% offline (MVP)
- Preparado para sync (UUID)
- Performance local excelente

❌ **Negativas:**

- Dados não compartilhados entre dispositivos (ainda)
- Backup manual (exportar dados)

---

## ADR-009: GoRouter para navegação

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos de navegação declarativa, type-safe e com suporte a deep links.

### Decisão

Usar **GoRouter**:

```dart
GoRoute(
  path: '/vehicle/:id',
  builder: (context, state) => VehicleDetailScreen(
    vehicleId: state.pathParameters['id']!,
  ),
),
```

### Alternativas consideradas

- **Navigator 1.0**: Imperativo, menos type-safe
- **AutoRoute**: Code generation, overhead
- **Beamer**: Menos popular

### Consequências

✅ **Positivas:**

- Navegação declarativa
- Deep links nativos
- Guarda de rotas (auth check)
- Integração com web

❌ **Negativas:**

- Curva de aprendizado (rotas declarativas)

---

## ADR-010: Flavors (dev/prod) com Flavorizr

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos de ambientes separados (dev e prod) com Firebase projects distintos.

### Decisão

Usar **Flavorizr** para automação:

- `main_dev.dart` + Firebase Dev
- `main_prod.dart` + Firebase Prod

### Alternativas consideradas

- **Manual setup**: Muito erro, difícil manter
- **Build modes apenas**: Não separa Firebase projects
- **Dotenv**: Não funciona bem para native (Android/iOS)

### Consequências

✅ **Positivas:**

- Setup automatizado
- Firebase projects isolados
- Fácil adicionar novos flavors

❌ **Negativas:**

- Dependência de ferramenta externa
- Build configs complexos

---

## ADR-011: Mappers explícitos entre camadas

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Precisamos isolar camadas e evitar vazamento de tipos de infraestrutura (Drift, Firebase) para camadas superiores.

### Decisão

Criar **Mappers** explícitos:

```dart
class VehicleMapper {
  static VehicleEntity toDomain(VehicleTableData data) { ... }
  static VehicleCompanion toCompanion(VehicleEntity entity) { ... }
}
```

### Alternativas consideradas

- **Auto-mappers (json_serializable)**: Menos controle
- **Conversão inline**: Código duplicado
- **Entidade = TableData**: Vazamento de camada

### Consequências

✅ **Positivas:**

- Isolamento total entre camadas
- Fácil trocar implementação (Drift → Hive)
- Lógica de conversão centralizada

❌ **Negativas:**

- Boilerplate adicional

---

## ADR-012: Validações reutilizáveis em Core

**Data:** 2026-01  
**Status:** ✅ Aceito

### Contexto

Validações (email, password, placa) são repetidas em múltiplos lugares.

### Decisão

Centralizar validators em **Core**:

```dart
class Validators {
  static Either<Failure, String> email(String? value) { ... }
  static Either<Failure, String> password(String? value) { ... }
}
```

### Alternativas consideradas

- **Validações inline na UI**: Código duplicado
- **Form validators locais**: Não reutilizáveis
- **Lib externa (validatorless)**: Apenas para UI simples

### Consequências

✅ **Positivas:**

- Reutilização total
- Consistência (mesmas regras)
- Testável isoladamente

❌ **Negativas:**

- Core cresce com o tempo (gerenciar bem)

---

## Resumo das Decisões

| ADR | Decisão | Status |
|-----|---------|--------|
| 001 | Clean Architecture | ✅ Aceito |
| 002 | Command Pattern | ✅ Aceito |
| 003 | Drift (SQLite) | ✅ Aceito |
| 004 | Either monad | ✅ Aceito |
| 005 | Failure hierarchy | ✅ Aceito |
| 006 | GetIt (DI) | ✅ Aceito |
| 007 | Firebase Auth | ✅ Aceito |
| 008 | Offline-first | ✅ Aceito (parcial) |
| 009 | GoRouter | ✅ Aceito |
| 010 | Flavorizr | ✅ Aceito |
| 011 | Mappers explícitos | ✅ Aceito |
| 012 | Validators em Core | ✅ Aceito |
| 013 | Estratégia de sincronização multi-dispositivo | 🔵 Proposto |

---

## ADR-013: Estratégia de sincronização multi-dispositivo

**Data:** 2026-04  
**Status:** 🔵 Proposto

### Contexto

O app é atualmente **offline-first puro**: todos os dados (veículos, abastecimentos, fotos) residem exclusivamente no SQLite local via Drift. O Firebase Auth já garante identidade do usuário em qualquer dispositivo, mas os dados não o seguem.

Para que um usuário acesse seus dados em um segundo dispositivo (tablet, smartphone novo, troca de aparelho), é necessário sincronizar os dados estruturados e os arquivos de mídia com uma fonte remota.

**Restrições identificadas na arquitetura atual:**

- `photoPath` e `receiptPath` são caminhos absolutos do filesystem local — inválidos em outros dispositivos
- Deletes são físicos (`DELETE FROM`) — incompatível com sync distribuído (o peer remoto não sabe que o registro foi apagado)
- `VehicleRepository` e `RefuelRepository` só conhecem o DAO local — sem abstração de fonte remota
- IDs já são UUIDs gerados localmente — **ponto positivo**, sem risco de colisão
- `updatedAt` existe nas três tabelas — base para resolução de conflito

### Decisão

Adotar a estratégia **Push/Pull com Firestore + last-write-wins**, implementada em três fases incrementais:

#### Fase 1 — Fundação de sync (dados estruturados)

1. **Soft delete**: Adicionar coluna `deletedAt DATETIME NULL` em `Vehicles` e `Refuels`; todos os hard deletes são convertidos para `UPDATE SET deletedAt = NOW()`; todas as queries de leitura adicionam `WHERE deletedAt IS NULL`
2. **Remote datasources**: Criar adaptadores Firestore para `Vehicle` e `Refuel` na camada `data/remote/`
3. **Repository dual-source**: `VehicleRepositoryImpl` e `RefuelRepositoryImpl` passam a orquestrar local + remote sem que os use cases saibam
4. **SyncUseCase**: Ao login → pull Firestore → merge local usando last-write-wins por `updatedAt`; ao escrever/deletar → push assíncrono em background

#### Fase 2 — Sincronização de mídia

1. Adicionar colunas `cloudPhotoUrl` e `cloudReceiptUrl` nas tabelas
2. Upload para **Firebase Storage** ao salvar foto/comprovante; armazenar a URL junto com o path local
3. Na leitura: exibir arquivo local se existir, senão baixar pela URL remota (cache local após download)

#### Fase 3 — Sync em tempo real (opcional, pós-MVP)

1. Substituir pull-on-login por `Firestore.snapshots()` stream
2. Mutações remotas refletem automaticamente no Drift local

#### Resolução de conflitos

Política: **last-write-wins por `updatedAt`**. Se dois dispositivos editam o mesmo registro offline, prevalece o timestamp mais recente. Não há notificação ao usuário. Adequado porque:
- Usuário único (sem colaboração em tempo real)
- Dados de abastecimento raramente são editados após criação
- Complexidade de merge por campo não justifica o custo no MVP

#### Mudanças que o domínio **não** sofre

As interfaces `VehicleRepository` e `RefuelRepository` **permanecem sem alteração**. Toda a orquestração de sync fica na camada `data`. Os use cases e a UI são agnósticos à existência de sincronização.

### Alternativas consideradas

| Alternativa | Por que descartada |
|---|---|
| **Firestore como fonte primária (cloud-first)** | App deixa de funcionar offline — viola requisito fundamental |
| **Supabase + PostgreSQL remoto** | Requer backend HTTP próprio; Firebase já está no projeto |
| **CRDT / Event sourcing** | Garante merge perfeito sem conflito, mas complexidade muito alta para app de usuário único sem colaboração |
| **Backup/restore manual (exportar JSON)** | UX ruim; não é sync automático |
| **Firestore offline cache automático** | Menos controle sobre quando/como sync ocorre; comportamento difícil de debugar |

### Consequências

✅ **Positivas:**

- Domain e Application imutáveis — risco de regressão mínimo
- Fases independentes: Fase 1 já entrega valor sem resolver fotos
- IDs UUID já preparados — sem migração de IDs
- `updatedAt` já existe — base de conflito pronta
- Funciona offline-first preservado durante toda a migração

❌ **Negativas:**

- Schema migration (Drift) necessária para `deletedAt`, `cloudPhotoUrl`, `cloudReceiptUrl` — requer atenção em produção
- Hard deletes físicos existentes precisam ser auditados e convertidos (vehicles, refuels, user cleanup)
- Firebase Storage introduz custo financeiro proporcional a armazenamento + banda de fotos
- Primeira sync de um dispositivo com muitos dados pode ser lenta (migração push-all)
- `last-write-wins` pode perder uma edição em cenários de edição simultânea offline — aceitável para o perfil de uso atual

### Dependências a adicionar (Fase 1)

```yaml
cloud_firestore: ^5.x.x
```

### Dependências a adicionar (Fase 2)

```yaml
firebase_storage: ^12.x.x
```

---

## Como propor nova ADR

1. Criar issue discutindo contexto e alternativas
2. Obter consenso do time
3. Adicionar ADR aqui (numeração sequencial)
4. Atualizar código conforme decisão
5. Documentar em domínio relevante

---

**Última atualização:** Abril 2026
