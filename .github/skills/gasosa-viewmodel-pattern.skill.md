# Skill — Gasosa ViewModel Pattern

**Padrões e convenções de ViewModel da camada de Presentation**

---

## Visão Geral

ViewModels no Gasosa App orquestram `Command`s e gerenciam estado de UI.
Eles **não contêm regras de negócio**, **não dependem de widgets Flutter** e **não armazenam estado de formulário** quando desnecessário.

A base é `ValueNotifier` + `Command<T>` (sem `ChangeNotifier`, sem Provider, sem Bloc).

---

## Responsabilidades

| Pertence à ViewModel | Pertence à Tela |
|---|---|
| Estado de domínio (`ManageVehicleState`, flags de negócio) | `TextEditingController`s |
| Orquestração de `Command`s | `GlobalKey<FormState>` |
| Lógica derivada (`shouldShowColdStart`, `hasColdStart`) | `_populateControllersIfNeeded` |
| Side effects de dados (foto staging, delete staged) | `AnimationController`, `ScrollController` |

---

## Anatomy de uma ViewModel

```dart
@injectable
class ManageVehicleViewModel {
  ManageVehicleViewModel(
    this._auth,
    this._getVehicleById,
    this._saveVehicle,
    this._deleteVehicle,
    this._savePhoto,
    this._deletePhoto,
  ) : state = ValueNotifier(const ManageVehicleState()),
      loadCommand = Command<Unit>(),
      saveCommand = Command<Unit>(),
      deleteCommand = Command<Unit>(),
      photoCommand = Command<String>();

  // 1. Dependências (use cases apenas)
  final AuthService _auth;
  final GetVehicleByIdUseCase _getVehicleById;
  // ...

  // 2. Commands tipados
  final Command<Unit> loadCommand;
  final Command<Unit> saveCommand;

  // 3. Estado observável
  final ValueNotifier<ManageVehicleState> state;

  // 4. Updaters (um por campo do estado)
  void updateName(String value) => state.value = state.value.copyWith(name: value);

  // 5. Dispose explícito
  void dispose() {
    state.dispose();
    loadCommand.dispose();
    saveCommand.dispose();
    deleteCommand.dispose();
    photoCommand.dispose();
  }
}
```

---

## Tipos de ViewModel

### Tipo 1 — Formulário simples (sem estado contínuo)

Usado em `LoginViewModel`, `RegisterViewModel`.

Regra: a VM **não armazena campos de formulário**. Os valores são passados como parâmetros no momento da ação.

```dart
@injectable
class LoginViewModel {
  LoginViewModel(this._loginGoogle, this._loginEmailPassword)
      : googleCommand = Command<AuthUser>(),
        loginCommand = Command<AuthUser>();

  final Command<AuthUser> googleCommand;
  final Command<AuthUser> loginCommand;

  // ✅ Valores recebidos no submit — sem campos mutáveis públicos
  Future<Either<Failure, AuthUser>?> loginWithEmailPassword({
    required String email,
    required String password,
  }) => loginCommand.run(() => _loginEmailPassword(email: email, password: password));

  void dispose() {
    googleCommand.dispose();
    loginCommand.dispose();
  }
}
```

Na tela:
```dart
// ✅ Controllers ficam na tela — dona correta do estado de UI
final _emailEC = TextEditingController();
final _passwordEC = TextEditingController();

// No submit:
_viewModel.loginWithEmailPassword(
  email: _emailEC.text,
  password: _passwordEC.text,
);
```

### Tipo 2 — Formulário com estado contínuo (edit mode)

Usado em `ManageVehicleViewModel`, `ManageRefuelViewModel`.

Regra: a VM mantém o estado do form para construir a entidade no `save()`. A tela usa `onChanged` + `updateX`.

```dart
@injectable
class ManageVehicleViewModel {
  // Estado consolidado (necessário para _buildEntity())
  final ValueNotifier<ManageVehicleState> state;

  // Updaters por campo
  void updateName(String value) => state.value = state.value.copyWith(name: value);
  void updatePlate(String value) => state.value = state.value.copyWith(plate: value);
  void updateFuelType(FuelType value) => state.value = state.value.copyWith(fuelType: value);
}
```

Na tela:
```dart
// Controllers ficam na tela
final _nameController = TextEditingController();

// Populate no primeiro build após load
void _populateControllersIfNeeded(ManageVehicleState s) {
  if (_didPopulate || !s.isEdit || s.initial == null) return;
  _nameController.text = s.name;
  _didPopulate = true;
}

// onChanged sincroniza VM
GasosaFormField(
  controller: _nameController,
  onChanged: _viewmodel.updateName,
)
```

---

## Contracts

### `Command<T>` — tipos corretos

```dart
// ✅ Operações sem dado de retorno → Unit
loadCommand = Command<Unit>()
saveCommand = Command<Unit>()
deleteCommand = Command<Unit>()

// ✅ Operações com dado → tipo concreto
loginCommand = Command<AuthUser>()
photoCommand = Command<String>()

// ❌ Nunca void
Command<void>()
```

### `right(unit)` em vez de `right(null)`

```dart
// ✅
return right(unit);

// ❌
return right(null);
```

### `flatMap`/`map` — sempre puros

Mutações de estado nunca dentro de `flatMap` ou `map`:

```dart
// ✅ Transformação pura + side effect separado
final result = either.flatMap((v) {
  if (v == null) return const Left(ValidationFailure('Não encontrado'));
  return Right(v);
});
result.fold(
  (_) {},
  (v) { state.value = state.value.copyWith(/* ... */); },
);
return result.map((_) => unit);

// ❌ Side effect dentro de flatMap
return either.flatMap((v) {
  state.value = ...; // imprevisível — não faça isso
  return right(null);
});
```

### Cast seguro de `Either`

```dart
// ✅ Usar fold com variáveis locais
Failure? failure;
RefuelEntity? entity;
either.fold((f) { failure = f; }, (r) { entity = r; });
if (failure != null) return Left(failure!);
if (entity == null) return const Left(ValidationFailure('Não encontrado'));
final e = entity!; // non-nullable a partir daqui

// ❌ Cast em runtime
final value = either as Right<Failure, RefuelEntity?>; // lança se errar
```

---

## Use Cases — sem bypass de serviços

Toda operação com side effect passa por um `UseCase`. Nunca chamar `AuthService`, `Repository` ou serviços diretamente da VM:

```dart
// ✅
final LogoutUseCase _logout;
Future<Either<Failure, void>> logout() => _logout();

// ❌
final AuthService _auth;
Future<void> logout() => _auth.logout(); // bypassa a camada de aplicação
```

---

## `dispose()` na tela — obrigatório

```dart
@override
void dispose() {
  _viewModel.dispose(); // sempre antes do super
  _emailEC.dispose();
  _passwordEC.dispose();
  super.dispose();
}
```

---

## Naming

| Padrão | Exemplo |
|---|---|
| Classe: `XxxViewModel` | `LoginViewModel`, `ManageVehicleViewModel` |
| Updaters: `updateX` | `updateName`, `updateFuelType` |
| Commands: `xCommand` | `saveCommand`, `loadCommand`, `deleteCommand` |
| Estado: `state` | `ValueNotifier<ManageVehicleState> state` |

---

## Checklist de revisão

- [ ] Nenhum `TextEditingController` ou `import flutter/material.dart` na VM
- [ ] `Command<Unit>` para operações sem dado de retorno — nunca `Command<void>`
- [ ] `flatMap`/`map` sem mutação de estado interno
- [ ] Campos de formulário: públicos só se a UI precisa de `onChanged` contínuo (Tipo 2)
- [ ] Operações com side effect: sempre via `UseCase`
- [ ] `dispose()` chamado na tela que instancia a VM
- [ ] Nenhum dead code (`updateX` não chamado em lugar nenhum)
- [ ] Naming: `ViewModel` com `V` maiúsculo
