# Feature: Avatar do Usuário

**Status:** 📋 Planejada — não iniciada  
**Branch sugerida:** `feat/user-avatar`

---

## 1. Contexto e decisões

### Decisões tomadas

| Ponto | Decisão | Razão |
| --- | --- | --- |
| Armazenamento | **Local only** (igual às fotos de veículos) | Consistente com a arquitetura atual; sem dependência de Firebase Storage |
| Ponto de entrada UX | **Tap no `GasosaAvatar`** no header do Dashboard | Gesto natural e intuitivo |
| Remoção de foto | **Sim — incluso no escopo** | Usuário pode reverter para o avatar padrão |
| Foto do Google vs local | **Foto local tem prioridade** | Foto customizada deve prevalecer sobre a do provider |
| Abstração de domínio | **Criar `UserRepository`** | Mantém arquitetura limpa; UserDao não deve ser acessado diretamente por use cases |

### O que já existe (não criar novamente)

- `AuthUser.photoUrl` — campo no modelo de domínio
- `GasosaAvatar` — widget já exibe `NetworkImage` ou asset padrão
- `GasosaPhotoPicker` — captura câmera/galeria, preview otimista, pronto para reusar
- `LocalPhotoStorageImpl` — salva/deleta arquivos em `Documents/photos/`
- `SavePhotoUseCase` / `DeletePhotoUseCase` — reutilizáveis
- `UserDao` — tem `upsert`, `updateUser`, `watchById`
- `Users` table — coluna `photoUrl` nullable já existe
- `image_picker: ^1.2.0` — dependência já instalada

---

## 2. Arquitetura da feature

### Novo contrato de domínio: `UserRepository`

```dart
// lib/domain/repositories/user_repository.dart
abstract interface class UserRepository {
  Future<Either<Failure, Unit>> saveUser(AuthUser user);
  Future<Either<Failure, AuthUser?>> getUserById(String id);
  Future<Either<Failure, Unit>> updatePhotoPath(String userId, String? photoPath);
  Stream<AuthUser?> watchUser(String userId);
}
```

> O `updatePhotoPath` recebe `null` para representar "remover foto" (volta ao padrão).

### Novo use case: `UpdateUserAvatarUseCase`

```dart
// lib/application/auth/update_user_avatar_use_case.dart
// Orquestra:
// 1. currentUser() guard
// 2. Salva arquivo local via SavePhotoUseCase (reutilizado)
// 3. Deleta foto anterior via DeletePhotoUseCase (se havia uma)
// 4. userRepository.updatePhotoPath(userId, newPath)
// 5. Loga observabilidade
```

### Novo use case: `RemoveUserAvatarUseCase`

```dart
// lib/application/auth/remove_user_avatar_use_case.dart
// Orquestra:
// 1. currentUser() guard
// 2. Recupera path atual via userRepository.getUserById()
// 3. Deleta arquivo local via DeletePhotoUseCase
// 4. userRepository.updatePhotoPath(userId, null)
// 5. Loga observabilidade
```

### Diagrama de fluxo (atualizar avatar)

```text
GasosaAvatar (tap)
    ↓
DashboardScreen._pickAvatar()
    ↓ abre GasosaPhotoPicker em bottom sheet
DashboardViewModel.updateAvatar(File)
    ↓
UpdateUserAvatarUseCase
    ├── SavePhotoUseCase(file, oldPath)  ← already exists
    └── UserRepository.updatePhotoPath(uid, newPath)
            ↓
        UserRepositoryImpl → UserDao.upsert()
```

### Prioridade de exibição do avatar

```
GasosaAvatar recebe: localPhotoPath ?? googlePhotoUrl ?? null (asset padrão)
```

O `DashboardViewModel` monta esse valor a partir do `UserRepository.watchUser()`.
Quando há um path local, ele tem precedência sobre a `photoUrl` do `AuthUser` (Google).

---

## 3. Plano de ação (sequência de implementação)

### Passo 1 — Domain: `UserRepository`

- [ ] Criar `lib/domain/repositories/user_repository.dart`
  - Contratos: `saveUser`, `getUserById`, `updatePhotoPath`, `watchUser`

### Passo 2 — Data: mapper + impl

- [ ] Criar `lib/data/mappers/user_mapper.dart`
  - `UserRow → AuthUser` e `AuthUser → UsersCompanion`
- [ ] Criar `lib/data/repositories/user_repository_impl.dart`
  - `@LazySingleton(as: UserRepository)`
  - Delega para `UserDao`
  - Wrap em `DatabaseFailure` nos catches

### Passo 3 — Application: use cases

- [ ] Criar `lib/application/auth/update_user_avatar_use_case.dart`
  - Injeta: `AuthService`, `UserRepository`, `SavePhotoUseCase`, `DeletePhotoUseCase`, `ObservabilityService`
  - Loga: `update_avatar_success` / `update_avatar_failure`
- [ ] Criar `lib/application/auth/remove_user_avatar_use_case.dart`
  - Injeta: `AuthService`, `UserRepository`, `DeletePhotoUseCase`, `ObservabilityService`
  - Loga: `remove_avatar_success` / `remove_avatar_failure`

### Passo 4 — Core: strings

- [ ] Adicionar em `ProfileStrings` (`app_strings.dart`):
  - `changePhotoMenuLabel`, `removePhotoMenuLabel`
  - `changePhotoSuccess`, `removePhotoSuccess`
  - `changePhotoSourceTitle` (título do bottom sheet câmera/galeria)

### Passo 5 — Presentation

- [ ] Atualizar `GasosaAvatar`:
  - Aceitar `File? localFile` além de `String? photoUrl`
  - Prioridade: `localFile` > `photoUrl` > asset padrão
  - Tornar o widget tappable (callback `onTap`)
- [ ] Atualizar `DashboardViewModel`:
  - Injetar `UpdateUserAvatarUseCase` e `RemoveUserAvatarUseCase`
  - Expor `updateAvatar(File)` e `removeAvatar()`
  - Ler `UserRepository.watchUser()` para obter `localPhotoPath` e compor o display
- [ ] Atualizar `DashboardScreen`:
  - Tap no `GasosaAvatar` → abre `GasosaPhotoPicker` em `showModalBottomSheet`
  - Adicionar "Remover foto" no `PopupMenuButton` (⋮) — visível apenas quando há foto local

### Passo 6 — Integração: salvar usuário no login

- [ ] No `LoginWithGoogleUseCase` (ou equivalente), após login bem-sucedido, chamar `userRepository.saveUser(authUser)` para persistir o usuário no banco local (necessário para `watchUser` funcionar offline)
- [ ] Verificar se o mesmo é feito no login por email/senha e no registro

### Passo 7 — Testes

- [ ] `update_user_avatar_use_case_test.dart` — sucesso, file não encontrado, falha no storage, falha no repositório, usuário não autenticado
- [ ] `remove_user_avatar_use_case_test.dart` — sucesso, sem foto para remover, falha na deleção, usuário não autenticado

---

## 4. Dependências e riscos

### Sem novas dependências de pacote

A feature inteira pode ser implementada com o que já está no `pubspec.yaml`.

### Risco: migração de schema do Drift

A coluna `photoUrl` já existe na tabela `Users`. Não haverá migration necessária para a coluna em si.  
**⚠️ Atenção**: se a tabela `Users` ainda não estiver sendo populada no login atual (só `VehicleDao` e `RefuelDao` são usados), o `Passo 6` é crítico — sem salvar o usuário no DB local, o `watchUser` nunca emite dados.

### Risco: path local inválido após reinstalação

Fotos locais ficam em `getApplicationDocumentsDirectory()`, que é apagado ao desinstalar. O `photoUrl` no DB ficaria apontando para um path inexistente.  
**Mitigação**: `GasosaAvatar` deve tratar gracefully um `File` com path que não existe (fallback para asset padrão).

### Risco: Google photo vs local

No login via Google, `AuthUser.photoUrl` vem com uma URL do Google CDN. Se o usuário tiver uma foto local salva no `UserRepository`, essa deve ser usada. O `DashboardViewModel` deve compor: `localUser?.photoPath ?? authUser.photoUrl`.

---

## 5. Contratos esperados ao final

```text
lib/
  domain/
    repositories/
      user_repository.dart          ← NOVO
  data/
    mappers/
      user_mapper.dart              ← NOVO
    repositories/
      user_repository_impl.dart     ← NOVO
  application/
    auth/
      update_user_avatar_use_case.dart  ← NOVO
      remove_user_avatar_use_case.dart  ← NOVO
  presentation/
    widgets/
      gasosa_avatar.dart            ← MODIFICADO (onTap + File? localFile)
    screens/
      dashboard/
        viewmodel/
          dashboard_viewmodel.dart  ← MODIFICADO
        dashboard_screen.dart       ← MODIFICADO
```
