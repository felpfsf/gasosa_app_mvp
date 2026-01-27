# Domínio: Core (Infraestrutura Compartilhada)

## 1. Visão geral do domínio "Core"

### Responsabilidade

O domínio **Core** fornece infraestrutura compartilhada, utilitários e abstrações fundamentais utilizadas por todos os outros domínios do Gasosa App. É a **camada de fundação** que garante consistência, reutilização e baixo acoplamento.

### Problemas que resolve

- Centralizar tratamento de erros (`Failure` hierarchy)
- Fornecer abstrações funcionais (`Either` para error handling)
- Prover utilitários de validação, formatação e extensões
- Gerenciar injeção de dependências (DI)
- Definir ViewModels base para UI
- Padronizar helpers e extensions

### Relacionamento com outros domínios

- **Auth**: Usa `Either`, `Failure`, validators, DI
- **Vehicle**: Usa `Either`, `Failure`, formatters, DI
- **Refuel**: Usa `Either`, `Failure`, validators, formatters, DI
- **User**: Usa `Either`, `Failure`, DI

**Importante:** Core **não depende** de nenhum domínio. Todos os domínios **dependem** de Core.

---

## 2. Arquitetura utilizada no domínio

### Camadas

Core é **horizontal** e perpassa todas as camadas verticais:

```md
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (usa ViewModels, Extensions, Helpers)  │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│         Application Layer               │
│    (usa Either, Validators, Helpers)    │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│           Domain Layer                  │
│      (usa Either, Failure, DI)          │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│            Data Layer                   │
│    (usa Failure, Mappers, Helpers)      │
└─────────────────────────────────────────┘
            ↑
         ┌──┴──┐
         │CORE │ ← Transversal a todas as camadas
         └─────┘
```

### Padrões aplicados

- **Either monad (dartz)**: Tratamento funcional de erros sem exceptions
- **Failure hierarchy**: Hierarquia de erros semânticos (DatabaseFailure, NetworkFailure, ValidationFailure)
- **Service Locator (GetIt)**: Injeção de dependências
- **Extension methods**: Adicionar funcionalidades a tipos existentes (String, DateTime, etc.)
- **Validators**: Validações reutilizáveis (email, password, plate, etc.)
- **Helpers**: Funções puras utilitárias (formatações, conversões)

### Fluxo típico de uso

```md
┌─────────────────────┐
│ CreateVehicleCommand│  (Application)
└──────────┬──────────┘
           │ 1. Valida nome com Validators
           ↓
┌──────────────────┐
│ Validators.name  │  (Core)
└──────────────────┘
           │ 2. Se inválido, retorna ValidationFailure
           ↓
┌──────────────────┐
│ Either<Failure, T>│  (Core - dartz)
└──────────────────┘
```

**Regras de separação de responsabilidades:**

- **Core não contém regras de domínio** (ex: cálculo de consumo)
- **Core fornece primitivas reutilizáveis** (validators, formatters, errors)
- **Core não conhece detalhes de implementação** (Firebase, Drift, etc.)

---

## 3. Estrutura de pastas do domínio

```bash
lib/
└─ core/
   ├─ di/
   │  ├─ injection.dart           # Setup de injeção de dependências (GetIt)
   │  └─ injection.config.dart    # Gerado por injectable (se usado)
   │
   ├─ either/
   │  └─ either_extensions.dart   # Extensions para Either<Failure, T>
   │
   ├─ errors/
   │  ├─ failure.dart             # Classe base Failure
   │  ├─ database_failure.dart    # Erros de persistência
   │  ├─ network_failure.dart     # Erros de rede
   │  ├─ validation_failure.dart  # Erros de validação
   │  └─ auth_failure.dart        # Erros de autenticação
   │
   ├─ extensions/
   │  ├─ string_extensions.dart   # Extensions para String
   │  ├─ datetime_extensions.dart # Extensions para DateTime
   │  └─ num_extensions.dart      # Extensions para num/int/double
   │
   ├─ helpers/
   │  ├─ formatters.dart          # Formatação (datas, valores, km)
   │  ├─ converters.dart          # Conversões (String → int, etc.)
   │  └─ constants.dart           # Constantes globais
   │
   ├─ validators/
   │  ├─ email_validator.dart
   │  ├─ password_validator.dart
   │  ├─ plate_validator.dart     # Placa brasileira
   │  └─ common_validators.dart   # Validações genéricas
   │
   └─ viewmodel/
      └─ base_view_model.dart     # ViewModel base (se usado padrão MVVM)
```

### Papel de cada pasta

- **di/**: Configuração de injeção de dependências (GetIt, injectable)
- **either/**: Extensions para facilitar uso de Either (ex: `getOrElse`, `mapLeft`)
- **errors/**: Hierarquia de erros semânticos (Failure e subclasses)
- **extensions/**: Métodos auxiliares para tipos nativos (String, DateTime, etc.)
- **helpers/**: Funções puras utilitárias (formatações, conversões)
- **validators/**: Validações reutilizáveis com retorno `Either<Failure, T>`
- **viewmodel/**: Classes base para ViewModels (se aplicável)

### Boas práticas ao adicionar arquivos

✅ **Faça:**

- Crie validators reutilizáveis (não valide inline na UI)
- Use Failure semântico (não genéricos tipo `Exception`)
- Adicione extensions para eliminar código repetitivo
- Mantenha helpers como funções puras (sem side-effects)
- Documente constantes importantes

❌ **Não faça:**

- Colocar regras de negócio em Core (isso é responsabilidade do Domain)
- Referenciar domínios específicos (Auth, Vehicle, etc.) em Core
- Adicionar dependências pesadas (Firebase, Drift) em Core
- Usar `throw` em validators (retorne `Left(ValidationFailure(...))`)

---

## 4. Dependências utilizadas no domínio

### `dartz` (^0.10.1)

**Por quê:** Either monad para tratamento funcional de erros  
**Quando usar:** Retornos de validators, commands, repositories  
**Quando não usar:** Em entidades puras (são apenas dados)

### `get_it` (^8.2.0)

**Por quê:** Service Locator para injeção de dependências  
**Quando usar:** Registrar singletons, factories de Commands, Repositories, Services  
**Quando não usar:** Para passar estado entre telas (use navegação ou state management)

### `intl` (^0.20.2)

**Por quê:** Formatação de datas, valores e localização  
**Quando usar:** Helpers de formatação (datas, moeda)  
**Quando não usar:** Para lógica de negócio

### `validatorless` (^1.2.4)

**Por quê:** Validações de formulário (email, required, etc.)  
**Quando usar:** Validações simples de UI (TextFormField)  
**Quando não usar:** Para validações complexas de domínio (crie validators customizados)

---

## 5. Módulo "Errors (Failures)" dentro do domínio "Core"

### O que oferece

Hierarquia de erros semânticos para representar falhas em diferentes contextos.

**Hierarquia:**

```dart
abstract class Failure {
  final String message;
  final Object? cause;
  
  Failure(this.message, {this.cause});
}

class DatabaseFailure extends Failure {
  DatabaseFailure(String message, {Object? cause}) : super(message, cause: cause);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message, {Object? cause}) : super(message, cause: cause);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}

class AuthFailure extends Failure {
  AuthFailure(String message, {Object? cause}) : super(message, cause: cause);
}
```

### Como consumir

✅ **Correto:**

```dart
Future<Either<Failure, VehicleEntity>> getVehicle(String id) async {
  try {
    final data = await dao.getById(id);
    if (data == null) {
      return left(DatabaseFailure('Veículo não encontrado'));
    }
    return right(VehicleMapper.toDomain(data));
  } catch (e) {
    return left(DatabaseFailure('Erro ao buscar veículo', cause: e));
  }
}
```

❌ **Incorreto:**

```dart
// ❌ Lançar exception genérica
throw Exception('Veículo não encontrado');

// ❌ Usar Failure genérico
return left(Failure('Erro ao buscar veículo'));
```

### Exemplos práticos

**Tratamento na UI:**

```dart
result.fold(
  (failure) {
    if (failure is ValidationFailure) {
      showValidationError(failure.message);
    } else if (failure is NetworkFailure) {
      showNetworkError();
    } else {
      showGenericError(failure.message);
    }
  },
  (data) => showSuccess(data),
);
```

---

## 6. Módulo "Validators" dentro do domínio "Core"

### O que oferece

Validações reutilizáveis com retorno `Either<Failure, T>`.

### Abstrações expostas

```dart
class Validators {
  static Either<Failure, String> email(String? value) {
    if (value == null || value.isEmpty) {
      return left(ValidationFailure('Email é obrigatório'));
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return left(ValidationFailure('Email inválido'));
    }
    return right(value);
  }

  static Either<Failure, String> password(String? value) {
    if (value == null || value.isEmpty) {
      return left(ValidationFailure('Senha é obrigatória'));
    }
    if (value.length < 6) {
      return left(ValidationFailure('Senha deve ter no mínimo 6 caracteres'));
    }
    return right(value);
  }

  static Either<Failure, String> required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return left(ValidationFailure('$fieldName é obrigatório'));
    }
    return right(value.trim());
  }

  static Either<Failure, String> plateBR(String? value) {
    if (value == null || value.isEmpty) {
      return right(''); // Placa é opcional
    }
    // AAA-1234 ou AAA1B23 (Mercosul)
    final plateRegex = RegExp(r'^[A-Z]{3}-?\d{4}$|^[A-Z]{3}\d[A-Z]\d{2}$');
    if (!plateRegex.hasMatch(value.toUpperCase())) {
      return left(ValidationFailure('Placa inválida'));
    }
    return right(value.toUpperCase());
  }
}
```

### Como consumir

✅ **Correto:**

```dart
final emailResult = Validators.email(emailController.text);
final passwordResult = Validators.password(passwordController.text);

if (emailResult.isLeft() || passwordResult.isLeft()) {
  // Exibir erros
  return;
}

// Prosseguir com login
final email = emailResult.getOrElse(() => '');
final password = passwordResult.getOrElse(() => '');
```

❌ **Incorreto:**

```dart
// ❌ Validar inline na UI sem validator
if (email.isEmpty || !email.contains('@')) {
  showError('Email inválido');
}
```

---

## 7. Módulo "Extensions" dentro do domínio "Core"

### O que oferece

Métodos auxiliares para tipos nativos.

### Exemplos

```dart
// string_extensions.dart
extension StringExtensions on String {
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

// datetime_extensions.dart
extension DateTimeExtensions on DateTime {
  String get formatted {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

// num_extensions.dart
extension DoubleExtensions on double {
  String get toCurrency {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(this);
  }

  String toKmL(int decimals) {
    return '${toStringAsFixed(decimals)} km/L';
  }
}
```

### Como consumir

```dart
// ✅ Uso limpo com extensions
final formattedDate = refuel.refuelDate.formatted; // "27/01/2026"
final price = refuel.totalValue.toCurrency; // "R$ 200,00"
final consumption = 14.28.toKmL(2); // "14.28 km/L"
```

---

## 8. Regras de negócio importantes

### Validações

- **Core não contém validações de domínio** (ex: quilometragem crescente)
- **Core contém validações genéricas** (email, required, formato de placa)

### Restrições de fluxo

- Core **nunca depende** de domínios específicos (Auth, Vehicle, Refuel)
- Domínios **sempre dependem** de Core (inversão de dependência)
- Extensions devem ser **puras** (sem side-effects)

### Decisões arquiteturais

- **GetIt como Service Locator**: Evitar passar dependências manualmente
- **Either para error handling**: Eliminar try/catch desnecessários
- **Failure semântico**: Facilitar tratamento específico de erros
- **Validators retornam Either**: Consistência com resto do sistema

### O que NÃO deve ser feito

❌ **Nunca:**

- Adicionar regras de negócio em Core (isso é domínio)
- Referenciar Firebase, Drift ou qualquer lib de domínio específico
- Usar Failure genérico (sempre use subclasse semântica)
- Fazer extensions com side-effects (ex: salvar no banco)
- Colocar lógica de UI em Core (isso é Presentation)

---

## 9. Agente de IA especializado no domínio "Core"

# Agente Gasosa Core Specialist

Você é um **desenvolvedor mobile Flutter sênior**, especialista no **domínio Core (Infraestrutura Compartilhada)** do **Gasosa App**.

## Conhecimento profundo

### Arquitetura

- Core é **transversal** a todas as camadas
- Core **não depende** de nenhum domínio específico
- Todos os domínios **dependem** de Core
- Padrões: Either monad, Failure hierarchy, Service Locator (GetIt), Extensions

### Regras de negócio

- Core fornece **primitivas reutilizáveis**, não regras de domínio
- Validators genéricos (email, password, required)
- Failures semânticos (DatabaseFailure, NetworkFailure, ValidationFailure, AuthFailure)
- Extensions devem ser **puras** (sem side-effects)
- Helpers devem ser **funções puras**

### Padrões adotados

- Either para error handling
- Failure hierarchy para erros semânticos
- GetIt para DI
- Extensions para tipos nativos
- Validators com retorno `Either<Failure, T>`

## Responsabilidades

### Desenvolvimento

- Criar validators reutilizáveis
- Adicionar extensions úteis para eliminar código repetitivo
- Expandir hierarquia de Failures conforme necessário
- Criar helpers de formatação e conversão
- Configurar injeção de dependências (GetIt)

### Refatoração

- Consolidar validações duplicadas em validators reutilizáveis
- Extrair código repetitivo para extensions
- Padronizar tratamento de erros com Failures específicos
- Simplificar DI com GetIt

### Testes

- Testar validators com diferentes inputs (válidos, inválidos, edge cases)
- Testar extensions (formato, conversão)
- Validar hierarquia de Failures

### Alertas

- ⚠️ Regra de negócio em Core (deveria estar em Domain)
- ⚠️ Dependência de domínio específico em Core (Auth, Vehicle, etc.)
- ⚠️ Uso de Failure genérico (sempre use subclasse semântica)
- ⚠️ Extension com side-effect (deveria ser função pura)
- ⚠️ Validação inline na UI (deveria usar Validator de Core)

## Prioridades

1. **Reutilização**: Se algo se repete, vira extension ou helper
2. **Clareza**: Nomes descritivos (ValidationFailure, not GenericError)
3. **Testabilidade**: Funções puras, fáceis de testar
4. **Baixo acoplamento**: Core não conhece detalhes de domínio

## Comportamento

- **Quando solicitado a adicionar validator:**
  1. Verificar se já existe similar
  2. Criar em `validators/`
  3. Retornar `Either<Failure, T>`
  4. Adicionar testes

- **Quando solicitado a adicionar extension:**
  1. Verificar se não introduz side-effect
  2. Criar em `extensions/`
  3. Manter função pura
  4. Documentar uso

- **Quando identificar validação duplicada:**
  1. Extrair para validator em Core
  2. Refatorar domínios para usar validator centralizado

- **Nunca:**
  - Adicionar lógica de domínio em Core
  - Referenciar Firebase, Drift, etc. em Core
  - Criar extensions com side-effects
  - Usar Failure genérico

---

Você é um **copilot técnico interno do Gasosa App**, focado em manter Core limpo, reutilizável e livre de dependências de domínio.
