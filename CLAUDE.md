# CLAUDE.md — Configuração Global de Desenvolvimento

## Contexto do Projeto

> Preencha com os dados reais do projeto. O Claude usa isto para tomar decisões.

- **Linguagem:** [ex: Kotlin, Java, TypeScript, C#, Go]
- **Framework:** [ex: Spring Boot, NestJS, ASP.NET, Gin]
- **Arquitetura:** Hexagonal (Ports & Adapters)
- **Paradigma de domínio:** Domain-Driven Design
- **Build:** [ex: Gradle, Maven, npm, dotnet]
- **Testes:** [ex: JUnit 5 + MockK, Jest, xUnit, GoTest]

> **Se os campos acima não estiverem preenchidos**, Claude deve:
> 1. Perguntar ao usuário qual linguagem e framework do projeto
> 2. Ou inferir dos arquivos do projeto (`package.json`, `build.gradle`, `pom.xml`, `go.mod`, `*.csproj`)
> 3. Adaptar exemplos e implementações à linguagem detectada

---

## Regras de Comunicação

1. **Objetividade:** Respostas curtas e diretas.
2. **Escopo estrito:** Responda/execute apenas o que foi pedido.
3. **Dúvida:** Pergunte antes de implementar se houver ambiguidade.
4. **Idioma:** Responda no mesmo idioma do usuário.
5. **Formato de código:** Sempre inclua o caminho completo do arquivo como comentário na primeira linha.
6. **Linguagem do projeto:** Use a linguagem definida em "Contexto do Projeto" para todos os exemplos e implementações.

---

## Skills e Ativação

| Skill | Arquivo | Prioridade |
|-------|---------|------------|
| ADR | `skills/adr/SKILL.md` | P0 — Antes de qualquer código |
| Task Generation | `skills/task-generation/SKILL.md` | P0 — Após ADR aprovada |
| Readable Code | `skills/readable-code/SKILL.md` | P0 — Sempre ativa no código |
| TDD Workflow | `skills/tdd-workflow/SKILL.md` | P1 — Features e bugs |
| Safe Refactoring | `skills/safe-refactoring/SKILL.md` | P1 — Refatorações |
| PR | `skills/pr/SKILL.md` | P1 — Criação de branches e PRs |
| DDD Patterns | `skills/ddd-patterns/SKILL.md` | P2 — Modelagem |
| Hexagonal Arch | `skills/hexagonal-architecture/SKILL.md` | P2 — Estrutura |
| Observability | `skills/observability/SKILL.md` | P2 — Logs e métricas |
| Security | `skills/security/SKILL.md` | P1 — Input, auth, dados sensíveis |

### Regras de Ativação

Ative skills com base na **intenção**, não em palavras isoladas:

| Intenção do Usuário | Skills Ativadas (em ordem) |
|----------------------|---------------------------|
| Criar/implementar feature nova | ADR → Task Generation → (por tarefa: Readable Code + TDD + DDD + Hexagonal) |
| Corrigir bug | ADR (simplificada) → Task Generation → (por tarefa: Readable Code + TDD bug fix) |
| Refatorar código existente | ADR (refactoring) → Task Generation → (por tarefa: Readable Code + Safe Refactoring) |
| Modelar domínio/entidades | ADR → DDD + Readable Code |
| Decidir onde colocar código | Hexagonal |
| Adicionar logs/monitoramento | Observability + Hexagonal |
| Lidar com input externo, auth, dados sensíveis | Security + Hexagonal |
| Criar PR / abrir pull request | PR |
| Revisar código existente | Code Review (ver seção abaixo) |
| Entender código existente | Análise (ver seção abaixo) |

### Resolução de Conflitos

Se duas skills dão instruções opostas:
1. **ADR vence** em questões de escopo e decisão ("o quê" e "por quê").
2. **Readable Code vence** em questões de sintaxe e legibilidade.
3. **DDD vence** em questões de modelagem e nomenclatura.
4. **Hexagonal vence** em questões de localização de código.
5. **Na dúvida**, pergunte ao usuário.

---

## Fluxo de Trabalho Obrigatório

### Pipeline Completo (Features, Bugs, Refatorações)

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────────────┐
│  1. ADR      │ ──→ │  2. Tarefas       │ ──→ │  3. Execução por tarefa │
│  (aprovação) │     │  (aprovação)      │     │  (TDD ou Safe Refactor) │
└─────────────┘     └──────────────────┘     └─────────────────────────┘
```

**Cada transição exige aprovação explícita do usuário.**

### Detalhamento

```
1. PLANEJAR
   a. Criar ADR (template: feature, bug ou refactoring)
   b. Esperar aprovação do usuário

2. DECOMPOR
   a. Gerar tarefas a partir da ADR aprovada
   b. Ordem inside-out (domínio → aplicação → infraestrutura)
   c. Esperar aprovação do usuário

3. EXECUTAR (por tarefa, uma de cada vez)
   a. Anunciar: "Iniciando Tarefa [N]/[Total]"
   b. Ativar skill correta (TDD ou Safe Refactoring)
   c. Aplicar Readable Code + DDD + Hexagonal + Observability
   d. Concluir: "Tarefa [N] concluída. Iniciar próxima?"
   e. Esperar confirmação
```

### Escape Hatch — Pipeline Simplificado

Se o usuário indicar urgência ou pedir execução direta ("só faz", "direto", "sem cerimônia", "rápido"):

```
Pipeline simplificado:
1. Claude cria ADR mínima INLINE (contexto + decisão + regras em ≤ 10 linhas)
2. Claude lista tarefas INLINE (sem template completo, só título + testes esperados)
3. Pede confirmação UMA VEZ para tudo
4. Executa com TDD normalmente
```

**O que NÃO pode ser pulado mesmo no escape hatch:**
- Readable Code (sempre ativo)
- Testes antes do código (TDD)
- Result Pattern para erros

### Exceções (sem ADR, sem tarefas)

| Situação | O que fazer |
|----------|-------------|
| Renomear variável / fix de typo | Executar direto |
| Pergunta sobre arquitetura | Responder direto |
| Atualizar dependência sem breaking change | Executar direto |
| Explicar conceito / entender código | Responder direto |

---

## Code Review

Quando o usuário pede para revisar código ("revisa", "review", "olha esse código", "o que acha"):

**Claude analisa na seguinte ordem e reporta apenas violações encontradas:**

| # | Verificação | Skill Referência |
|---|-------------|-----------------|
| 1 | Readable Code: números mágicos, operator overloading, syntax sugar, nomes | readable-code |
| 2 | DDD: entidade sem comportamento, VO mutável, lógica fora do domínio | ddd-patterns |
| 3 | Hexagonal: domínio importando framework, regra no controller, ORM no domínio | hexagonal-architecture |
| 4 | Erros: exception para fluxo em vez de Result, erros engolidos | readable-code + hexagonal |
| 5 | Observability: log no domínio, dados sensíveis logados, falta correlation ID | observability |
| 6 | Testes: lógica no teste, múltiplos conceitos, falta de cenários de borda | tdd-workflow |
| 7 | Security: input não validado, secrets hardcoded, SQL concatenado, mass assignment | security |

**Formato de resposta:**

```
### 🔍 Code Review

**Arquivo:** [caminho]

#### Violações
1. [Regra violada] — [linha ou trecho] — [como corrigir]
2. ...

#### Pontos positivos
- [o que está bom]

#### Sugestão
[ação recomendada: corrigir direto, criar ADR para refatorar, ou aceitar como está]
```

---

## Análise de Código Existente

Quando o usuário cola código e pede para entender ("explica", "o que faz", "como funciona"):

**Claude deve:**
1. Explicar o que o código faz em linguagem simples (1-3 parágrafos)
2. Identificar em qual camada da arquitetura ele se encaixa
3. Apontar padrões DDD presentes (entity, VO, service, etc.)
4. **NÃO sugerir melhorias a menos que o usuário peça** — o objetivo é entender, não modificar

---

## Convenções de Projeto

### Nomes de Arquivo

| Tipo | Convenção | Exemplo |
|------|-----------|---------|
| Classes / Tipos | PascalCase | `CreditProposal`, `MoneyTest` |
| Arquivos de código | Seguir padrão da linguagem | Kotlin/Java: `CreditProposal.kt` — TS: `credit-proposal.ts` — Go: `credit_proposal.go` |
| Diretórios | kebab-case ou lowercase | `credit/model/`, `rest-server/` |
| Arquivos de config | kebab-case | `app-config.yml`, `feature-toggles.json` |
| ADRs | `ADR-NNN-titulo-descritivo.md` | `ADR-001-criar-simulacao-credito.md` |
| Testes | Mesmo nome + sufixo Test | `CreditProposalTest`, `MoneyTest` |

**Regra:** Seguir a convenção dominante da linguagem do projeto. Se o projeto já tem padrão estabelecido, manter consistência com o existente.

### Commits

Cada tarefa concluída = um commit. Formato:

```
[tipo]: [descrição curta]

Refs: ADR-NNN, Tarefa N/Total

tipo:
  feat     → feature nova
  fix      → bug fix
  refactor → refatoração
  test     → apenas testes
  docs     → documentação
  chore    → config, build, dependências
```

**Exemplos:**
```
feat: create Money value object with add and subtract

Refs: ADR-001, Tarefa 1/7
```

```
fix: correct IOF calculation for 30-day period

Refs: ADR-003, Tarefa 2/2
```

**Regras:**
- Mensagem em inglês (convenção de mercado) ou seguir padrão existente do projeto
- Primeira linha ≤ 72 caracteres
- Referência à ADR e tarefa no corpo
- Um commit por tarefa (atômico e revertível)

### Branches

#### Branches de trabalho (durante desenvolvimento)
```
[tipo]/ADR-NNN-descricao-curta

Exemplos:
  feat/ADR-001-simulacao-credito
  fix/ADR-003-iof-calculation
  refactor/ADR-005-new-financial-calculator
```

#### Branches para PR → master
Seguir regras da skill `skills/pr/SKILL.md` (padrão `RELEASE/CARD-JIRA` ou `HOTFIX/CARD-JIRA`).

#### Ciclo de Vida da Branch
1. Criar branch de trabalho: `feat/ADR-001-simulacao-credito`
2. Desenvolver com commits atômicos (1 por tarefa)
3. Quando pronto para PR, renomear para padrão PR: `RELEASE/CARD-JIRA` ou `HOTFIX/CARD-JIRA`
4. Criar PR via skill PR

Ou, se o card Jira já é conhecido desde o início:
1. Criar branch direto no padrão PR: `RELEASE/CARD-JIRA`
2. Desenvolver normalmente com commits atômicos

---

## Readable Code (Sempre Ativo — Resumo)

Regras completas em `skills/readable-code/SKILL.md`. Resumo para referência rápida:

- Zero números mágicos → constantes nomeadas.
- Sem operator overloading → métodos explícitos (`.add()`, `.multiply()`).
- Sem funções funcionais → `for` loops em vez de `map`, `filter`, `fold`.
- Sem syntax sugar → formas explícitas da linguagem.
- Pattern matching (`when`, `match`, `switch`) → permitido para Result types e enums.
- Variáveis intermediárias → decompor expressões complexas.
- Result Pattern → tipos explícitos para erros esperados, sem exceptions para fluxo.