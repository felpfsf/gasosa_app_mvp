# Agentes e Skills do Gasosa App

**Sistema de agentes especializados e skills reutilizáveis para desenvolvimento com IA**

---

## Visão Geral

O Gasosa App utiliza uma arquitetura de **agentes especializados** para maximizar produtividade e manter consistência arquitetural ao desenvolver com assistentes de IA (GitHub Copilot, ChatGPT, etc.).

### Estrutura

```
.github/
├── agents/
│   ├── orchestrator.agent.md
│   ├── domain-core.agent.md
│   ├── presentation-ux.agent.md
│   ├── persistence-drift.agent.md
│   ├── firebase-integration.agent.md
│   ├── testing-quality.agent.md
│   ├── navigation-routing.agent.md
│   └── release-hygiene.agent.md
├── skills/
│   ├── gasosa-architecture-principles.skill.md
│   ├── gasosa-command-pattern.skill.md
│   ├── gasosa-error-model.skill.md
│   ├── gasosa-drift-conventions.skill.md
│   ├── gasosa-firebase-conventions.skill.md
│   └── gasosa-testing-strategy.skill.md
└── pull_request_template.md
```

---

## Agentes Disponíveis

### [orchestrator.agent.md](./orchestrator.agent.md)
**Coordenador principal** que roteia solicitações para agentes especializados.

**Use quando:**
- Não souber qual agente acionar
- Tarefa envolve múltiplos domínios
- Precisar de planejamento de alto nível

### [domain-core.agent.md](./domain-core.agent.md)
**Especialista em domínio de negócio**, entidades, Commands e regras de validação.

**Use quando:**
- Criar/alterar entidades (VehicleEntity, RefuelEntity, etc.)
- Implementar novos Commands (use cases)
- Adicionar regras de negócio
- Definir interfaces de Repository

### [presentation-ux.agent.md](./presentation-ux.agent.md)
**Especialista em UI/UX**, widgets, screens, estados e acessibilidade.

**Use quando:**
- Criar novas telas/widgets
- Implementar estados de UI (loading/error/empty)
- Melhorar acessibilidade
- Refatorar componentes visuais

### [persistence-drift.agent.md](./persistence-drift.agent.md)
**Especialista em persistência local** com Drift (SQLite).

**Use quando:**
- Criar/alterar tables do Drift
- Escrever queries complexas (JOINs, agregações)
- Criar migrations
- Otimizar performance de banco de dados

### [firebase-integration.agent.md](./firebase-integration.agent.md)
**Especialista em integração com Firebase** (Auth, Analytics, Crashlytics).

**Use quando:**
- Implementar fluxos de autenticação
- Adicionar eventos de analytics
- Configurar crash reporting
- Integrar novos serviços Firebase

### [testing-quality.agent.md](./testing-quality.agent.md)
**Especialista em testes, mocks, cobertura e qualidade** de código.

**Use quando:**
- Criar testes unitários de Commands
- Escrever widget tests
- Aumentar cobertura de testes
- Criar mocks e factories

### [navigation-routing.agent.md](./navigation-routing.agent.md)
**Especialista em navegação**, rotas e deep links.

**Use quando:**
- Adicionar novas rotas
- Configurar navegação complexa
- Implementar deep links
- Configurar guards de autenticação

### [release-hygiene.agent.md](./release-hygiene.agent.md)
**Especialista em release, CI/CD, versionamento** e deploy.

**Use quando:**
- Preparar release para produção
- Configurar CI/CD (GitHub Actions)
- Atualizar changelog
- Configurar flavors (dev/prod)

---

## Skills Disponíveis

Skills são **conhecimento reutilizável** compartilhado entre agentes.

### [gasosa-architecture-principles.skill.md](../skills/gasosa-architecture-principles.skill.md)
Princípios de Clean Architecture + DDD light do Gasosa App.

### [gasosa-command-pattern.skill.md](../skills/gasosa-command-pattern.skill.md)
Padrão Command (use cases) usado no Gasosa App.

### [gasosa-error-model.skill.md](../skills/gasosa-error-model.skill.md)
Modelo de tratamento de erros com Either e Failures.

### [gasosa-drift-conventions.skill.md](../skills/gasosa-drift-conventions.skill.md)
Convenções para persistência local com Drift (SQLite).

### [gasosa-firebase-conventions.skill.md](../skills/gasosa-firebase-conventions.skill.md)
Convenções para integração com Firebase (Auth, Analytics, Crashlytics).

### [gasosa-testing-strategy.skill.md](../skills/gasosa-testing-strategy.skill.md)
Estratégia de testes do Gasosa App.

---

## Como Usar

### 1. Com GitHub Copilot Chat

```
@workspace Use o agente @domain-core para criar um novo Command 
que calcule o custo médio por km de um veículo.

Antes de começar, leia a skill gasosa-command-pattern.skill.md 
para entender o padrão.
```

### 2. Com ChatGPT/Claude

```
Leia o arquivo .github/agents/domain-core.agent.md e a skill 
gasosa-command-pattern.skill.md.

Depois, me ajude a criar um Command que calcule o custo médio 
por km de um veículo.
```

### 3. Workflow Recomendado

1. **Analise a tarefa** → Qual domínio está envolvido?
2. **Escolha o agente** → Use orchestrator se estiver em dúvida
3. **Consulte skills** → Leia skills relevantes antes de implementar
4. **Implemente** → Siga as convenções documentadas
5. **Teste** → Use testing-quality para criar testes

---

## Árvore de Decisão Rápida

```
Minha tarefa envolve:

├─ Entidades/Commands/Regras de negócio?
│  └─→ @domain-core
│
├─ UI/Widgets/Telas?
│  └─→ @presentation-ux
│
├─ Drift/SQLite/Migrations?
│  └─→ @persistence-drift
│
├─ Firebase (Auth/Analytics/Crashlytics)?
│  └─→ @firebase-integration
│
├─ Navegação/Rotas?
│  └─→ @navigation-routing
│
├─ Testes/Mocks/Cobertura?
│  └─→ @testing-quality
│
├─ Release/CI/CD?
│  └─→ @release-hygiene
│
└─ Não sei / Multidisciplinar?
   └─→ @orchestrator
```

---

## Princípios de Uso

1. **Sempre consulte skills antes de implementar** → Evita reinventar padrões
2. **Um agente por vez** → Foco e clareza
3. **Valide com testes** → Use @testing-quality após implementação
4. **Atualize documentação** se necessário

---

## Manutenção

### Atualizar Agentes/Skills

Quando padrões evoluírem, atualize os arquivos correspondentes em `.github/agents/` e `.github/skills/`.

### Adicionar Novo Agente

1. Crie arquivo `novo-agente.agent.md` em `.github/agents/`
2. Adicione referência no `orchestrator.agent.md`
3. Atualize este README

### Adicionar Nova Skill

1. Crie arquivo `gasosa-nova-skill.skill.md` em `.github/skills/`
2. Referencie em agentes relevantes
3. Atualize este README

---

## Referências

- **Docs:** [/docs/](../../docs/) → Documentação completa do projeto
- **Playbook:** [/docs/playbook.md](../../docs/playbook.md) → Guia de uso de IA
- **Testing Strategy:** [/docs/testing-strategy.md](../../docs/testing-strategy.md)

---

**Última atualização:** Março 2026  
**Versão:** 1.0.0
