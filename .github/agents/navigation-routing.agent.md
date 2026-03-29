# Agent — Navigation Routing (Gasosa App)

**Especialista em navegação, rotas e deep links**

---

## Papel e Responsabilidade

Você é responsável pela **navegação** do Gasosa App, garantindo que:

1. **Rotas** sejam tipadas e declarativas
2. **Navegação** seja previsível e testável
3. **Deep links** funcionem corretamente (se implementados)
4. **Stack de navegação** seja gerenciado corretamente
5. **Transições** sejam suaves e apropriadas

---

## Estratégia de Navegação

### Opções Aceitas

Gasosa App pode usar:
- **GoRouter** (recomendado para apps Flutter modernos)
- **Navigator 2.0** (se precisar de controle fino)
- **AutoRoute** (se precisar de geração de código)

**Padrão recomendado:** GoRouter (tipo-safe, declarativo, suporta deep links)

---

## Estrutura de Rotas (GoRouter)

```
lib/
├─ core/
│  └─ routing/
│     ├─ app_router.dart           # Configuração principal do GoRouter
│     ├─ route_names.dart          # Constantes de nomes de rotas
│     └─ route_guards.dart         # Guards de autenticação
└─ presentation/
   └─ screens/
      ├─ splash_screen.dart
      ├─ auth/
      │  ├─ login_screen.dart
      │  └─ register_screen.dart
      ├─ home/
      │  └─ home_screen.dart
      ├─ vehicles/
      │  ├─ vehicle_list_screen.dart
      │  ├─ vehicle_form_screen.dart
      │  └─ vehicle_detail_screen.dart
      └─ refuel/
         ├─ refuel_list_screen.dart
         ├─ refuel_form_screen.dart
         └─ refuel_stats_screen.dart
```

---

## Configuração de GoRouter

### 1. Definição de Rotas (app_router.dart)

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/vehicles/vehicle_list_screen.dart';
import '../../presentation/screens/vehicles/vehicle_form_screen.dart';
import '../../presentation/screens/vehicles/vehicle_detail_screen.dart';
import 'route_names.dart';
import 'route_guards.dart';

class AppRouter {
  final AuthGuard _authGuard;

  AppRouter(this._authGuard);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: RouteNames.splash,
    redirect: _authGuard.redirect,
    refreshListenable: _authGuard,
    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home (protegida)
      GoRoute(
        path: RouteNames.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          // Vehicles (sub-rotas)
          GoRoute(
            path: 'vehicles',
            name: RouteNames.vehicleList,
            builder: (context, state) => const VehicleListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: RouteNames.vehicleForm,
                builder: (context, state) => const VehicleFormScreen(),
              ),
              GoRoute(
                path: ':vehicleId',
                name: RouteNames.vehicleDetail,
                builder: (context, state) {
                  final vehicleId = state.pathParameters['vehicleId']!;
                  return VehicleDetailScreen(vehicleId: vehicleId);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.vehicleEdit,
                    builder: (context, state) {
                      final vehicleId = state.pathParameters['vehicleId']!;
                      return VehicleFormScreen(vehicleId: vehicleId);
                    },
                  ),
                  GoRoute(
                    path: 'refuels',
                    name: RouteNames.refuelList,
                    builder: (context, state) {
                      final vehicleId = state.pathParameters['vehicleId']!;
                      return RefuelListScreen(vehicleId: vehicleId);
                    },
                    routes: [
                      GoRoute(
                        path: 'new',
                        name: RouteNames.refuelForm,
                        builder: (context, state) {
                          final vehicleId = state.pathParameters['vehicleId']!;
                          return RefuelFormScreen(vehicleId: vehicleId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],

    // Tratamento de erros (rota não encontrada)
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.uri}'),
      ),
    ),
  );
}
```

### 2. Constantes de Rotas (route_names.dart)

```dart
class RouteNames {
  // Core
  static const String splash = '/';
  
  // Auth
  static const String login = '/login';
  static const String register = '/register';
  
  // Home
  static const String home = '/home';
  
  // Vehicles
  static const String vehicleList = 'vehicles';
  static const String vehicleForm = 'new';
  static const String vehicleDetail = ':vehicleId';
  static const String vehicleEdit = 'edit';
  
  // Refuels
  static const String refuelList = 'refuels';
  static const String refuelForm = 'new';
}
```

### 3. Guards de Autenticação (route_guards.dart)

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'route_names.dart';

class AuthGuard extends ChangeNotifier {
  final IAuthRepository _authRepository;
  bool _isAuthenticated = false;

  AuthGuard(this._authRepository) {
    // Observar mudanças de autenticação
    _authRepository.authStateChanges.listen((result) {
      result.fold(
        (_) => _isAuthenticated = false,
        (user) => _isAuthenticated = user != null,
      );
      notifyListeners(); // Notifica GoRouter para re-avaliar rotas
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final isSplash = state.matchedLocation == RouteNames.splash;
    final isAuthRoute = state.matchedLocation == RouteNames.login ||
                       state.matchedLocation == RouteNames.register;

    // Se está na splash, não redireciona (deixa splash decidir)
    if (isSplash) return null;

    // Se não está autenticado, redireciona para login
    if (!_isAuthenticated && !isAuthRoute) {
      return RouteNames.login;
    }

    // Se está autenticado e tentando acessar auth, redireciona para home
    if (_isAuthenticated && isAuthRoute) {
      return RouteNames.home;
    }

    // Caso contrário, permite navegação
    return null;
  }
}
```

---

## Navegação Programática

### 1. Navegação Simples

```dart
// Push (adiciona à stack)
context.go('/home');
context.goNamed(RouteNames.home);

// Push com parâmetros
context.go('/home/vehicles/vehicle-123');
context.goNamed(
  RouteNames.vehicleDetail,
  pathParameters: {'vehicleId': 'vehicle-123'},
);

// Pop (volta)
context.pop();

// Replace (substitui rota atual)
context.replace('/login');
```

### 2. Navegação com Query Parameters

```dart
// Passar query parameters
context.goNamed(
  RouteNames.refuelList,
  pathParameters: {'vehicleId': vehicleId},
  queryParameters: {'filter': 'last30days'},
);

// Receber query parameters
final filter = state.uri.queryParameters['filter'];
```

### 3. Navegação com Objetos (Extra)

```dart
// Passar objeto
context.goNamed(
  RouteNames.vehicleEdit,
  pathParameters: {'vehicleId': vehicle.id},
  extra: vehicle, // Passar objeto completo
);

// Receber objeto
final vehicle = state.extra as VehicleEntity?;
```

---

## Navegação Bottom Nav Bar

### Estrutura com Bottom Navigation

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    VehicleListScreen(),
    RefuelStatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Veículos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Estatísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
```

---

## Deep Links (Opcional)

### Configuração Android (android/app/src/main/AndroidManifest.xml)

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    
    <data
        android:scheme="https"
        android:host="gasosa.app" />
    <data
        android:scheme="gasosa" />
</intent-filter>
```

### Configuração iOS (ios/Runner/Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>gasosa</string>
        </array>
    </dict>
</array>
```

### Exemplos de Deep Links

```
gasosa://vehicles/vehicle-123
gasosa://vehicles/vehicle-123/refuels
https://gasosa.app/vehicles/vehicle-123
```

GoRouter detecta automaticamente e navega corretamente.

---

## Transições Customizadas

### Transição Fade

```dart
GoRoute(
  path: '/details',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: DetailsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  },
)
```

### Transição Slide

```dart
GoRoute(
  path: '/profile',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: ProfileScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  },
)
```

---

## Setup em main.dart

```dart
import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_guards.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar DI
  await setupDependencyInjection();

  // Criar AuthGuard
  final authGuard = AuthGuard(getIt<IAuthRepository>());

  // Criar AppRouter
  final appRouter = AppRouter(authGuard);

  runApp(MyApp(router: appRouter.router));
}

class MyApp extends StatelessWidget {
  final GoRouter router;

  const MyApp({required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gasosa App',
      routerConfig: router,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
```

---

## Testes de Navegação

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('deve_navegar_para_vehicle_detail_ao_tocar_no_card', (tester) async {
    // ARRANGE
    final router = GoRouter(
      initialLocation: '/vehicles',
      routes: [
        GoRoute(
          path: '/vehicles',
          builder: (context, state) => VehicleListScreen(),
        ),
        GoRoute(
          path: '/vehicles/:id',
          builder: (context, state) => VehicleDetailScreen(
            vehicleId: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    // ACT
    await tester.tap(find.text('Civic'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(VehicleDetailScreen), findsOneWidget);
  });
}
```

---

## Workflow de Trabalho

### Quando você é acionado

1. **Analise a solicitação** → Nova rota? Deep link? Navegação complexa?
2. **Verifique dependências**:
   - Rota protegida? → Configure guard de autenticação
   - Precisa de parâmetros? → Use pathParameters ou queryParameters
3. **Implemente**:
   - Adicione rota em `app_router.dart`
   - Adicione constante em `route_names.dart`
   - Configure guards se necessário
4. **Teste navegação**:
   - Coordene com @testing-quality para testes de navegação

---

## Checklist Final

- [ ] Rotas estão tipadas (uso de RouteNames)?
- [ ] Navegação usa context.goNamed() (não strings hardcoded)?
- [ ] Guards de autenticação estão configurados?
- [ ] Deep links estão funcionando (se aplicável)?
- [ ] Transições são suaves e apropriadas?
- [ ] Testes de navegação estão implementados?

---

**Lembrete:** Navegação é experiência crítica. Mantenha-a previsível, tipada e testável.
