## Descrição

<!-- Descreva brevemente as mudanças deste PR -->

## Tipo de mudança

- [ ] 🐛 Bug fix (correção que resolve um problema)
- [ ] ✨ Feature (nova funcionalidade)
- [ ] 💥 Breaking change (mudança que quebra compatibilidade)
- [ ] ♻️ Refactor (mudança de código sem alterar funcionalidade)
- [ ] 📝 Docs (atualização de documentação)
- [ ] 🎨 UI (mudanças visuais)
- [ ] ⚡ Performance (melhoria de performance)
- [ ] ✅ Tests (adição/atualização de testes)

## Domínio Afetado

- [ ] Auth (Autenticação)
- [ ] Vehicle (Veículos)
- [ ] Refuel (Abastecimentos)
- [ ] Core (Infraestrutura compartilhada)
- [ ] UI/UX (Apresentação)
- [ ] Firebase (Integração)
- [ ] Drift (Persistência local)
- [ ] Outro: _______________

## Checklist de Qualidade

### Código
- [ ] Código segue as convenções do projeto (Clean Architecture + DDD light)
- [ ] Separação de camadas respeitada (Presentation → Application → Domain → Data)
- [ ] Commands retornam `Either<Failure, Result>`
- [ ] Entidades são imutáveis (usam `copyWith`)
- [ ] Sem lógica de negócio na UI

### Testes
- [ ] Testes unitários foram adicionados/atualizados
- [ ] Testes de Commands cobrem casos de sucesso e erro
- [ ] Todos os testes passam (`flutter test`)
- [ ] Cobertura de testes está adequada por camada:
  - [ ] Domain/Commands: 100%
  - [ ] Data/Repositories: 80%+
  - [ ] UI/Widgets: 50%+

### Qualidade
- [ ] Análise estática limpa (`flutter analyze`)
- [ ] Sem warnings de linter
- [ ] Código formatado (`dart format .`)

### Firebase
- [ ] Analytics não loga PII (email, nome, CPF, etc.)
- [ ] Crashlytics configurado para erros não fatais
- [ ] Eventos de analytics têm nomes descritivos (snake_case)

### Drift (se aplicável)
- [ ] Tables seguem convenções (plural, PascalCase)
- [ ] Foreign keys têm `ON DELETE CASCADE`
- [ ] Migration criada e versionada
- [ ] Índices criados para queries frequentes

### Documentação
- [ ] README atualizado (se aplicável)
- [ ] Changelog atualizado (se feature/fix relevante)
- [ ] Comentários adicionados em código complexo
- [ ] Domain docs atualizados (`docs/domain-*.md`)

## Como testar

<!-- Descreva os passos para testar as mudanças -->

1. ...
2. ...

## Screenshots / GIFs (se aplicável)

<!-- Adicione screenshots ou GIFs das mudanças visuais -->

## Impacto

<!-- Descreva o impacto desta mudança -->

- **Performance**: [ ] Melhora | [ ] Neutro | [ ] Piora  
- **Tamanho do app**: [ ] Cresce | [ ] Neutro | [ ] Diminui  
- **Breaking change?**: [ ] Sim | [x] Não

## Dependências

<!-- Este PR depende de outros PRs? Liste aqui -->

## Notas Adicionais

<!-- Qualquer informação adicional relevante -->

---

**Revisão sugerida por agente**: (marque qual agente deveria revisar)
- [ ] @domain-core (entidades, Commands, regras de negócio)
- [ ] @presentation-ux (UI, widgets, acessibilidade)
- [ ] @persistence-drift (Drift, migrations)
- [ ] @firebase-integration (Auth, Analytics, Crashlytics)
- [ ] @testing-quality (testes, cobertura)
- [ ] @navigation-routing (rotas, navegação)
- [ ] @release-hygiene (CI/CD, versionamento)
