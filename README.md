# Gasosa App (MVP)

Bem-vindo ao Gasosa App! Este projeto tem como objetivo oferecer uma solução simples e eficiente para motoristas acompanharem abastecimentos, consumo médio e histórico dos seus veículos. O app é construído em Flutter, utilizando Firebase para autenticação, Drift para persistência local offline-first, e segue padrões modernos de arquitetura.

## Visão Geral

- **Propósito**: Permitir o registro fácil de abastecimentos, cálculo de consumo médio, e visualização de histórico técnico para manutenção e controle de gastos.
- **Público-alvo**: Motoristas que buscam um histórico confiável do uso dos seus veículos, tanto para controle pessoal quanto para acompanhamento de manutenção.
- **Arquitetura**: Clean Architecture + Command Pattern, com foco em escalabilidade, manutenibilidade e testes.

## Principais Funcionalidades

- **Autenticação Firebase**: cadastro/login por e-mail/senha e Google.
- **CRUD de veículos**: com foto opcional, dados principais, exclusão em cascata.
- **CRUD de abastecimentos**: registro completo (data, tipo de combustível, litros, valores, partida a frio, comprovante opcional).
- **Cálculo de consumo médio**: baseado no histórico de abastecimentos.
- **Persistência local**: Drift (SQLite-like), mantendo dados offline e prontos para sincronização futura.
- **Interface moderna**: design system próprio, navegação com GoRouter, feedbacks visuais.

## Tecnologias Utilizadas

- **Flutter 3+**
- **Firebase Auth**
- **Drift** (persistência local)
- **GetIt** (injeção de dependências)
- **GoRouter** (navegação)
- **Dartz** (resultados funcionais)

## Organização do Projeto

- **lib/domain**: entidades e interfaces de domínio
- **lib/data**: DAOs, mapeadores e repositórios
- **lib/application**: Commands (padrão Command/UseCase)
- **lib/presentation**: telas, widgets e viewmodels
- **lib/core**: helpers, formatadores, validators, DI
- **lib/theme**: design system

## Principais Regras de Negócio

- Odômetro crescente por veículo
- Data de abastecimento não futura
- Valores/litros > 0
- Exclusão de veículo remove abastecimentos vinculados (cascade)
- Consumo médio exibido apenas com histórico suficiente

## Roadmap Resumido

1. Autenticação + Drift + DS
2. CRUD Veículos
3. CRUD Abastecimentos + Consumo
4. Polimentos, testes e refinamentos

## Como contribuir

Pull requests são bem-vindos! Veja o [PDS — Gasosa (MVP) v1.0.md] e as issues do projeto para mais detalhes do escopo, regras e sugestões de melhorias.

---

> Dúvidas, sugestões ou problemas? Abra uma issue ou entre in contato.
