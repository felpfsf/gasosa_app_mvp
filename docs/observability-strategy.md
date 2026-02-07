# Estratégia de Observabilidade - Gasosa App MVP

## 📋 Visão Geral

Este documento define a estratégia de observabilidade do Gasosa App, usando **Firebase Crashlytics** (crashes e erros) e **Firebase Analytics** (eventos e funil). O objetivo é garantir visibilidade real de erros e comportamento do usuário no MVP, sem overengineering.

---

## 🎯 Objetivos

1. **Detectar e entender erros em produção** (crashes e falhas tratadas)
2. **Ter trilha (breadcrumb) do que aconteceu antes do erro**
3. **Medir o básico do funil do MVP** (login → criar veículo → registrar abastecimento)

### Princípios (não negociáveis)

- **Privacidade primeiro**: Não enviar PII (e-mail, nome, placa, path de arquivo, conteúdo de imagem)
- **Error taxonomy**: Classificar falhas por tipo (`AuthFailure`, `DatabaseFailure`, `ValidationFailure`)
- **Simplicidade**: Poucos eventos bem escolhidos > 50 eventos inúteis

---

## 🛠️ Stack (Firebase)

| Ferramenta | Propósito | Quando usar |
| ------------ | ----------- | ------------- |
| **Firebase Crashlytics** | Crashes (fatal) e erros não-fatais (Failure) | Sempre |
| **Firebase Analytics** | Eventos de negócio e funil | Sempre |
| **Custom Keys** (Crashlytics) | Contexto adicional (userId, vehicleId, route) | Em erros |
| **Breadcrumbs** (Crashlytics) | Trilha de navegação e ações | Antes de erros |

---

## 📊 O Que Rastrear (Mínimo Bom)

### 1. Crashes + Erros

#### Crashes (fatal)

- Capturados automaticamente pelo Crashlytics
- `FlutterError.onError` → Crashlytics
- `PlatformDispatcher.instance.onError` → Crashlytics

#### Erros tratados (non-fatal)

- `Either<Failure, T>` → quando `Left(failure)`, enviar como non-fatal
- Tipos de Failure:
  - `AuthFailure` (login, registro, Google Sign-In)
  - `DatabaseFailure` (CRUD veículos/abastecimentos)
  - `ValidationFailure` (validação de formulário)
  - `NotFoundFailure` (recurso não existe)
  - `BusinessFailure` (regra de negócio violada)
  - `UnexpectedFailure` (catch-all)

**Payload sanitizado:**

```dart
{
  'type': 'AuthFailure',
  'code': 'invalid_credentials',
  'message': 'Credenciais inválidas', // sem dados do usuário
  'route': '/login',
  'userId': 'abc123'  // apenas ID interno, sem e-mail
}
```

---

### 2. Breadcrumbs (Trilha)

Registrar no Crashlytics antes de operações críticas:

| Tipo | Exemplo | Payload |
| ------ | --------- | --------- |
| **Navegação** | Mudança de rota | `{'from': '/home', 'to': '/add_vehicle'}` |
| **Ação do usuário** | Tap em botão | `{'action': 'tap_add_vehicle', 'route': '/home'}` |
| **Estado de IO** | Sucesso/falha de DB | `{'event': 'db_write_success', 'entity': 'vehicle'}` |
| **Auth state** | Mudança de autenticação | `{'event': 'auth_state_changed', 'isAuthenticated': true}` |

**Importante:** Não incluir parâmetros sensíveis (placa, e-mail, nome).

---

### 3. Eventos de Analytics (Funil MVP)

#### Autenticação

| Evento | Parâmetros | Quando disparar |
| -------- | ----------- | ----------------- |
| `login_attempt` | `method: 'email'` ou `'google'` | Usuário clica em "Entrar" |
| `login_success` | `method: 'email'` ou `'google'` | Login bem-sucedido |
| `login_fail` | `method: 'email'`, `error_type: 'invalid_credentials'` | Falha no login |
| `register_attempt` | - | Usuário clica em "Registrar" |
| `register_success` | - | Registro bem-sucedido |
| `register_fail` | `error_type: 'weak_password'` | Falha no registro |

#### Veículos

| Evento | Parâmetros | Quando disparar |
| -------- | ----------- | ----------------- |
| `vehicle_create_attempt` | - | Usuário clica em "Salvar" (novo) |
| `vehicle_create_success` | `has_photo: true/false` | Veículo criado |
| `vehicle_create_fail` | `error_type: 'database_error'` | Falha ao criar |
| `vehicle_update_success` | - | Veículo atualizado |
| `vehicle_delete_success` | - | Veículo deletado |

#### Abastecimentos

| Evento | Parâmetros | Quando disparar |
| -------- | ----------- | ----------------- |
| `refuel_create_attempt` | - | Usuário clica em "Salvar" (novo) |
| `refuel_create_success` | `has_receipt: true/false`, `fuel_type: 'gasoline'` | Abastecimento criado |
| `refuel_create_fail` | `error_type: 'database_error'` | Falha ao criar |
| `receipt_photo_added` | - | Usuário adiciona foto de recibo |
| `consumption_calculated` | - | Cálculo de consumo exibido |

#### App Lifecycle

| Evento | Parâmetros | Quando disparar |
| -------- | ----------- | ----------------- |
| `app_open` | - | App abre (primeiro frame) |
| `first_open` | - | Primeira vez que usuário abre o app |
| `cold_start_used` | `duration_ms: 1234` | App inicia do zero (opcional) |

---

## 🏗️ Arquitetura do Serviço

### Camada: `lib/core/services/observability/`

```md
lib/core/services/observability/
├── observability_service.dart         # Interface (contrato)
├── firebase_observability_service.dart # Implementação Firebase
└── noop_observability_service.dart    # Implementação vazia (testes)
```

---

### Interface: `observability_service.dart`

```dart
abstract class ObservabilityService {
  /// Registra um erro não-fatal (Failure tratada)
  Future<void> logError(
    Failure failure, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  });

  /// Registra um evento de analytics
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  });

  /// Registra um breadcrumb (trilha)
  void logBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
  });

  /// Define custom key para contexto (userId, vehicleId, route)
  void setCustomKey(String key, dynamic value);

  /// Define userId (para correlação, sem PII)
  void setUserId(String? userId);

  /// Limpa contexto (logout)
  void clearContext();
}
```

---

### Implementação: `firebase_observability_service.dart`

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:gasosa_app/core/errors/failures.dart';
import 'observability_service.dart';

class FirebaseObservabilityService implements ObservabilityService {
  final FirebaseCrashlytics _crashlytics;
  final FirebaseAnalytics _analytics;

  FirebaseObservabilityService({
    FirebaseCrashlytics? crashlytics,
    FirebaseAnalytics? analytics,
  })  : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
        _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> logError(
    Failure failure, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    // Sanitizar contexto (remover PII)
    final sanitized = _sanitizeContext(context);
    
    // Adicionar tipo de falha
    _crashlytics.setCustomKey('failure_type', failure.runtimeType.toString());
    _crashlytics.setCustomKey('failure_message', failure.message);
    
    // Adicionar contexto adicional
    sanitized.forEach((key, value) {
      _crashlytics.setCustomKey(key, value.toString());
    });

    // Enviar como non-fatal
    await _crashlytics.recordError(
      failure,
      stackTrace ?? StackTrace.current,
      reason: failure.message,
      fatal: false,
    );
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    // Sanitizar parâmetros
    final sanitized = _sanitizeContext(parameters);
    
    await _analytics.logEvent(
      name: name,
      parameters: sanitized,
    );
  }

  @override
  void logBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
  }) {
    final sanitized = _sanitizeContext(data);
    final breadcrumb = '$message ${sanitized.isNotEmpty ? sanitized.toString() : ''}';
    
    _crashlytics.log(breadcrumb);
  }

  @override
  void setCustomKey(String key, dynamic value) {
    // Não permitir keys sensíveis
    if (_isSensitiveKey(key)) return;
    
    _crashlytics.setCustomKey(key, value.toString());
  }

  @override
  void setUserId(String? userId) {
    _crashlytics.setUserIdentifier(userId ?? '');
    _analytics.setUserId(id: userId);
  }

  @override
  void clearContext() {
    setUserId(null);
    // Limpar custom keys relevantes (se necessário)
  }

  // Helpers privados
  Map<String, dynamic> _sanitizeContext(Map<String, dynamic>? context) {
    if (context == null) return {};
    
    return Map.fromEntries(
      context.entries.where((e) => !_isSensitiveKey(e.key)),
    );
  }

  bool _isSensitiveKey(String key) {
    const sensitive = [
      'email',
      'name',
      'displayName',
      'plate',
      'licensePlate',
      'photoPath',
      'receiptPath',
      'password',
      'token',
      'filePath',
    ];
    
    return sensitive.any((s) => key.toLowerCase().contains(s));
  }
}
```

---

### Noop (para testes): `noop_observability_service.dart`

```dart
import 'package:gasosa_app/core/errors/failures.dart';
import 'observability_service.dart';

class NoopObservabilityService implements ObservabilityService {
  @override
  Future<void> logError(
    Failure failure, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    // Não faz nada
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    // Não faz nada
  }

  @override
  void logBreadcrumb(String message, {Map<String, dynamic>? data}) {
    // Não faz nada
  }

  @override
  void setCustomKey(String key, dynamic value) {
    // Não faz nada
  }

  @override
  void setUserId(String? userId) {
    // Não faz nada
  }

  @override
  void clearContext() {
    // Não faz nada
  }
}
```

---

## 🔌 Integração na App

### 1. Setup no `main.dart`

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Desabilitar em debug (opcional)
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  runApp(const MyApp());
}
```

---

### 2. Injetar no `ServiceLocator` / `GetIt`

```dart
// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/core/services/observability/firebase_observability_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Observability
  getIt.registerLazySingleton<ObservabilityService>(
    () => FirebaseObservabilityService(),
  );
  
  // ... outros serviços
}
```

---

### 3. Usar nos Commands

#### Exemplo: `login_email_password_command.dart`

```dart
class LoginEmailPasswordCommand {
  final AuthRepository _authRepository;
  final ObservabilityService _observability;

  LoginEmailPasswordCommand(
    this._authRepository,
    this._observability,
  );

  Future<Either<Failure, AuthUser>> call({
    required String email,
    required String password,
  }) async {
    // Breadcrumb: tentativa de login
    _observability.logBreadcrumb(
      'Login attempt',
      data: {'method': 'email'},
    );

    // Analytics: tentativa
    await _observability.logEvent(
      'login_attempt',
      parameters: {'method': 'email'},
    );

    // Validação
    final emailValidation = EmailValidator.validate(email);
    if (emailValidation.isLeft()) {
      await _observability.logEvent(
        'login_fail',
        parameters: {'method': 'email', 'error_type': 'invalid_email'},
      );
      return emailValidation;
    }

    // Tentar login
    final result = await _authRepository.loginWithEmailAndPassword(
      email: email,
      password: password,
    );

    return result.fold(
      (failure) async {
        // Log erro não-fatal
        await _observability.logError(
          failure,
          context: {'method': 'email', 'route': '/login'},
        );

        // Analytics: falha
        await _observability.logEvent(
          'login_fail',
          parameters: {
            'method': 'email',
            'error_type': failure.runtimeType.toString(),
          },
        );

        return Left(failure);
      },
      (user) async {
        // Contexto: userId
        _observability.setUserId(user.id);
        _observability.setCustomKey('route', '/home');

        // Analytics: sucesso
        await _observability.logEvent(
          'login_success',
          parameters: {'method': 'email'},
        );

        return Right(user);
      },
    );
  }
}
```

---

### 4. Usar nos Widgets (navegação)

#### Exemplo: `main.dart` ou `app_router.dart`

```dart
// Quando mudar de rota
MaterialApp.router(
  routerConfig: GoRouter(
    observers: [
      ObservabilityNavigatorObserver(getIt<ObservabilityService>()),
    ],
    // ...
  ),
);
```

#### Observer customizado

```dart
class ObservabilityNavigatorObserver extends NavigatorObserver {
  final ObservabilityService _observability;

  ObservabilityNavigatorObserver(this._observability);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    
    _observability.logBreadcrumb(
      'Navigation',
      data: {
        'from': previousRoute?.settings.name ?? 'unknown',
        'to': route.settings.name ?? 'unknown',
      },
    );
    
    _observability.setCustomKey('current_route', route.settings.name ?? 'unknown');
  }
}
```

---

## ✅ Checklist de Privacidade

Antes de enviar qualquer dado, verificar:

- [ ] Não contém e-mail
- [ ] Não contém nome completo
- [ ] Não contém placa de veículo
- [ ] Não contém path absoluto de arquivo
- [ ] Não contém conteúdo de imagem/nota
- [ ] Não contém senha ou token
- [ ] Se tiver userId, é ID interno (não e-mail)
- [ ] Logs de erro não expõem stack trace para UI

---

## 🧪 Checklist de Validação

### Fase 1: Testes locais (Debug)

- [ ] Forçar um crash: `throw Exception('Test crash');`
- [ ] Verificar no Crashlytics Console (pode levar 5-10 min)
- [ ] Forçar um erro tratado: `logError(AuthFailure(...))`
- [ ] Verificar non-fatal no Crashlytics Console
- [ ] Disparar 2–3 eventos: `logEvent('test_event')`
- [ ] Verificar no DebugView do Analytics (ativar antes)
- [ ] Verificar breadcrumbs: navegar entre 3 telas e forçar erro
- [ ] Verificar contexto (userId, custom keys)

### Fase 2: Testes em staging (Release mode)

- [ ] Build release: `flutter build apk --release`
- [ ] Testar fluxo completo: login → criar veículo → criar abastecimento
- [ ] Verificar funil no Analytics (pode levar 24h para aparecer)
- [ ] Simular erro de rede (modo avião) e verificar envio
- [ ] Verificar que PII não aparece no console

### Fase 3: Produção (monitoramento contínuo)

- [ ] Configurar alertas no Crashlytics (> 10 erros/hora)
- [ ] Revisar crashes semanalmente
- [ ] Revisar eventos do funil mensalmente
- [ ] Validar que breadcrumbs ajudam no debug

---

## 📦 Dependências Necessárias

Adicionar ao `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.10.0
  firebase_crashlytics: ^4.4.0
  firebase_analytics: ^11.4.0

dev_dependencies:
  # Para testes (mock)
  mocktail: ^1.0.0
```

Executar:

```bash
flutter pub get
flutterfire configure  # Se ainda não configurou
```

---

## 📈 Métricas de Sucesso (MVP)

### Crashlytics

- **Crash-free rate:** > 99.5%
- **Tempo médio para resolver crash crítico:** < 48h
- **Non-fatal errors por usuário:** < 5/mês

### Analytics (Funil)

1. `app_open` → `login_attempt` → `login_success`: > 70%
2. `login_success` → `vehicle_create_success`: > 80%
3. `vehicle_create_success` → `refuel_create_success`: > 60%

---

## 🔄 Evolução Pós-MVP

Quando o app crescer, considerar:

1. **Performance monitoring** (Firebase Performance)
2. **Remote config** (A/B testing)
3. **User properties** (segmentação)
4. **Custom dimensions** (Analytics)
5. **Session replay** (tool externa, cuidado com privacidade)

---

## 📚 Referências

- [Firebase Crashlytics - Flutter](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter)
- [Firebase Analytics - Flutter](https://firebase.google.com/docs/analytics/get-started?platform=flutter)
- [Crashlytics Best Practices](https://firebase.google.com/docs/crashlytics/best-practices)
- [GDPR e Firebase](https://firebase.google.com/support/privacy)

---

## 🎯 Resumo Executivo

**O quê rastrear:**

- Crashes (automático)
- Erros tratados (Failure → non-fatal)
- 15 eventos de funil (login, vehicle, refuel)
- Breadcrumbs de navegação e ações

**Onde:**

- `ObservabilityService` em `lib/core/services/observability/`
- Injetar via GetIt
- Usar em Commands e NavigatorObserver

**Privacidade:**

- Sanitizar contexto (sem PII)
- Usar userId interno, não e-mail
- Validar antes de cada release

**Validação:**

- Debug: forçar crash e erro
- Staging: testar funil completo
- Produção: monitorar semanalmente
