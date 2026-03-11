# CLAUDE.md — Configuracao Global de Desenvolvimento

## Contexto do Projeto

> Preencha com os dados reais do projeto. O Claude usa isto para tomar decisoes.

- **Linguagem:** [ex: Kotlin, Java, TypeScript, C#, Go]
- **Framework:** [ex: Spring Boot, NestJS, ASP.NET, Gin]
- **Arquitetura:** Hexagonal (Ports & Adapters)
- **Paradigma de dominio:** Domain-Driven Design
- **Build:** [ex: Gradle, Maven, npm, dotnet]
- **Testes:** [ex: JUnit 5 + MockK, Jest, xUnit, GoTest]

> **Se os campos acima nao estiverem preenchidos**, Claude deve:
> 1. Perguntar ao usuario qual linguagem e framework do projeto
> 2. Ou inferir dos arquivos do projeto (`package.json`, `build.gradle`, `pom.xml`, `go.mod`, `*.csproj`)
> 3. Adaptar exemplos e implementacoes a linguagem detectada

---

## Regras de Comunicacao

1. **Objetividade:** Respostas curtas e diretas.
2. **Escopo estrito:** Responda/execute apenas o que foi pedido.
3. **Duvida:** Pergunte antes de implementar se houver ambiguidade.
4. **Idioma:** Responda no mesmo idioma do usuario.
5. **Formato de codigo:** Sempre inclua o caminho completo do arquivo como comentario na primeira linha.
6. **Linguagem do projeto:** Use a linguagem definida em "Contexto do Projeto" para todos os exemplos e implementacoes.

---

## Auto-Skills (OBRIGATORIO)

Antes de responder qualquer pedido de codigo, VERIFIQUE se o pedido ativa alguma skill.
Skills estao em `skills/`. O hook `hooks/auto-skill-loader.sh` injeta automaticamente
as skills relevantes. Caso o hook nao tenha injetado, carregue manualmente via Read.

### Skills P0 — Sempre Ativas
Estas regras se aplicam a TODO codigo que voce escrever:

**readable-code**: Codigo explicito, sem magic numbers, sem syntax sugar, sem functional patterns.
Loops imperativos, variaveis intermediarias nomeadas, Result pattern para erros.

**verification-before-completion**: NUNCA diga "pronto", "funciona", "testes passam" sem
ter executado o comando de verificacao E colado o output. Evidencia antes de claims.

**defense-in-depth**: Ao corrigir bugs, valide em TODAS as camadas (entry, business, env, debug).

### Skills P1-P2 — Sob Demanda
Se o hook nao injetou mas o contexto pede, carregue com Read:

| Contexto | Skill |
|----------|-------|
| Implementar/criar | skills/tdd-workflow/SKILL.md |
| Refatorar | skills/safe-refactoring/SKILL.md |
| Decisao arquitetural | skills/adr/SKILL.md |
| Decompor em tarefas | skills/task-generation/SKILL.md |
| Criar PR | skills/pr/SKILL.md |
| Debug/erro/bug | skills/systematic-debugging/SKILL.md |
| Seguranca | skills/security/SKILL.md |
| Estrutura de camadas | skills/hexagonal-architecture/SKILL.md |
| Modelagem dominio | skills/ddd-patterns/SKILL.md |
| Logging/metricas | skills/observability/SKILL.md |
| Receber code review | skills/receiving-code-review/SKILL.md |
| Brainstorm/design | skills/brainstorming/SKILL.md |
| Anti-patterns de teste | skills/testing-anti-patterns/SKILL.md |
| Agentes paralelos | skills/dispatching-parallel-agents/SKILL.md |
| Finalizar branch | skills/finishing-a-development-branch/SKILL.md |

---

## Skills e Ativacao — Tabela Completa

| Skill | Arquivo | Prioridade |
|-------|---------|------------|
| ADR | `skills/adr/SKILL.md` | P0 — Antes de qualquer codigo |
| Task Generation | `skills/task-generation/SKILL.md` | P0 — Apos ADR aprovada |
| Readable Code | `skills/readable-code/SKILL.md` | P0 — Sempre ativa no codigo |
| Verification | `skills/verification-before-completion/SKILL.md` | P0 — Antes de claims |
| Defense-in-Depth | `skills/defense-in-depth/SKILL.md` | P0 — Correcao de bugs |
| Root Cause Tracing | `skills/root-cause-tracing/SKILL.md` | P0 — Sub-skill de debugging |
| TDD Workflow | `skills/tdd-workflow/SKILL.md` | P1 — Features e bugs |
| Safe Refactoring | `skills/safe-refactoring/SKILL.md` | P1 — Refatoracoes |
| PR | `skills/pr/SKILL.md` | P1 — Criacao de branches e PRs |
| Security | `skills/security/SKILL.md` | P1 — Input, auth, dados sensiveis |
| Systematic Debugging | `skills/systematic-debugging/SKILL.md` | P1 — Investigacao de bugs |
| Receiving Code Review | `skills/receiving-code-review/SKILL.md` | P1 — Receber feedback |
| DDD Patterns | `skills/ddd-patterns/SKILL.md` | P2 — Modelagem |
| Hexagonal Arch | `skills/hexagonal-architecture/SKILL.md` | P2 — Estrutura |
| Observability | `skills/observability/SKILL.md` | P2 — Logs e metricas |
| Brainstorming | `skills/brainstorming/SKILL.md` | P2 — Design de ideias |
| Testing Anti-Patterns | `skills/testing-anti-patterns/SKILL.md` | P2 — Qualidade de testes |
| Dispatching Agents | `skills/dispatching-parallel-agents/SKILL.md` | P2 — Paralelismo |
| Finishing Branch | `skills/finishing-a-development-branch/SKILL.md` | P2 — Finalizar trabalho |

### Regras de Ativacao

Ative skills com base na **intencao**, nao em palavras isoladas:

| Intencao do Usuario | Skills Ativadas (em ordem) |
|---------------------|---------------------------|
| Criar/implementar feature nova | ADR → Task Generation → (por tarefa: Readable Code + TDD + DDD + Hexagonal) |
| Corrigir bug | Systematic Debugging → ADR (simplificada) → TDD bug fix |
| Refatorar codigo existente | ADR (refactoring) → Task Generation → Safe Refactoring |
| Modelar dominio/entidades | ADR → DDD + Readable Code |
| Decidir onde colocar codigo | Hexagonal |
| Adicionar logs/monitoramento | Observability + Hexagonal |
| Lidar com input externo, auth, dados sensiveis | Security + Hexagonal |
| Criar PR / abrir pull request | PR |
| Receber feedback de code review | Receiving Code Review |
| Explorar ideias / design | Brainstorming |
| Finalizar branch | Verification → Finishing Branch |

### Resolucao de Conflitos

Se duas skills dao instrucoes opostas:
1. **ADR vence** em questoes de escopo e decisao ("o que" e "por que").
2. **Readable Code vence** em questoes de sintaxe e legibilidade.
3. **DDD vence** em questoes de modelagem e nomenclatura.
4. **Hexagonal vence** em questoes de localizacao de codigo.
5. **Na duvida**, pergunte ao usuario.

---

## Fluxo de Trabalho Obrigatorio

### Pipeline Completo (Features, Bugs, Refatoracoes)

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────────────┐
│  1. ADR      │ ──→ │  2. Tarefas       │ ──→ │  3. Execucao por tarefa │
│  (aprovacao) │     │  (aprovacao)      │     │  (TDD ou Safe Refactor) │
└─────────────┘     └──────────────────┘     └─────────────────────────┘
```

**Cada transicao exige aprovacao explicita do usuario.**

### Detalhamento

```
1. PLANEJAR
   a. Criar ADR (template: feature, bug ou refactoring)
   b. Esperar aprovacao do usuario

2. DECOMPOR
   a. Gerar tarefas a partir da ADR aprovada
   b. Ordem inside-out (dominio → aplicacao → infraestrutura)
   c. Esperar aprovacao do usuario

3. EXECUTAR (por tarefa, uma de cada vez)
   a. Anunciar: "Iniciando Tarefa [N]/[Total]"
   b. Ativar skill correta (TDD ou Safe Refactoring)
   c. Aplicar Readable Code + DDD + Hexagonal + Observability
   d. Concluir: "Tarefa [N] concluida. Iniciar proxima?"
   e. Esperar confirmacao
```

### Escape Hatch — Pipeline Simplificado

Se o usuario indicar urgencia ou pedir execucao direta ("so faz", "direto", "sem cerimonia", "rapido"):

```
Pipeline simplificado:
1. Claude cria ADR minima INLINE (contexto + decisao + regras em ≤ 10 linhas)
2. Claude lista tarefas INLINE (sem template completo, so titulo + testes esperados)
3. Pede confirmacao UMA VEZ para tudo
4. Executa com TDD normalmente
```

**O que NAO pode ser pulado mesmo no escape hatch:**
- Readable Code (sempre ativo)
- Testes antes do codigo (TDD)
- Result Pattern para erros

### Excecoes (sem ADR, sem tarefas)

| Situacao | O que fazer |
|----------|-------------|
| Renomear variavel / fix de typo | Executar direto |
| Pergunta sobre arquitetura | Responder direto |
| Atualizar dependencia sem breaking change | Executar direto |
| Explicar conceito / entender codigo | Responder direto |

---

## Code Review

Quando o usuario pede para revisar codigo ("revisa", "review", "olha esse codigo", "o que acha"):

**Claude analisa na seguinte ordem e reporta apenas violacoes encontradas:**

| # | Verificacao | Skill Referencia |
|---|-------------|-----------------|
| 1 | Readable Code: numeros magicos, operator overloading, syntax sugar, nomes | readable-code |
| 2 | DDD: entidade sem comportamento, VO mutavel, logica fora do dominio | ddd-patterns |
| 3 | Hexagonal: dominio importando framework, regra no controller, ORM no dominio | hexagonal-architecture |
| 4 | Erros: exception para fluxo em vez de Result, erros engolidos | readable-code + hexagonal |
| 5 | Observability: log no dominio, dados sensiveis logados, falta correlation ID | observability |
| 6 | Testes: logica no teste, multiplos conceitos, falta de cenarios de borda | tdd-workflow |
| 7 | Security: input nao validado, secrets hardcoded, SQL concatenado, mass assignment | security |

**Formato de resposta:**

```
### Code Review

**Arquivo:** [caminho]

#### Violacoes
1. [Regra violada] — [linha ou trecho] — [como corrigir]
2. ...

#### Pontos positivos
- [o que esta bom]

#### Sugestao
[acao recomendada: corrigir direto, criar ADR para refatorar, ou aceitar como esta]
```

---

## Analise de Codigo Existente

Quando o usuario cola codigo e pede para entender ("explica", "o que faz", "como funciona"):

**Claude deve:**
1. Explicar o que o codigo faz em linguagem simples (1-3 paragrafos)
2. Identificar em qual camada da arquitetura ele se encaixa
3. Apontar padroes DDD presentes (entity, VO, service, etc.)
4. **NAO sugerir melhorias a menos que o usuario peca** — o objetivo e entender, nao modificar

---

## Convencoes de Projeto

### Nomes de Arquivo

| Tipo | Convencao | Exemplo |
|------|-----------|---------|
| Classes / Tipos | PascalCase | `CreditProposal`, `MoneyTest` |
| Arquivos de codigo | Seguir padrao da linguagem | Kotlin/Java: `CreditProposal.kt` — TS: `credit-proposal.ts` — Go: `credit_proposal.go` |
| Diretorios | kebab-case ou lowercase | `credit/model/`, `rest-server/` |
| Arquivos de config | kebab-case | `app-config.yml`, `feature-toggles.json` |
| ADRs | `ADR-NNN-titulo-descritivo.md` | `ADR-001-criar-simulacao-credito.md` |
| Testes | Mesmo nome + sufixo Test | `CreditProposalTest`, `MoneyTest` |

**Regra:** Seguir a convencao dominante da linguagem do projeto. Se o projeto ja tem padrao estabelecido, manter consistencia com o existente.

### Commits

Cada tarefa concluida = um commit. Formato:

```
[tipo]: [descricao curta]

Refs: ADR-NNN, Tarefa N/Total

tipo:
  feat     → feature nova
  fix      → bug fix
  refactor → refatoracao
  test     → apenas testes
  docs     → documentacao
  chore    → config, build, dependencias
```

**Regras:**
- Primeira linha ≤ 72 caracteres
- Referencia a ADR e tarefa no corpo
- Um commit por tarefa (atomico e revertivel)

### Branches

#### Branches de trabalho (durante desenvolvimento)
```
[tipo]/ADR-NNN-descricao-curta

Exemplos:
  feat/ADR-001-simulacao-credito
  fix/ADR-003-iof-calculation
  refactor/ADR-005-new-financial-calculator
```

---

## Readable Code (Sempre Ativo — Resumo)

Regras completas em `skills/readable-code/SKILL.md`. Resumo para referencia rapida:

- Zero numeros magicos → constantes nomeadas.
- Sem operator overloading → metodos explicitos (`.add()`, `.multiply()`).
- Sem funcoes funcionais → `for` loops em vez de `map`, `filter`, `fold`.
- Sem syntax sugar → formas explicitas da linguagem.
- Pattern matching (`when`, `match`, `switch`) → permitido para Result types e enums.
- Variaveis intermediarias → decompor expressoes complexas.
- Result Pattern → tipos explicitos para erros esperados, sem exceptions para fluxo.
