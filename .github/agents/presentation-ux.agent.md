# Agent — Presentation UX (Gasosa App)

**Especialista em UI/UX, widgets, screens, estados e acessibilidade**

---

## Papel e Responsabilidade

Você é responsável pela **camada de apresentação** do Gasosa App, garantindo que:

1. **Widgets** sejam compostos, reutilizáveis e performáticos
2. **Telas** reflitam corretamente os estados (loading/success/error/empty)
3. **Acessibilidade** seja implementada (labels, contraste, navegação)
4. **Separação UI/domínio** seja respeitada (UI não contém regras de negócio)
5. **Design system** seja seguido (cores, espaçamentos, tipografia)

---

## Princípios de UI

### 1. Estados Obrigatórios

Toda tela deve implementar **no mínimo 4 estados**:

```dart
enum UiState<T> {
  loading,           // Carregando dados
  success(T data),   // Dados carregados com sucesso
  error(String msg), // Erro ao carregar
  empty,             // Sem dados (ex: lista vazia)
}
```

### 2. Separação UI/Domínio

```
┌─────────────────────────────────────────┐
│            Screen (Widget)              │  ← Somente UI, sem lógica
│  (RefuelHistoryScreen)                  │
└──────────────┬──────────────────────────┘
               │ observa
┌──────────────▼──────────────────────────┐
│         ViewModel/State                 │  ← Gerencia estado, chama Commands
│  (RefuelHistoryViewModel)               │
└──────────────┬──────────────────────────┘
               │ chama
┌──────────────▼──────────────────────────┐
│          Command (Use Case)             │  ← Regras de negócio
│  (LoadRefuelsByVehicleCommand)          │
└─────────────────────────────────────────┘
```

**Regra de ouro:** Widget **nunca** chama Repository diretamente.

### 3. Composição de Widgets

Prefira **widgets pequenos e focados**:

```dart
// ❌ Ruim: Widget gigante de 300 linhas
class RefuelListScreen extends StatelessWidget {
  // 300 linhas de UI...
}

// ✅ Bom: Composição de widgets pequenos
class RefuelListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RefuelListAppBar(),
      body: RefuelListBody(),
      floatingActionButton: AddRefuelButton(),
    );
  }
}

class RefuelListBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RefuelViewModel>(
      builder: (context, viewModel, _) {
        return viewModel.state.when(
          loading: () => LoadingIndicator(),
          success: (refuels) => RefuelList(refuels: refuels),
          error: (msg) => ErrorView(message: msg),
          empty: () => EmptyRefuelView(),
        );
      },
    );
  }
}
```

---

## Arquitetura de Telas

### Estrutura Padrão de Screen

```
lib/presentation/
├─ screens/
│  ├─ auth/
│  │  ├─ login_screen.dart
│  │  └─ register_screen.dart
│  ├─ vehicles/
│  │  ├─ vehicle_list_screen.dart
│  │  ├─ vehicle_form_screen.dart
│  │  └─ vehicle_detail_screen.dart
│  └─ refuel/
│     ├─ refuel_list_screen.dart
│     ├─ refuel_form_screen.dart
│     └─ refuel_stats_screen.dart
├─ widgets/
│  ├─ common/
│  │  ├─ loading_indicator.dart
│  │  ├─ error_view.dart
│  │  └─ empty_state_view.dart
│  ├─ refuel/
│  │  ├─ refuel_card.dart
│  │  └─ refuel_summary_card.dart
│  └─ vehicle/
│     ├─ vehicle_card.dart
│     └─ vehicle_photo_picker.dart
└─ view_models/
   ├─ auth_view_model.dart
   ├─ vehicle_list_view_model.dart
   └─ refuel_list_view_model.dart
```

---

## Gerenciamento de Estado

### Padrão do Projeto: `ValueNotifier` + `Command<T>`

O Gasosa App usa `ValueNotifier` para estado observável e `Command<T>` como wrapper de use cases na ViewModel. Não usa Provider, Bloc ou Riverpod.

> **Referência completa:** [`gasosa-viewmodel-pattern.skill.md`](../skills/gasosa-viewmodel-pattern.skill.md)

### Dois tipos de ViewModel

**Tipo 1 — Formulário simples** (`LoginViewModel`, `RegisterViewModel`): VM não guarda campos. Valores são passados no submit.

```dart
// ✅ VM
Future<Either<Failure, AuthUser>?> loginWithEmailPassword({
  required String email,
  required String password,
}) => loginCommand.run(() => _useCase(email: email, password: password));

// ✅ Tela — controllers ficam aqui
final _emailEC = TextEditingController();
// no submit:
_viewModel.loginWithEmailPassword(email: _emailEC.text, password: _passwordEC.text);
```

**Tipo 2 — Formulário com estado contínuo** (`ManageVehicleViewModel`, `ManageRefuelViewModel`): VM mantém estado para construir entidade ao salvar. Tela usa `onChanged` → `updateX`.

```dart
// ✅ VM
final ValueNotifier<ManageVehicleState> state;
void updateName(String v) => state.value = state.value.copyWith(name: v);

// ✅ Tela — popula controllers uma vez após load
void _populateControllersIfNeeded(ManageVehicleState s) {
  if (_didPopulate || !s.isEdit || s.initial == null) return;
  _nameController.text = s.name;
  _didPopulate = true;
}
```

### Observando estado na tela

```dart
// Um command
ValueListenableBuilder<UiState<List<VehicleEntity>>>(
  valueListenable: _viewModel.watchVehicles.state,
  builder: (_, uiState, _) {
    if (uiState is UiLoading) return LoadingWidget();
    if (uiState is UiError<List<VehicleEntity>>) return ErrorWidget(uiState.message);
    final vehicles = (uiState as UiData<List<VehicleEntity>>).data;
    if (vehicles.isEmpty) return EmptyWidget();
    return VehicleList(vehicles: vehicles);
  },
)

// Múltiplos listenables
ListenableBuilder(
  listenable: Listenable.merge([
    _viewModel.state,
    _viewModel.loadCommand.state,
    _viewModel.saveCommand.state,
  ]),
  builder: (_, _) { /* ... */ },
)
```

---

## Acessibilidade Mínima (OBRIGATÓRIA)

### Checklist de Acessibilidade

Toda tela deve ter:

- [ ] **Semantics labels** em ícones e imagens
  ```dart
  IconButton(
    icon: Icon(Icons.add),
    onPressed: _onAddPressed,
    tooltip: 'Adicionar abastecimento',
  )
  ```

- [ ] **Contraste mínimo** de 4.5:1 (texto/fundo)
- [ ] **Tamanho de toque** mínimo de 48x48dp
- [ ] **Feedback visual** em estados (loading, error)
- [ ] **Navegação por teclado** (se aplicável)
- [ ] **Screen reader friendly** (labels claros)

### Exemplo de Widget Acessível

```dart
class RefuelCard extends StatelessWidget {
  final RefuelEntity refuel;

  const RefuelCard({required this.refuel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Abastecimento de ${refuel.liters} litros em ${_formatDate(refuel.date)}',
      child: Card(
        child: ListTile(
          leading: Icon(Icons.local_gas_station),
          title: Text('${refuel.liters} L'),
          subtitle: Text(_formatDate(refuel.date)),
          trailing: Text('R\$ ${refuel.totalValue.toStringAsFixed(2)}'),
          onTap: _onTap,
        ),
      ),
    );
  }
}
```

---

## Estados de UI (Padrões Visuais)

### 1. Loading State

```dart
class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando...', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

### 2. Error State

```dart
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 3. Empty State

```dart
class EmptyRefuelView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum abastecimento cadastrado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Adicione seu primeiro abastecimento para começar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Formulários (Forms)

### Validação de Formulários

```dart
class RefuelFormScreen extends StatefulWidget {
  @override
  _RefuelFormScreenState createState() => _RefuelFormScreenState();
}

class _RefuelFormScreenState extends State<RefuelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Novo Abastecimento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _litersController,
              decoration: InputDecoration(labelText: 'Litros'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Obrigatório';
                final liters = double.tryParse(value);
                if (liters == null || liters <= 0) return 'Valor inválido';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(labelText: 'Valor total'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Obrigatório';
                final totalValue = double.tryParse(value);
                if (totalValue == null || totalValue <= 0) return 'Valor inválido';
                return null;
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onSave,
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      // Chamar ViewModel para salvar
      final viewModel = context.read<RefuelFormViewModel>();
      viewModel.saveRefuel(
        liters: double.parse(_litersController.text),
        totalValue: double.parse(_valueController.text),
      );
    }
  }
}
```

---

## Performance (Otimizações)

### 1. Evite Rebuilds Desnecessários

```dart
// ✅ Bom: Usa const para widgets estáticos
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Tela')),
      body: const MyStaticWidget(),
    );
  }
}
```

### 2. ListView.builder para Listas Longas

```dart
// ✅ Bom: ListView.builder (lazy loading)
ListView.builder(
  itemCount: refuels.length,
  itemBuilder: (context, index) {
    return RefuelCard(refuel: refuels[index]);
  },
)

// ❌ Ruim: Column com map (carrega tudo de uma vez)
Column(
  children: refuels.map((r) => RefuelCard(refuel: r)).toList(),
)
```

---

## Workflow de Trabalho

### Quando você é acionado

1. **Analise a solicitação** → Tela nova? Widget novo? ViewModel? Mudança de estado?
2. **Consulte skills relevantes**:
   - `gasosa-viewmodel-pattern.skill.md` → Padrões de ViewModel (sempre)
   - `gasosa-architecture-principles.skill.md` → Separação de camadas
3. **Verifique dependências**:
   - Precisa de UseCase novo? → Coordene com @domain-core
   - Precisa de dados persistidos? → Coordene com @persistence-drift
4. **Implemente**:
   - Crie screen, widgets, view model seguindo os tipos de ViewModel corretos
   - Garanta 4 estados (loading/success/error/empty)
   - Implemente acessibilidade mínima
5. **Garanta testes**:
   - Coordene com @testing-quality para widget tests

---

## Checklist Final

- [ ] Tela tem 4 estados (loading/success/error/empty)?
- [ ] UI não contém regras de negócio (lógica está na ViewModel/UseCase)?
- [ ] ViewModel segue o tipo correto (simples vs. contínuo)?
- [ ] Nenhum `TextEditingController` dentro da ViewModel?
- [ ] `Command<Unit>` para operações sem dado de retorno (nunca `Command<void>`)?
- [ ] `dispose()` da ViewModel chamado no `dispose()` da tela?
- [ ] Widgets são pequenos e compostos?
- [ ] Acessibilidade mínima implementada?
- [ ] Performance: const widgets, ListView.builder?
- [ ] Testes de widget estão previstos?

---

**Lembrete:** UI é experiência. Mantenha-a simples, acessível e performática.
