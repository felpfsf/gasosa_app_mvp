# Skills do Gasosa App

**Conhecimento reutilizável e convenções compartilhadas**

---

## Visão Geral

Skills são **padrões e convenções documentados** que servem como referência para agentes especializados e desenvolvedores do Gasosa App.

Cada skill documenta:

- **Visão geral** do padrão/convenção
- **Exemplos práticos** de implementação
- **Checklist de validação**
- **Referências** para documentação detalhada

---

## Skills Disponíveis

### [gasosa-architecture-principles.skill.md](./gasosa-architecture-principles.skill.md)

**Princípios de Clean Architecture + DDD light**

Documenta:

- Separação de camadas (Presentation → Application → Domain → Data)
- Regras de dependência
- Domain é produto (puro, sem frameworks)
- Offline-first com Drift
- Injeção de dependências com GetIt

**Use quando:**

- Criar novas features/domínios
- Validar separação de camadas
- Refatorar código existente
- Tomar decisões arquiteturais

---

### [gasosa-command-pattern.skill.md](./gasosa-command-pattern.skill.md)

**Padrão Command (Use Cases)**

Documenta:

- Estrutura padrão de Commands
- Responsabilidades (orquestrar, validar, delegar)
- Padrões por tipo (Create, Read, Delete, Cálculos)
- Composição de Commands
- Testes de Commands

**Use quando:**

- Criar novos Commands
- Validar estrutura de use cases
- Entender fluxo de execução
- Escrever testes de Commands

---

### [gasosa-error-model.skill.md](./gasosa-error-model.skill.md)

**Tratamento funcional de erros**

Documenta:

- Either monad (`Either<Failure, Result>`)
- Hierarchy de Failures (ValidationFailure, DatabaseFailure, etc.)
- Padrões de uso (Commands, Repositories, ViewModels)
- Composição de Either (flatMap, fold)
- Display de erros na UI

**Use quando:**

- Implementar tratamento de erros
- Criar novos tipos de Failure
- Entender fluxo de erros
- Mapear exceptions para Failures

---

### [gasosa-drift-conventions.skill.md](./gasosa-drift-conventions.skill.md)

**Persistência local com Drift (SQLite)**

Documenta:

- Convenções de nomenclatura (Tables, Columns, DAOs)
- Definição de Tables (constraints, foreign keys, índices)
- DAOs (queries, streams, transactions)
- Migrations seguras (versionamento, tipos)
- Performance (índices, paginação, evitar N+1)

**Use quando:**

- Criar/alterar tables do Drift
- Escrever queries complexas
- Criar migrations
- Otimizar performance de banco

---

### [gasosa-firebase-conventions.skill.md](./gasosa-firebase-conventions.skill.md)

**Integração com Firebase**

Documenta:

- Firebase Auth (wrapper pattern, mapeamento de erros)
- Firebase Analytics (eventos, user properties, privacidade)
- Firebase Crashlytics (setup, logging, custom keys)
- Configuração por flavor (dev/prod)
- Testes (mocks de Firebase)

**Use quando:**

- Implementar autenticação
- Adicionar eventos de analytics
- Configurar crash reporting
- Garantir privacidade (não logar PII)

---

### [gasosa-viewmodel-pattern.skill.md](./gasosa-viewmodel-pattern.skill.md)

**Padrões e convenções de ViewModel**

Documenta:

- Responsabilidades da ViewModel vs. da Tela
- Tipo 1: formulário simples (valores no submit, sem campos públicos)
- Tipo 2: formulário com estado contínuo (`onChanged` + `updateX`)
- `Command<Unit>` — nunca `Command<void>`
- `flatMap`/`map` puros (sem side effects)
- Cast seguro de `Either` via `fold`
- Use Cases obrigatórios (sem bypass de serviços)
- `dispose()` na tela

**Use quando:**

- Criar novas ViewModels
- Revisar ViewModels existentes
- Decidir onde colocar `TextEditingController`s
- Entender o padrão `ValueNotifier` + `Command<T>`

---

### [gasosa-testing-strategy.skill.md](./gasosa-testing-strategy.skill.md)

**Estratégia de testes**

Documenta:

- Pirâmide de testes (70% unit, 20% widget, 10% integration)
- Cobertura por camada (100% Commands, 80% Repositories, 50% UI)
- Templates de testes (Commands, Widgets, Mappers, Repositories)
- Factories e mocks reutilizáveis
- Regras de ouro (nomenclatura, isolamento, AAA)

**Use quando:**

- Criar testes unitários
- Escrever widget tests
- Aumentar cobertura
- Criar mocks/factories

---

## Como Usar

### 1. Antes de Implementar

Leia a skill relevante para entender o padrão:

```
Antes de criar um novo Command, leia gasosa-command-pattern.skill.md 
para entender a estrutura padrão.
```

### 2. Durante Code Review

Valide contra checklist da skill:

```
Este Command segue o padrão gasosa-command-pattern?
- [ ] Retorna Either<Failure, Result>?
- [ ] Validações no início (fail fast)?
- [ ] Delega persistência para Repository?
```

### 3. Com Agentes de IA

Agentes referenciam skills automaticamente:

```
@domain-core crie um Command para calcular consumo médio.

(domain-core consulta gasosa-command-pattern.skill.md antes de implementar)
```

---

## Manutenção

### Atualizar Skill

Quando padrões evoluírem, atualize o arquivo correspondente:

```bash
# Exemplo: atualizar convenção de testes
vim .github/skills/gasosa-testing-strategy.skill.md
```

### Adicionar Nova Skill

1. Crie arquivo em `.github/skills/`
2. Use template padrão:

   ```markdown
   # Skill — Gasosa [Nome da Skill]
   
   ## Visão Geral
   ...
   
   ## [Seção Principal]
   ...
   
   ## Checklist de Qualidade
   ...
   
   ## Referências
   ...
   ```

3. Atualize este README
4. Referencie em agentes relevantes

---

## Referências

- **Agents:** [/agents/README.md](../agents/README.md) → Agentes especializados
- **Docs:** [/docs/](../../docs/) → Documentação completa do projeto
- **Testing:** [/docs/testing-strategy.md](../../docs/testing-strategy.md)

---

**Última atualização:** Março 2026  
**Versão:** 1.0.0
