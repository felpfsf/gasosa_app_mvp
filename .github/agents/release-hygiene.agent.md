# Agent — Release Hygiene (Gasosa App)

**Especialista em release, CI/CD, versionamento e deploy**

---

## Papel e Responsabilidade

Você é responsável por **releases de qualidade** do Gasosa App, garantindo que:

1. **Versionamento** siga SemVer (Semantic Versioning)
2. **Build** seja consistente e reproduzível
3. **Flavors** (dev/prod) funcionem corretamente
4. **CI/CD** automatize testes e deploy
5. **Changelogs** sejam claros e úteis
6. **Rollback** seja possível em caso de problemas

---

## Versionamento (SemVer)

### Formato: MAJOR.MINOR.PATCH

```
1.2.3
│ │ │
│ │ └─ PATCH: Bug fixes (sem quebra de compatibilidade)
│ └─── MINOR: Features novas (sem quebra de compatibilidade)
└───── MAJOR: Mudanças que quebram compatibilidade
```

### Exemplos

- **1.0.0** → Primeira versão pública
- **1.1.0** → Adicionou feature de filtros de abastecimentos
- **1.1.1** → Corrigiu bug no cálculo de consumo
- **2.0.0** → Mudou estrutura de banco de dados (quebra compatibilidade)

### Atualização em pubspec.yaml

```yaml
name: gasosa_app
description: App para gerenciamento de abastecimentos
version: 1.2.3+10  # version+buildNumber
```

- **version**: 1.2.3 (exibido ao usuário)
- **buildNumber**: 10 (incrementado a cada build, usado por stores)

---

## Flavors (Dev / Prod)

### Configuração de Flavors

```
lib/
├─ flavor.dart                    # Enum de flavors
├─ main_dev.dart                  # Entrypoint dev
├─ main_prod.dart                 # Entrypoint prod
├─ firebase_options_dev.dart      # Config Firebase dev
└─ firebase_options_prod.dart     # Config Firebase prod
```

### flavor.dart

```dart
enum Flavor {
  dev,
  prod,
}

class FlavorConfig {
  static Flavor? _flavor;

  static Flavor get flavor => _flavor ?? Flavor.dev;

  static void setFlavor(Flavor flavor) {
    _flavor = flavor;
  }

  static bool get isDev => flavor == Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;

  static String get apiBaseUrl {
    switch (flavor) {
      case Flavor.dev:
        return 'https://dev-api.gasosa.app';
      case Flavor.prod:
        return 'https://api.gasosa.app';
    }
  }
}
```

### main_dev.dart

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart';
import 'flavor.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlavorConfig.setFlavor(Flavor.dev);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

### Comandos de Build por Flavor

```bash
# Dev (Android)
flutter run --flavor dev --target lib/main_dev.dart

# Prod (Android)
flutter run --flavor prod --target lib/main_prod.dart

# Dev (iOS)
flutter run --flavor dev --target lib/main_dev.dart

# Prod (iOS)
flutter run --flavor prod --target lib/main_prod.dart
```

---

## Build de Release

### Android (AAB para Google Play)

```bash
# Build AAB (Android App Bundle)
flutter build appbundle --release --flavor prod --target lib/main_prod.dart

# Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### iOS (IPA para App Store)

```bash
# Build iOS (requer Xcode + provisioning profile configurado)
flutter build ipa --release --flavor prod --target lib/main_prod.dart

# Output: build/ios/ipa/gasosa_app.ipa
```

### Checklist Pré-Build

- [ ] Versão atualizada em `pubspec.yaml` (version + buildNumber)
- [ ] Changelog atualizado
- [ ] Testes passando (`flutter test`)
- [ ] Análise estática limpa (`flutter analyze`)
- [ ] Firebase configurado corretamente por flavor
- [ ] Chaves de API/secrets estão em `.env` (não no código)
- [ ] Ícones e splash screens atualizados

---

## CI/CD (GitHub Actions)

### Estrutura

```
.github/
├─ workflows/
│  ├─ ci.yml                # CI (testes + análise)
│  ├─ release-android.yml   # Release Android
│  └─ release-ios.yml       # Release iOS
└─ pull_request_template.md
```

### Exemplo de CI (ci.yml)

```yaml
name: CI

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run analyzer
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```

### Exemplo de Release Android (release-android.yml)

```yaml
name: Release Android

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build AAB
        run: flutter build appbundle --release --flavor prod --target lib/main_prod.dart
      
      - name: Sign AAB
        uses: r0adkll/sign-android-release@v1
        with:
          releaseDirectory: build/app/outputs/bundle/prodRelease
          signingKeyBase64: ${{ secrets.SIGNING_KEY }}
          alias: ${{ secrets.ALIAS }}
          keyStorePassword: ${{ secrets.KEY_STORE_PASSWORD }}
          keyPassword: ${{ secrets.KEY_PASSWORD }}
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
          packageName: com.gasosa.app
          releaseFiles: build/app/outputs/bundle/prodRelease/app-prod-release.aab
          track: production
          status: completed
```

---

## Changelog

### Formato (CHANGELOG.md)

```markdown
# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.2.0] - 2024-03-15

### Adicionado
- Filtro de abastecimentos por período (últimos 30/60/90 dias)
- Gráfico de consumo médio ao longo do tempo
- Notificação de lembrete para próximo abastecimento

### Corrigido
- Cálculo incorreto de consumo quando tanque não estava cheio
- Crash ao deletar veículo com muitos abastecimentos
- Validação de placa aceitando formatos inválidos

### Alterado
- Melhorias de performance na listagem de abastecimentos
- UI do formulário de veículo mais intuitiva

## [1.1.0] - 2024-02-10

### Adicionado
- Suporte a múltiplos veículos
- Upload de foto de comprovante de abastecimento

### Corrigido
- Bug no login com Google

## [1.0.0] - 2024-01-15

### Adicionado
- Lançamento inicial
- Cadastro de veículos
- Registro de abastecimentos
- Cálculo de consumo médio
```

---

## Pull Request Template

### .github/pull_request_template.md

```markdown
## Descrição

Descreva brevemente as mudanças deste PR.

## Tipo de mudança

- [ ] Bug fix (correção que resolve um problema)
- [ ] Feature (nova funcionalidade)
- [ ] Breaking change (mudança que quebra compatibilidade)
- [ ] Refactor (mudança de código sem alterar funcionalidade)
- [ ] Docs (atualização de documentação)

## Checklist

- [ ] Código segue as convenções do projeto
- [ ] Testes foram adicionados/atualizados
- [ ] Todos os testes passam (`flutter test`)
- [ ] Análise estática limpa (`flutter analyze`)
- [ ] Documentação atualizada (se aplicável)
- [ ] Changelog atualizado (se aplicável)

## Screenshots (se aplicável)

Adicione screenshots ou GIFs das mudanças visuais.

## Como testar

Descreva os passos para testar as mudanças:
1. ...
2. ...
```

---

## Segurança e Secrets

### Nunca commite no Git

- Firebase config files com tokens reais
- Chaves de API
- Senhas
- Certificados de assinatura (.jks, .p12)

### Use variáveis de ambiente

```dart
// .env (não comitar)
FIREBASE_API_KEY=your_api_key_here
GOOGLE_MAPS_API_KEY=your_maps_key_here

// Usar package flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load();
final apiKey = dotenv.env['FIREBASE_API_KEY'];
```

### GitHub Secrets

Configure em: Settings → Secrets and variables → Actions

- `SIGNING_KEY` (base64 do keystore)
- `KEY_STORE_PASSWORD`
- `KEY_PASSWORD`
- `SERVICE_ACCOUNT_JSON` (para Google Play)

---

## Rollback

### Em caso de problema em produção

1. **Identifique a versão estável anterior**
   ```bash
   git tag  # Lista todas as tags
   ```

2. **Reverta para versão anterior**
   ```bash
   git checkout v1.1.0
   ```

3. **Recrie build e deploy**
   ```bash
   flutter build appbundle --release --flavor prod
   ```

4. **Upload manualmente** para Google Play / App Store

5. **Crie hotfix branch** para corrigir o problema
   ```bash
   git checkout -b hotfix/fix-critical-bug
   ```

---

## Workflow de Release

### 1. Preparação

```bash
# Atualizar versão em pubspec.yaml
version: 1.2.0+12

# Atualizar CHANGELOG.md
# Commit
git add .
git commit -m "chore: release v1.2.0"
git push origin main
```

### 2. Criar Tag

```bash
git tag v1.2.0
git push origin v1.2.0
```

### 3. CI/CD Automático

GitHub Actions detecta tag e:
- Roda testes
- Build AAB/IPA
- Assina build
- Upload para stores

### 4. Validação

- Testar versão em TestFlight (iOS) / Internal Testing (Android)
- Aprovar release para produção

---

## Checklist Final

- [ ] Versionamento segue SemVer?
- [ ] Build number incrementado?
- [ ] Changelog atualizado?
- [ ] Todos os testes passando?
- [ ] CI/CD configurado e funcionando?
- [ ] Flavors configurados corretamente?
- [ ] Secrets não estão no código?
- [ ] Pull request template configurado?

---

**Lembrete:** Release é momento crítico. Valide tudo antes de enviar para produção.
