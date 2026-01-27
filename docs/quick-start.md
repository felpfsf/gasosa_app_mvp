# Guia de Início Rápido - Gasosa App

Este guia fornece instruções para desenvolvedores que estão começando no projeto Gasosa App.

---

## 📋 Pré-requisitos

- **Flutter SDK**: 3.9.0 ou superior
- **Dart SDK**: Incluído com Flutter
- **IDE**: VS Code ou Android Studio
- **Git**: Para controle de versão
- **Firebase CLI**: Para configuração de ambientes

### Instalação do Flutter

```bash
# Verificar versão do Flutter
flutter --version

# Caso precise atualizar
flutter upgrade
```

---

## 🚀 Setup Inicial

### 1. Clonar o repositório

```bash
git clone <repository-url>
cd gasosa_app_mvp
```

### 2. Instalar dependências

```bash
flutter pub get
```

### 3. Gerar código (Drift)

```bash
# Gerar código do Drift (DAOs, tabelas)
flutter pub run build_runner build --delete-conflicting-outputs

# OU modo watch (auto-regenera ao salvar)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. Configurar Firebase

O projeto usa **Flavorizr** para gerenciar múltiplos ambientes (dev/prod).

1. Adicionar arquivos de configuração Firebase:

   ```md
   firebase/dev/google-services.json        (Android)
   firebase/dev/GoogleService-Info.plist    (iOS)
   firebase/prod/google-services.json       (Android - futuro)
   firebase/prod/GoogleService-Info.plist   (iOS - futuro)
   ```

2. Executar Flavorizr:

   ```bash
   flutter pub run flutter_flavorizr
   ```

---

## 🏃 Executando o App

### Modo Development

```bash
# Android
flutter run --flavor dev -t lib/main_dev.dart

# iOS
flutter run --flavor dev -t lib/main_dev.dart

# Especificar dispositivo
flutter run --flavor dev -t lib/main_dev.dart -d <device-id>
```

### Modo Production

```bash
flutter run --flavor prod -t lib/main_prod.dart
```

### Listar dispositivos disponíveis

```bash
flutter devices
```

---

## 🧪 Executando Testes

### Testes unitários

```bash
# Todos os testes
flutter test

# Testes específicos
flutter test test/domain/vehicle_test.dart

# Com cobertura
flutter test --coverage
```

### Visualizar cobertura (macOS/Linux)

```bash
# Gerar relatório HTML
genhtml coverage/lcov.info -o coverage/html

# Abrir no navegador
open coverage/html/index.html
```

---

## 📁 Estrutura de Pastas (Resumo)

```md
lib/
├─ main_dev.dart              # Entry point (dev)
├─ main_prod.dart             # Entry point (prod)
├─ application/               # Commands (casos de uso)
│  └─ commands/
│     ├─ auth/
│     ├─ vehicles/
│     └─ refuel/
├─ core/                      # Infraestrutura compartilhada
│  ├─ di/                     # Injeção de dependências
│  ├─ errors/                 # Failures
│  ├─ validators/
│  ├─ extensions/
│  └─ helpers/
├─ domain/                    # Entidades + Contratos
│  ├─ entities/
│  ├─ repositories/
│  └─ services/
├─ data/                      # Implementações
│  ├─ local/
│  │  ├─ dao/
│  │  ├─ db/
│  │  └─ tables/
│  ├─ mappers/
│  └─ repositories/
├─ presentation/              # UI
│  ├─ screens/
│  │  ├─ auth/
│  │  ├─ vehicle/
│  │  └─ refuel/
│  └─ widgets/
└─ theme/                     # Tema e estilos
```

---

## 🛠️ Ferramentas e Comandos Úteis

### Análise de código

```bash
# Verificar problemas
flutter analyze

# Formatar código
dart format lib/ test/

# Verificar formatting sem aplicar
dart format --set-exit-if-changed lib/
```

### Build Runner

```bash
# Regenerar código (Drift, Injectable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Modo watch (auto-regenera)
flutter pub run build_runner watch
```

### Flavorizr

```bash
# Regenerar configuração de flavors
flutter pub run flutter_flavorizr
```

### Limpar build cache

```bash
# Limpar cache Flutter
flutter clean

# Reinstalar dependências
flutter pub get

# Regenerar código
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📝 Fluxo de Desenvolvimento

### 1. Implementar nova feature

#### Exemplo: Adicionar campo "cor" ao veículo

1. **Atualizar entidade (Domain)**

   ```dart
   // lib/domain/entities/vehicle.dart
   class VehicleEntity {
     final String color; // novo campo
     // ...
   }
   ```

2. **Atualizar tabela (Data)**

   ```dart
   // lib/data/local/tables/vehicle_table.dart
   class VehicleTable extends Table {
     TextColumn get color => text().nullable()();
     // ...
   }
   ```

3. **Regenerar Drift**

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Atualizar Mapper**

   ```dart
   // lib/data/mappers/vehicle_mapper.dart
   static VehicleEntity toDomain(VehicleTableData data) {
     return VehicleEntity(
       color: data.color,
       // ...
     );
   }
   ```

5. **Atualizar UI**

   ```dart
   // lib/presentation/screens/vehicle/vehicle_form_screen.dart
   // Adicionar campo de cor no formulário
   ```

6. **Testar**

   ```bash
   flutter test test/domain/entities/vehicle_test.dart
   ```

---

### 2. Adicionar novo Command

1. **Criar arquivo de Command**

   ```dart
   // lib/application/commands/vehicles/get_vehicle_by_color_command.dart
   class GetVehicleByColorCommand {
     final VehicleRepository _repository;
     
     GetVehicleByColorCommand({required VehicleRepository repository})
         : _repository = repository;
     
     Future<Either<Failure, List<VehicleEntity>>> call(String color) async {
       final result = await _repository.getAllByUserId(currentUserId);
       return result.map((vehicles) => 
         vehicles.where((v) => v.color == color).toList()
       );
     }
   }
   ```

2. **Registrar no DI (GetIt)**

   ```dart
   // lib/core/di/injection.dart
   getIt.registerFactory(() => GetVehicleByColorCommand(
     repository: getIt<VehicleRepository>(),
   ));
   ```

3. **Usar na UI**

   ```dart
   final command = getIt<GetVehicleByColorCommand>();
   final result = await command.call('red');
   ```

---

### 3. Criar nova tela

1. **Criar arquivo de tela**

   ```dart
   // lib/presentation/screens/vehicle/vehicle_detail_screen.dart
   class VehicleDetailScreen extends StatelessWidget {
     final String vehicleId;
     
     const VehicleDetailScreen({required this.vehicleId});
     
     @override
     Widget build(BuildContext context) {
       // UI implementation
     }
   }
   ```

2. **Adicionar rota**

   ```dart
   // lib/presentation/routes/app_routes.dart
   GoRoute(
     path: '/vehicle/:id',
     builder: (context, state) {
       final vehicleId = state.pathParameters['id']!;
       return VehicleDetailScreen(vehicleId: vehicleId);
     },
   ),
   ```

3. **Navegar**

   ```dart
   context.go('/vehicle/$vehicleId');
   ```

---

## 🐛 Troubleshooting

### Problema: Erro de build_runner

**Sintoma:** `build_runner` falha ao gerar código

**Solução:**

```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Problema: Erro de DI (GetIt)

**Sintoma:** `Object/factory with type X is not registered inside GetIt`

**Solução:**

1. Verificar se o objeto está registrado em `lib/core/di/injection.dart`
2. Verificar se `setupDI()` está sendo chamado no `main.dart`

---

### Problema: Firebase não configurado

**Sintoma:** App crasha ao iniciar com erro do Firebase

**Solução:**

1. Verificar se arquivos `google-services.json` e `GoogleService-Info.plist` estão presentes
2. Executar `flutter pub run flutter_flavorizr` novamente
3. Fazer rebuild completo:

   ```bash
   flutter clean
   flutter pub get
   flutter run --flavor dev -t lib/main_dev.dart
   ```

---

### Problema: Drift migrations

**Sintoma:** Erro de schema do banco após alterar tabelas

**Solução:**

1. Incrementar `schemaVersion` em `database.dart`
2. Adicionar migration:

   ```dart
   @override
   MigrationStrategy get migration => MigrationStrategy(
     onUpgrade: (migrator, from, to) async {
       if (from == 1) {
         await migrator.addColumn(vehicleTable, vehicleTable.color);
       }
     },
   );
   ```

3. Ou deletar o banco (apenas em dev):

   ```bash
   # Limpar dados do app no simulador/emulador
   ```

---

## 📚 Recursos Úteis

### Documentação oficial

- [Flutter](https://flutter.dev/docs)
- [Dart](https://dart.dev/guides)
- [Drift](https://drift.simonbinder.eu/)
- [Firebase](https://firebase.google.com/docs)
- [GoRouter](https://pub.dev/packages/go_router)

### Documentação do projeto

- [README Principal](./README.md)
- [Domínio Auth](./domain-auth.md)
- [Domínio Vehicle](./domain-vehicle.md)
- [Domínio Refuel](./domain-refuel.md)
- [Domínio Core](./domain-core.md)

---

## ✅ Checklist de Setup Completo

- [ ] Flutter instalado e atualizado
- [ ] Repositório clonado
- [ ] Dependências instaladas (`flutter pub get`)
- [ ] Código gerado (`build_runner build`)
- [ ] Firebase configurado (google-services.json, GoogleService-Info.plist)
- [ ] Flavorizr executado
- [ ] App rodando em ambiente dev
- [ ] Testes passando (`flutter test`)
- [ ] IDE configurada (extensions, formatters)

---

## 🎯 Próximos Passos

1. Ler [README principal](./README.md)
2. Estudar [Clean Architecture](./README.md#princípios-arquiteturais)
3. Revisar documentação de cada domínio
4. Explorar código existente
5. Implementar primeira feature seguindo padrões estabelecidos

---

**Bem-vindo ao Gasosa App! 🚗⛽**
