# Agents — Gasosa App

Este diretório define agentes especializados para acelerar o desenvolvimento do Gasosa com consistência técnica.

## Como usar (regra simples)

1) Sempre comece com o `base.md`.
2) Para uma tarefa, combine `base.md` + 1 agente especialista.
3) Se a tarefa envolver duas áreas (ex: segurança + observabilidade), combine `base.md` + `security.md` + `observability.md`.

## Agentes disponíveis

- `base.md` — Guardião do projeto (arquitetura, padrões, decisões)
- `ux-ui.md` — UX/UI sem Figma (fluxos, componentes, consistência visual)
- `security.md` — Hardening pré-loja (pragmático, sem paranoia enterprise)
- `observability.md` — Tracking de erros e saúde (crash, logs, breadcrumbs, eventos)
- `tests.md` — Estratégia e implementação de testes (unit, integration, widget)

## Saída padrão (o que o agente deve entregar)

Todo agente deve responder, quando aplicável, nesta ordem:

1) **Plano curto** (3–7 passos)
2) **Decisões e trade-offs** (quando houver)
3) **Snippets** (código/estrutura)
4) **Checklist de validação**
5) **Sugestões de testes** (ou links para o agente `tests.md`)
