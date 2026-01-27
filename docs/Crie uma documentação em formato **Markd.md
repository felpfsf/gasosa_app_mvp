Crie uma documentação em formato **Markdown (.md)** para o projeto **Gasosa App**, um aplicativo mobile desenvolvido em **Flutter**, com foco em registro de abastecimentos de veículos pessoais.

A documentação deve estar organizada **por domínio**, seguindo os princípios de **Clean Architecture** e **DDD light**, e deve conter:

---

## 1. Visão geral do domínio “XXX”

Explique de forma clara:

- Qual é a responsabilidade do domínio “XXX”
- Quais problemas ele resolve dentro do Gasosa
- Como ele se relaciona com outros domínios do app

Exemplos de domínios:

- Auth
- Vehicle
- Refuel
- User
- Core / Shared

---

## 2. Arquitetura utilizada no domínio

Detalhe:

- Camadas utilizadas (presentation, domain, data)
- Padrões aplicados (Clean Architecture, Command Pattern, offline-first)
- Regras importantes de separação de responsabilidades
- Como ocorre o fluxo: UI → Command/UseCase → Repository → Data Source

Inclua **diagramas textuais simples**, quando fizer sentido.

---

## 3. Estrutura de pastas do domínio

Descreva a estrutura de pastas real do projeto, por exemplo:

```bash
lib/
└─ features/
└─ vehicle/
├─ presentation/
│  └─ cubit/
├─ domain/
│  ├─ entities/
│  ├─ repositories/
│  └─ usecases/
└─ data/
├─ local/
├─ mappers/
└─ repositories/
```

Explique o papel de cada pasta e **boas práticas esperadas** ao adicionar novos arquivos.

---

## 4. Dependências utilizadas no domínio

Liste e explique apenas as dependências relevantes para o domínio, como:

- drift
- firebase_auth
- go_router
- get_it / injectable
- freezed
- bloc / cubit

Explique **por que** cada uma é usada e **quando não usar**.

---

## 5. Módulo “YYYY” dentro do domínio “XXX”

Explique detalhadamente:

- O que o módulo “YYYY” oferece para o restante do domínio
- Quais entidades, use cases ou abstrações ele expõe
- Como outros módulos devem consumi-lo
- Exemplos de uso correto e incorreto

---

## 6. Regras de negócio importantes

Documente regras explícitas do domínio, por exemplo:

- validações
- restrições de fluxo
- decisões arquiteturais já tomadas
- o que **não deve ser feito**, mesmo que tecnicamente possível

---

## 7. Criação de um Agente de IA especializado no domínio “XXX”

Após a documentação, crie um **perfil de agente de IA**, que deve:

- Atuar como um **desenvolvedor mobile Flutter sênior**
- Ser especialista no domínio “XXX” do Gasosa App
- Conhecer profundamente:
  - a arquitetura do projeto
  - regras de negócio
  - padrões adotados
- Desenvolver novas funcionalidades **sem violar a arquitetura existente**
- Priorizar:
  - clareza
  - testabilidade
  - baixo acoplamento
  - consistência com o restante do código

O agente deve:

- Refatorar código quando necessário
- Sugerir testes
- Alertar quando uma decisão quebrar padrões do projeto
- Nunca introduzir overengineering desnecessário

Descreva esse agente como se fosse um **copilot técnico interno do Gasosa App**.

---

## 8. Tom da documentação e do agente

- Técnico, direto e didático
- Focado em longo prazo e manutenibilidade
- Evitar abstrações vagas
- Priorizar exemplos práticos e decisões explícitas
