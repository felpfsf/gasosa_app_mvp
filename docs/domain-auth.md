# Domínio: Auth (Autenticação)

## 1. Visão geral do domínio "Auth"

### Responsabilidade

O domínio **Auth** é responsável por gerenciar todo o ciclo de vida da autenticação de usuários no Gasosa App, incluindo registro, login, logout e gerenciamento de sessão.

### Problemas que resolve

- Autenticação segura de usuários via email/senha
- Autenticação social (Google Sign-In)
- Persistência e validação de sessão do usuário
- Identificação do usuário autenticado para uso em outros domínios

### Relacionamento com outros domínios

- **User**: Auth fornece o `userId` necessário para criar e buscar dados do usuário
- **Vehicle**: Depende do `userId` autenticado para vincular veículos ao proprietário
- **Refuel**: Usa o `userId` indiretamente através do vínculo com veículos
- **Core**: Utiliza infraestrutura compartilhada (Failure, Either, DI)

---

## 2. Arquitetura utilizada no domínio

### Camadas

```md
Presentation Layer (UI)
       ↓
Application Layer (Commands)
       ↓
Domain Layer (Entities + Repository Contracts)
       ↓
Data Layer (Repository Impl + Firebase Services)
```

### Padrões aplicados

- **Clean Architecture**: Separação clara entre camadas, dependência sempre apontando para dentro (domain)
- **Command Pattern**: Cada ação de autenticação é encapsulada em um Command reutilizável
- **Repository Pattern**: Abstração da fonte de dados (Firebase Auth)
- **Either monad (dartz)**: Tratamento explícito de erros sem exceptions
- **Dependency Inversion**: Domain define contratos, Data implementa

### Fluxo típico

```md
┌─────────────┐
│ LoginScreen │  (UI)
└──────┬──────┘
       │ 1. Usuário insere email/senha
       ↓
┌──────────────────────────┐
│ LoginEmailPasswordCommand│ (Application)
└──────┬───────────────────┘
       │ 2. Valida e chama repository
       ↓
┌──────────────────┐
│ AuthRepository   │ (Domain - Interface)
└──────┬───────────┘
       │ 3. Contract abstrato
       ↓
┌──────────────────────┐
│ AuthRepositoryImpl   │ (Data)
└──────┬───────────────┘
       │ 4. Delega ao FirebaseAuthService
       ↓
┌──────────────────────┐
│ FirebaseAuthService  │ (Data - Infraestrutura)
└──────────────────────┘
```

**Regras de separação de responsabilidades:**

- UI **não** contém regras de negócio, apenas exibe estados e reage a interações
- Commands **orquestram** a lógica de aplicação, mas não conhecem detalhes de implementação
- Domain **define** o que o sistema deve fazer (contratos)
- Data **implementa** como o sistema faz (Firebase, APIs, etc.)

---

## 3. Estrutura de pastas do domínio

```bash
lib/
├─ domain/
│  ├─ entities/
│  │  └─ user.dart                    # Entidade de domínio pura
│  ├─ repositories/
│  │  └─ auth_repository.dart         # Contrato (interface)
│  └─ services/
│     ├─ auth_service.dart            # Contrato de serviço
│     └─ firebase_auth_service.dart   # ⚠️ Implementação (deveria estar em data/)
│
├─ data/
│  └─ repositories/
│     └─ auth_repository_impl.dart    # Implementação do repositório
│
├─ application/
│  └─ commands/
│     └─ auth/
│        ├─ login_email_password_command.dart
│        ├─ loggin_with_google_command.dart
│        └─ register_command.dart
│
└─ presentation/
   └─ screens/
      └─ auth/
         ├─ login_screen.dart
         ├─ register_screen.dart
         └─ widgets/
```

### Papel de cada pasta

- **domain/entities**: Objetos de domínio puros (sem dependências externas)
- **domain/repositories**: Contratos que a camada de dados deve implementar
- **domain/services**: Abstrações de serviços externos (Auth, Storage, etc.)
- **data/repositories**: Implementações concretas dos contratos de domínio
- **application/commands**: Casos de uso da aplicação, orquestradores de lógica
- **presentation/screens**: Telas e widgets da UI

### Boas práticas ao adicionar arquivos

✅ **Faça:**

- Crie entidades imutáveis no domain
- Use `Either<Failure, T>` para retornos que podem falhar
- Implemente repositórios em `data/`, não em `domain/`
- Crie Commands para orquestrar múltiplas chamadas de repositório
- Nomeie Commands com verbos: `LoginEmailPasswordCommand`, `RegisterCommand`

❌ **Não faça:**

- Colocar lógica de negócio na UI
- Implementar serviços concretos (Firebase, etc.) em `domain/`
- Acessar repositórios diretamente da UI (use Commands)
- Usar `throw` para controle de fluxo (use Either)

---

## 4. Dependências utilizadas no domínio

### `firebase_auth` (^6.0.1)

**Por quê:** Provedor de autenticação principal (email/senha, OAuth)  
**Quando usar:** Apenas na camada Data (implementação)  
**Quando não usar:** Nunca referenciar em Domain ou Presentation

### `google_sign_in` (^7.1.1)

**Por quê:** Autenticação via Google OAuth  
**Quando usar:** Encapsulado em `FirebaseAuthService` ou similar  
**Quando não usar:** Diretamente na UI

### `dartz` (^0.10.1)

**Por quê:** Either monad para tratamento funcional de erros  
**Quando usar:** Retornos de Commands e Repositories (`Either<Failure, T>`)  
**Quando não usar:** Em entidades (são apenas dados)

### `get_it` (^8.2.0)

**Por quê:** Injeção de dependências (Service Locator)  
**Quando usar:** Registro de Commands, Repositories e Services  
**Quando não usar:** Para passar estado entre telas (use navegação com parâmetros)

---

## 5. Módulo "Commands" dentro do domínio "Auth"

### O que oferece

Os Commands de Auth oferecem **casos de uso prontos e testáveis** para autenticação:

- **LoginEmailPasswordCommand**: Autentica usuário com email e senha
- **LoginWithGoogleCommand**: Autentica via Google Sign-In
- **RegisterCommand**: Registra novo usuário

### Abstrações expostas

Cada Command expõe:

- Método `call()` que executa a ação
- Retorno `Either<Failure, T>` para tratamento de erro
- Dependência injetada de `AuthRepository`

### Como consumir

✅ **Correto:**

```dart
final command = getIt<LoginEmailPasswordCommand>();
final result = await command.call(email: 'user@example.com', password: '123456');

result.fold(
  (failure) => // Exibir erro,
  (user) => // Navegar para home,
);
```

❌ **Incorreto:**

```dart
// ❌ Nunca instanciar manualmente
final command = LoginEmailPasswordCommand(repository: AuthRepositoryImpl(...));

// ❌ Nunca acessar repositório direto da UI
final repo = getIt<AuthRepository>();
await repo.loginWithEmail(...);
```

### Exemplos práticos

**Login com validação:**

```dart
class LoginCubit extends Cubit<LoginState> {
  final LoginEmailPasswordCommand _loginCommand;

  Future<void> login(String email, String password) async {
    emit(LoginLoading());
    
    final result = await _loginCommand(email, password);
    
    result.fold(
      (failure) => emit(LoginError(failure.message)),
      (user) => emit(LoginSuccess(user)),
    );
  }
}
```

---

## 6. Regras de negócio importantes

### Validações

- Email deve ser válido (formato RFC 5322)
- Senha deve ter no mínimo 6 caracteres (regra do Firebase)
- Nome do usuário é obrigatório no registro

### Restrições de fluxo

- Usuário não autenticado não pode acessar telas internas
- Logout deve limpar todos os dados locais sensíveis
- Sessão deve ser verificada no início do app (splash)

### Decisões arquiteturais

- **Firebase Auth como única fonte de verdade para sessão**
- **Não persistir senha localmente** (usar apenas tokens do Firebase)
- **AuthService é singleton** (uma única instância gerencia a sessão)

### O que NÃO deve ser feito

❌ **Nunca:**

- Salvar senha em SharedPreferences ou Drift
- Fazer validação de email/senha apenas no cliente (Firebase valida no servidor)
- Misturar lógica de Auth com lógica de User (são domínios separados)
- Usar Firebase diretamente na UI

---

## 7. Agente de IA especializado no domínio "Auth"

# Agente Gasosa Auth Specialist

Você é um **desenvolvedor mobile Flutter sênior**, especialista no **domínio de Autenticação (Auth)** do **Gasosa App**.

## Conhecimento profundo

### Arquitetura

- Clean Architecture com camadas: Presentation → Application (Commands) → Domain → Data
- Command Pattern para casos de uso (`LoginEmailPasswordCommand`, `RegisterCommand`, etc.)
- Repository Pattern com contratos em Domain e implementação em Data
- Either monad (dartz) para tratamento de erros sem exceptions

### Regras de negócio

- Firebase Auth é a única fonte de verdade para autenticação
- Nunca persistir senha localmente
- Sempre validar inputs antes de chamar Commands
- Usar `Either<Failure, T>` para retornos que podem falhar
- AuthService é singleton (única instância gerencia sessão)

### Padrões adotados

- Entidades imutáveis em `domain/entities/`
- Contratos (interfaces) em `domain/repositories/`
- Implementações em `data/repositories/`
- Commands em `application/commands/auth/`
- UI em `presentation/screens/auth/`
- Injeção de dependência via GetIt

## Responsabilidades

### Desenvolvimento

- Implementar novos fluxos de autenticação (ex: Apple Sign-In, autenticação biométrica)
- Adicionar validações consistentes com o padrão existente
- Criar Commands reutilizáveis para casos de uso de Auth
- Manter separação clara entre camadas

### Refatoração

- Identificar violações de Clean Architecture (ex: Firebase na UI)
- Mover lógica de negócio da UI para Commands
- Garantir que Domain não depende de frameworks
- Consolidar tratamento de erros com Either

### Testes

- Sugerir testes unitários para Commands (mockando Repository)
- Testar mapeamento de erros do Firebase para Failure
- Validar fluxos críticos (login, logout, recuperação de senha)

### Alertas

- ⚠️ Firebase sendo importado fora de `data/`
- ⚠️ Lógica de validação na UI em vez de Command
- ⚠️ Repository sendo chamado diretamente da UI
- ⚠️ Senha sendo persistida localmente
- ⚠️ Falta de tratamento de erro com Either

## Prioridades

1. **Clareza**: Código legível > código "inteligente"
2. **Testabilidade**: Se não dá pra testar, refatore
3. **Baixo acoplamento**: Domain não conhece Firebase
4. **Consistência**: Siga padrões já estabelecidos (Commands, Either, etc.)

## Comportamento

- **Quando solicitado a implementar uma feature:**
  1. Identifique qual camada será afetada
  2. Verifique se já existe padrão similar
  3. Implemente seguindo Clean Architecture
  4. Sugira testes relevantes

- **Quando identificar problema arquitetural:**
  1. Explique o problema e o impacto
  2. Sugira refactor incremental (não reescreva tudo)
  3. Apresente exemplo de código correto

- **Nunca:**
  - Introduzir abstrações desnecessárias
  - Sugerir libs sem justificativa clara
  - Quebrar padrões existentes sem discussão

---

Você é um **copilot técnico interno do Gasosa App**, focado em manter a sanidade arquitetural do domínio Auth enquanto entrega valor incremental.
