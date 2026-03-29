# Skill — Gasosa Firebase Conventions

**Convenções para integração com Firebase (Auth, Analytics, Crashlytics)**

---

## Visão Geral

Esta skill documenta as convenções do Gasosa App para **Firebase**, garantindo:
- **Autenticação segura** (email/senha, Google Sign-In)
- **Analytics úteis** (eventos de produto, não PII)
- **Crashlytics eficaz** (logs contextuais, erros não fatais)
- **Privacidade** (nunca logar dados sensíveis)

---

## Serviços Usados

1. **Firebase Auth** - Autenticação e sessão
2. **Firebase Analytics** - Eventos de produto
3. **Firebase Crashlytics** - Crash reporting

---

## Firebase Auth

### Wrapper Pattern

```dart
// ✅ BOM: Wrapper que retorna Either
class FirebaseAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Future<Either<Failure, UserEntity>> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(_mapToUserEntity(credential.user!));
    } on FirebaseAuthException catch (e) {
      return Left(_mapAuthException(e));
    }
  }
}

// ❌ RUIM: Sem wrapper, lança exceptions
Future<UserEntity> signIn(String email, String password) async {
  final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  return UserEntity.fromFirebase(credential.user!);
}
```

### Mapeamento de Erros

```dart
Failure _mapAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return AuthFailure('Usuário não encontrado');
    case 'wrong-password':
      return AuthFailure('Senha incorreta');
    case 'email-already-in-use':
      return AuthFailure('Email já cadastrado');
    case 'weak-password':
      return AuthFailure('Senha muito fraca (mínimo 6 caracteres)');
    case 'invalid-email':
      return ValidationFailure('Email inválido');
    case 'user-disabled':
      return AuthFailure('Usuário desabilitado');
    default:
      return AuthFailure('Erro de autenticação: ${e.message}');
  }
}
```

### Stream de Autenticação

```dart
Stream<Either<Failure, UserEntity?>> get authStateChanges {
  return _auth.authStateChanges().map((user) {
    if (user == null) return Right(null);
    return Right(_mapToUserEntity(user));
  }).handleError((e) {
    return Left(AuthFailure('Erro ao observar autenticação'));
  });
}
```

---

## Firebase Analytics

### Convenções de Nomenclatura

```dart
// ✅ BOM: snake_case, descritivo
_analytics.logEvent(name: 'create_refuel', ...);
_analytics.logEvent(name: 'delete_vehicle', ...);

// ❌ RUIM: camelCase, genérico
_analytics.logEvent(name: 'createRefuel', ...);
_analytics.logEvent(name: 'click', ...);
```

### Eventos Padrão (use quando possível)

```dart
// Login
await _analytics.logLogin(loginMethod: 'email');
await _analytics.logLogin(loginMethod: 'google');

// Signup
await _analytics.logSignUp(signUpMethod: 'email');

// Screen views
await _analytics.logScreenView(screenName: 'vehicle_list');
```

### Eventos Customizados

```dart
// Estrutura padrão
await _analytics.logEvent(
  name: 'create_refuel',
  parameters: {
    'refuel_id': refuelId,           // ID anonimizado
    'liters': liters,                // Métrica
    'total_value': totalValue,       // Métrica
    'full_tank': fullTank,           // Boolean
  },
);
```

### Catálogo de Eventos do Gasosa

#### Auth
```dart
// Login
logLogin(String method) // method: 'email', 'google'
logSignUp(String method)
logLogout()

// Senha
logPasswordReset()
```

#### Vehicles
```dart
// CRUD
logEvent(name: 'create_vehicle', parameters: {
  'vehicle_id': vehicleId,
  'brand': brand,          // Opcional
  'model': model,          // Opcional
});

logEvent(name: 'update_vehicle', parameters: {
  'vehicle_id': vehicleId,
});

logEvent(name: 'delete_vehicle', parameters: {
  'vehicle_id': vehicleId,
});
```

#### Refuels
```dart
// CRUD
logEvent(name: 'create_refuel', parameters: {
  'refuel_id': refuelId,
  'vehicle_id': vehicleId,
  'liters': liters,
  'total_value': totalValue,
  'full_tank': fullTank,
});

logEvent(name: 'view_refuel_history', parameters: {
  'vehicle_id': vehicleId,
});

logEvent(name: 'filter_refuels', parameters: {
  'filter_type': 'last_30_days', // ou 'last_60_days', 'custom'
});
```

### User Properties

```dart
// Setar properties do usuário
await _analytics.setUserProperty(
  name: 'total_vehicles',
  value: totalVehicles.toString(),
);

await _analytics.setUserProperty(
  name: 'plan',
  value: 'free', // ou 'premium'
);
```

### ⚠️ NUNCA LOGUE

```dart
// ❌ RUIM: PII (Personally Identifiable Information)
_analytics.logEvent(
  name: 'user_action',
  parameters: {
    'email': user.email,           // ❌ PII
    'name': user.name,             // ❌ PII
    'phone': user.phone,           // ❌ PII
    'address': user.address,       // ❌ PII
    'cpf': user.cpf,               // ❌ PII
  },
);

// ✅ BOM: IDs anonimizados apenas
_analytics.logEvent(
  name: 'user_action',
  parameters: {
    'user_id': user.id,            // ✅ ID anonimizado
  },
);
```

---

## Firebase Crashlytics

### Setup em main.dart

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Configurar Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(MyApp());
}
```

### Wrapper Pattern

```dart
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService(this._crashlytics);

  // Logar erro não fatal
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  // Logar mensagem (breadcrumb)
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  // Setar user ID (para rastreabilidade)
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  // Setar custom key (contexto)
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }
}
```

### Uso em Repositories

```dart
@override
Future<Either<Failure, VehicleEntity>> save(VehicleEntity vehicle) async {
  try {
    await _dao.insertOrUpdate(...);
    return Right(vehicle);
  } catch (e, stack) {
    // Logar erro no Crashlytics
    _crashlytics.recordError(
      e,
      stack,
      reason: 'Erro ao salvar veículo (vehicleId: ${vehicle.id})',
      fatal: false,
    );
    return Left(DatabaseFailure('Erro ao salvar veículo'));
  }
}
```

### Logging de Contexto

```dart
// Adicionar breadcrumbs para rastrear ações do usuário
await _crashlytics.log('User opened vehicle list');
await _crashlytics.log('User tapped on vehicle: $vehicleId');
await _crashlytics.log('User started creating refuel');

// Em caso de crash, breadcrumbs aparecem no relatório
```

### Custom Keys (Contexto Adicional)

```dart
// Adicionar contexto útil
await _crashlytics.setCustomKey('current_screen', 'vehicle_list');
await _crashlytics.setCustomKey('total_vehicles', totalVehicles);
await _crashlytics.setCustomKey('offline_mode', isOffline);

// User ID (após login)
await _crashlytics.setUserId(user.id);
```

---

## Configuração por Flavor

### Estrutura

```
lib/
├─ firebase_options_dev.dart
├─ firebase_options_prod.dart
├─ main_dev.dart
└─ main_prod.dart
```

### main_dev.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}
```

### Gerar Firebase Options

```bash
# Dev
flutterfire configure \
  --project=gasosa-dev \
  --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=com.gasosa.app.dev \
  --android-app-id=com.gasosa.app.dev

# Prod
flutterfire configure \
  --project=gasosa-prod \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.gasosa.app \
  --android-app-id=com.gasosa.app
```

---

## Testes

### Mock Firebase Auth

```dart
class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

test('deve_retornar_Right_quando_login_sucesso', () async {
  // ARRANGE
  final mockAuth = MockFirebaseAuthService();
  final command = LoginEmailPasswordCommand(mockAuth);

  final user = UserFactory.create();
  when(() => mockAuth.signInWithEmailPassword(any(), any()))
      .thenAnswer((_) async => Right(user));

  // ACT
  final result = await command.execute(
    email: 'test@example.com',
    password: 'password123',
  );

  // ASSERT
  expect(result.isRight(), true);
});
```

### Mock Analytics

```dart
class MockAnalyticsService extends Mock implements AnalyticsService {}

test('deve_logar_evento_create_refuel_apos_sucesso', () async {
  // ARRANGE
  final mockAnalytics = MockAnalyticsService();
  final command = CreateRefuelCommand(mockRepository, mockAnalytics);

  // ACT
  await command.execute(...);

  // ASSERT
  verify(() => mockAnalytics.logCreateRefuel(
    refuelId: any(named: 'refuelId'),
    liters: any(named: 'liters'),
    totalValue: any(named: 'totalValue'),
    fullTank: any(named: 'fullTank'),
  )).called(1);
});
```

---

## Checklist de Qualidade

- [ ] Firebase Auth usa wrapper (retorna Either)?
- [ ] Erros do Firebase Auth são mapeados para Failures?
- [ ] Analytics não loga PII (email, nome, CPF, etc.)?
- [ ] Eventos de analytics têm nomes descritivos (snake_case)?
- [ ] Crashlytics está configurado em main.dart?
- [ ] Erros não fatais são logados com contexto (reason)?
- [ ] User ID é setado no Crashlytics após login?
- [ ] Testes mockam serviços Firebase?
- [ ] Configuração por flavor (dev/prod) está correta?

---

**Referências:**
- Firebase Flutter docs: https://firebase.flutter.dev/
- `lib/core/services/` → Wrappers de Firebase
