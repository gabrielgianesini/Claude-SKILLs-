---
name: task-generation
description: Decompõe uma ADR aprovada em tarefas ordenadas e atômicas. Cada tarefa mapeia para um ciclo TDD e um commit. Ativada após aprovação da ADR, antes de qualquer implementação.
metadata:
  version: 1.0.0
  priority: P0
  activation: Após aprovação da ADR, antes da implementação
  conflicts: Nenhum. Alimenta TDD Workflow ou Safe Refactoring.
---

## Princípio

> Nenhuma implementação começa sem uma lista de tarefas aprovada.
> Tarefas são atômicas, ordenadas e testáveis.

---

## Quando Ativar

- **Sempre** após aprovação de uma ADR (feature, bug fix ou refactoring)
- **Nunca** pular esta etapa — sem tarefas, não há execução

---

## Estratégia de Decomposição: Inside-Out

Tarefas são ordenadas do núcleo do domínio para as bordas da aplicação:

```
1. Value Objects        (domínio — sem dependências)
2. Entities             (domínio — usam VOs)
3. Domain Events        (domínio — emitidos por entidades/aggregates)
4. Domain Services      (domínio — lógica que não pertence a uma entidade)
5. Repository Ports     (domínio — interfaces)
6. Use Cases            (aplicação — orquestram domínio)
7. Primary Adapters     (infra — controllers, consumers)
8. Secondary Adapters   (infra — repositories impl, clients)
9. Wiring / Config      (infra — injeção de dependência, feature toggles)
```

### Por que Inside-Out?

- Cada tarefa depende apenas de tarefas anteriores (já concluídas)
- Testes de domínio são puros (sem mocks de infra)
- Feedback rápido — problemas no modelo aparecem cedo

---

## Template de Tarefa

```markdown
### Tarefa N/Total: [Título descritivo]

**Camada:** [Domain | Application | Infrastructure]
**Skill:** [TDD Workflow | Safe Refactoring]
**Depende de:** [Tarefa X, Y ou "nenhuma"]

**O que criar/modificar:**
- [arquivo ou classe 1]
- [arquivo ou classe 2]

**Testes esperados:**
- [ ] [should X when Y]
- [ ] [should Z when W]

**Critério de conclusão:**
Todos os testes passam. Commit: `[tipo]: [descrição curta]`
```

---

## Regras de Granularidade

| Regra | Descrição |
|-------|-----------|
| 1 tarefa = 1 conceito | Ex: um Value Object, um Use Case, um adapter |
| 1 tarefa = 1 commit | Atômico e revertível |
| 1-3 ciclos TDD por tarefa | Se precisar de mais, a tarefa é grande demais — dividir |
| Testável isoladamente | Cada tarefa tem seus próprios testes |
| Independência máxima | Minimizar dependências entre tarefas |

### Sinais de Tarefa Grande Demais

- Mais de 3 testes esperados com conceitos diferentes
- Precisa modificar mais de 3 arquivos em camadas diferentes
- Não cabe em uma frase: "Criar [X] que faz [Y]"

**Ação:** Dividir em sub-tarefas seguindo a ordem inside-out.

---

## Fonte das Tarefas

As tarefas vêm diretamente da ADR aprovada:

| Seção da ADR | Gera |
|--------------|------|
| Design Técnico (entidades, VOs, services) | Tarefas de domínio (camadas 1-5) |
| Regras de Negócio | Testes dentro das tarefas de domínio |
| Use Cases / Fluxos | Tarefas de aplicação (camada 6) |
| Endpoints / Consumers | Tarefas de primary adapter (camada 7) |
| Integrações externas | Tarefas de secondary adapter (camada 8) |
| Casos de Teste Esperados | Distribuídos entre as tarefas correspondentes |

**Regra:** Toda seção da ADR deve estar coberta por pelo menos uma tarefa. Se sobrar seções sem tarefa, há gap no plano.

---

## Fluxo de Trabalho

```
1. Receber ADR aprovada
2. Identificar todos os artefatos (VOs, Entities, Services, Ports, Use Cases, Adapters)
3. Ordenar inside-out
4. Para cada artefato:
   a. Definir testes esperados (extrair das Regras de Negócio e Casos de Teste)
   b. Identificar dependências (quais tarefas anteriores são pré-requisito)
   c. Definir critério de conclusão (commit message)
5. Apresentar lista ao usuário
6. Esperar aprovação antes de iniciar execução
```

---

## Modo Simplificado (Escape Hatch)

Quando o CLAUDE.md ativa o pipeline simplificado (usuário pede urgência), a geração de tarefas é reduzida a uma lista inline:

```markdown
### Tarefas (simplificado)

1. [Título] — Testes: [lista curta dos testes]
2. [Título] — Testes: [lista curta dos testes]
3. [Título] — Testes: [lista curta dos testes]

> Aprovar para iniciar execução?
```

**O que muda no simplificado:**
- Sem template completo (só título + testes esperados)
- Sem campo de dependências explícitas (ordem implícita da lista)
- Sem campo de camada (implícito pelo nome)
- Aprovação única para tudo

**O que NÃO muda:**
- Ordem inside-out mantida
- Cada tarefa ainda é 1 conceito = 1 commit
- Testes esperados obrigatórios

---

## Formato de Resposta

```markdown
### Tarefas para ADR-NNN: [Título da ADR]

---

### Tarefa 1/N: [Título]

**Camada:** Domain
**Skill:** TDD Workflow
**Depende de:** nenhuma

**O que criar:**
- [arquivo 1]

**Testes esperados:**
- [ ] [teste 1]
- [ ] [teste 2]

**Commit:** `feat: [descrição]`

---

### Tarefa 2/N: [Título]

**Camada:** Domain
**Skill:** TDD Workflow
**Depende de:** Tarefa 1

**O que criar:**
- [arquivo 1]

**Testes esperados:**
- [ ] [teste 1]

**Commit:** `feat: [descrição]`

---

[... demais tarefas ...]

---

> **Total:** N tarefas | **Ordem:** inside-out (domínio → aplicação → infra)
> Aprovar para iniciar execução? Quer ajustar escopo, ordem ou granularidade?
```

---

## Checklist de Validação

Antes de apresentar as tarefas ao usuário, verificar:

- [ ] Todas as seções da ADR estão cobertas por pelo menos uma tarefa
- [ ] Ordem inside-out respeitada (domínio primeiro, infra por último)
- [ ] Cada tarefa tem testes esperados definidos
- [ ] Cada tarefa mapeia para exatamente um commit
- [ ] Dependências entre tarefas são explícitas e acíclicas
- [ ] Nenhuma tarefa modifica mais de uma camada (domain, application, infrastructure)
- [ ] Granularidade adequada (1-3 ciclos TDD por tarefa)
- [ ] Modo simplificado disponível se o pipeline simplificado foi ativado
- [ ] Regras de negócio da ADR estão refletidas nos testes esperados
- [ ] Formato de commit segue padrão do CLAUDE.md: `[tipo]: [descrição]`

---

## Exemplo Completo

Para uma ADR de "Criar simulação de crédito":

```markdown
### Tarefas para ADR-001: Criar Simulação de Crédito

### Tarefa 1/6: Criar Value Object Money

**Camada:** Domain
**Skill:** TDD Workflow
**Depende de:** nenhuma

**O que criar:**
- Money (amount, currency)

**Testes esperados:**
- [ ] should create Money with valid amount and currency
- [ ] should reject negative amount
- [ ] should add two Money of same currency
- [ ] should reject add of different currencies

**Commit:** `feat: create Money value object with add and subtract`

---

### Tarefa 2/6: Criar Entity CreditSimulation

**Camada:** Domain
**Skill:** TDD Workflow
**Depende de:** Tarefa 1

**O que criar:**
- CreditSimulation (id, requestedAmount: Money, term, rate, result)

**Testes esperados:**
- [ ] should create simulation with valid parameters
- [ ] should calculate monthly installment
- [ ] should calculate total cost

**Commit:** `feat: create CreditSimulation entity with calculation`

---

### Tarefa 3/6: Criar Port SimulationRepositoryPort

**Camada:** Domain
**Skill:** TDD Workflow
**Depende de:** Tarefa 2

**O que criar:**
- SimulationRepositoryPort (interface)

**Testes esperados:**
- [ ] (sem testes — é apenas uma interface)

**Commit:** `feat: create SimulationRepositoryPort interface`

---

### Tarefa 4/6: Criar Use Case CreateSimulation

**Camada:** Application
**Skill:** TDD Workflow
**Depende de:** Tarefa 2, Tarefa 3

**O que criar:**
- CreateSimulationUseCase
- CreateSimulationCommand
- CreateSimulationResult

**Testes esperados:**
- [ ] should create and persist simulation with valid command
- [ ] should return error when amount exceeds limit
- [ ] should return error when term is invalid

**Commit:** `feat: create CreateSimulation use case`

---

### Tarefa 5/6: Criar Controller SimulationController

**Camada:** Infrastructure (Primary Adapter)
**Skill:** TDD Workflow
**Depende de:** Tarefa 4

**O que criar:**
- SimulationController (POST /simulations)
- CreateSimulationRequest (DTO)
- SimulationResponse (DTO)
- SimulationMapper

**Testes esperados:**
- [ ] should return 201 with simulation result
- [ ] should return 400 when request is invalid
- [ ] should return 422 when business rule fails

**Commit:** `feat: create SimulationController with POST endpoint`

---

### Tarefa 6/6: Criar Adapter SimulationRepositoryAdapter

**Camada:** Infrastructure (Secondary Adapter)
**Skill:** TDD Workflow
**Depende de:** Tarefa 3

**O que criar:**
- SimulationRepositoryAdapter (implementa SimulationRepositoryPort)
- SimulationEntity (ORM)
- SimulationPersistenceMapper

**Testes esperados:**
- [ ] should save and retrieve simulation
- [ ] should map between domain and ORM entity correctly

**Commit:** `feat: create SimulationRepositoryAdapter with JPA`

---

> **Total:** 6 tarefas | **Ordem:** inside-out (domínio → aplicação → infra)
> Aprovar para iniciar execução? Quer ajustar escopo, ordem ou granularidade?
```
