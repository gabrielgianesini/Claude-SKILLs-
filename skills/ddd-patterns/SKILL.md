---
name: ddd-patterns
description: Tactical and strategic DDD patterns. Activated when working with entities, value objects, aggregates, domain events, repositories, domain services, bounded contexts, or business rule modeling.
metadata:
  version: 2.0.0
  priority: P2
  activation: intent-based
  conflicts: For syntax decisions (operator overloading, functional patterns), readable-code takes precedence.
---

# DDD Patterns — Domain-Driven Design

## Princípio

> O código reflete a linguagem do negócio. Nomes, métodos e estruturas
> devem ser compreensíveis por alguém da área de negócio.

---

## Padrões Táticos (Building Blocks)

### 1. Entity

Objeto com **identidade única** que persiste ao longo do tempo.

```
class CreditProposal:
    id: ProposalId                  // Identidade única tipada
    clientId: ClientId
    amount: Money
    status: ProposalStatus
    createdAt: Timestamp

    function approve() -> CreditProposal:
        require status == PENDING, "Can only approve pending proposals"
        return copy(status = APPROVED)

    function reject(reason: String) -> CreditProposal:
        require status == PENDING, "Can only reject pending proposals"
        return copy(status = REJECTED)
```

**Regras:**
- Identidade única (UUID, ID tipado)
- Igualdade por identidade, não por atributos
- Contém comportamento de negócio (não é "saco de dados")
- Métodos expressam intenção do negócio (`approve()`, não `setStatus()`)

### 2. Value Object

Objeto **imutável** definido por seus atributos. Sem identidade própria.

```
class Money:
    amount: Decimal
    currency: Currency

    constructor(amount, currency):
        require amount >= 0, "Amount cannot be negative"

    // Métodos nomeados — NÃO operator overloading (regra Readable Code)
    function add(other: Money) -> Money:
        require currency == other.currency, "Currency mismatch"
        return new Money(amount + other.amount, currency)

    function subtract(other: Money) -> Money:
        require currency == other.currency, "Currency mismatch"
        return new Money(amount - other.amount, currency)

    function isGreaterThan(other: Money) -> Boolean:
        require currency == other.currency, "Currency mismatch"
        return amount > other.amount

    static ZERO_BRL = new Money(0, Currency.BRL)
```

**Regras:**
- Imutável (operações retornam nova instância)
- Auto-validação no construtor
- Igualdade por atributos
- **Métodos nomeados** em vez de operadores sobrecarregados

### 3. Typed ID

IDs tipados para evitar mistura de identificadores.

```
class ProposalId:
    value: UUID

    static function generate() -> ProposalId:
        return new ProposalId(UUID.random())

    static function from(value: String) -> ProposalId:
        return new ProposalId(UUID.parse(value))
```

**Benefício:** O compilador/type checker impede `findByClientId(proposalId)` — tipos diferentes.

### 4. Aggregate Root

Cluster de entidades tratado como unidade. Único ponto de entrada para modificações.

```
class Order:
    id: OrderId
    customerId: CustomerId
    items: List<OrderItem>         // Entidades internas (privado)
    status: OrderStatus
    events: List<DomainEvent>      // Eventos coletados (privado)

    function addItem(productId, quantity, price) -> OrderItem:
        require status == DRAFT, "Cannot modify confirmed order"
        item = new OrderItem(id: generate(), productId, quantity, unitPrice: price)
        items.add(item)
        return item

    function removeItem(itemId):
        require status == DRAFT, "Cannot modify confirmed order"
        items.remove(where: id == itemId)

    function confirm() -> Order:
        require items.isNotEmpty(), "Cannot confirm empty order"
        status = CONFIRMED
        events.add(new OrderConfirmedEvent(id, customerId, total()))
        return this

    function total() -> Money:
        sum = Money.ZERO_BRL
        for item in items:
            sum = sum.add(item.subtotal())
        return sum

    function domainEvents() -> List<DomainEvent>:
        return copy of events

    function clearEvents():
        events.clear()

    static function create(customerId) -> Order:
        return new Order(
            id: OrderId.generate(),
            customerId: customerId,
            items: empty list,
            status: DRAFT,
            events: empty list
        )
```

**Regras de Aggregate:**
- Entidades internas só acessadas via Root
- Referências externas por ID (não por objeto)
- Uma transação = um Aggregate
- Eventos de domínio coletados internamente, publicados pelo adapter

### 5. Domain Event

Algo que **aconteceu** no domínio. Imutável, no passado.

```
interface DomainEvent:
    occurredAt: Timestamp
    aggregateId: String

class ProposalCreatedEvent implements DomainEvent:
    aggregateId: String
    clientId: String
    amount: Decimal
    currency: String
    occurredAt: Timestamp

class ProposalApprovedEvent implements DomainEvent:
    aggregateId: String
    approvedBy: String
    occurredAt: Timestamp
```

**Regras:**
- Nome no **passado** (Created, Approved, Cancelled)
- Imutável
- Contém dados relevantes do momento (não referências a objetos)
- Timestamp obrigatório
- Sem "now()" como default — injetado explicitamente para testabilidade

#### Publicação de Domain Events

Eventos são **coletados** no aggregate e **publicados** pelo adapter (infraestrutura).

```
1. Aggregate coleta evento  →  order.confirm()  →  events.add(OrderConfirmedEvent)
2. Use Case salva aggregate →  repository.save(order)
3. Adapter publica eventos  →  após save(), publica cada evento
4. Adapter limpa eventos    →  order.clearEvents()
```

**Estratégias de publicação:**

| Estratégia | Quando Usar | Trade-off |
|-----------|-------------|-----------|
| Síncrona (in-process) | Sistemas simples, baixo volume | Simples, mas falha no publish = inconsistência |
| Outbox Pattern | Produção, alta confiabilidade | Consistência garantida, mais complexo |

> **Quem publica:** O Secondary Adapter (repository) após persistir, ou o Use Case após chamar save().
> **Quem loga:** O adapter que publica — ver skill `observability` para padrão de logging de eventos.

### 6. Domain Service

Lógica de negócio que **não pertence** a nenhuma entidade específica.

```
class CreditEligibilityService:
    creditLimitRepository: CreditLimitRepositoryPort

    function checkEligibility(clientId, requestedAmount) -> EligibilityResult:
        limit = creditLimitRepository.findByClientId(clientId)
        if limit is null:
            return EligibilityResult.NotEligible("No credit limit found")

        if requestedAmount.isGreaterThan(limit.availableLimit):
            return EligibilityResult.NotEligible("Insufficient limit")

        return EligibilityResult.Eligible(limit.availableLimit)

// Result type
EligibilityResult:
    Eligible(availableLimit: Money)
    NotEligible(reason: String)
```

**Quando usar:**
- Operação envolve múltiplos agregados
- Lógica não pertence naturalmente a nenhuma entidade
- Precisa de dados de ports secundários

### 7. Repository Port

Interface/contrato no domínio. Implementação na infraestrutura.

```
interface OrderRepositoryPort:
    function save(order: Order)
    function findById(id: OrderId) -> Order or null
    function findByCustomerId(customerId: CustomerId) -> List<Order>
```

**Regras:**
- Interface no DOMÍNIO
- Um repository por Aggregate Root
- Retorna agregados completos
- Sem detalhes de infraestrutura (sem Page, Specification, Query)

### 8. Factory

Criação complexa de agregados isolada em classe dedicada.

**Dois tipos de Factory:**

| Tipo | Localização | Dependências | Quando Usar |
|------|-------------|-------------|-------------|
| Factory Pura | `domain/[context]/model/` ou `factory/` | Nenhuma — só dados primitivos | Criação com validação de invariantes, sem consultas externas |
| Factory Orquestradora | `domain/[context]/usecase/` | Ports, Services | Criação que precisa consultar repositórios ou serviços externos |

> **Regra:** Se a Factory precisa de Ports ou Services, ela é um **Use Case**, não uma Factory de domínio.

#### Factory Pura (Domínio)

```
// domain/[context]/model/OrderFactory ou domain/[context]/factory/OrderFactory

class OrderFactory:

    static function create(customerId: CustomerId, items: List<ItemData>) -> CreateOrderResult:
        if items.isEmpty():
            return CreateOrderResult.EmptyOrder()

        order = new Order(
            id: OrderId.generate(),
            customerId: customerId,
            status: DRAFT,
            items: empty list,
            events: empty list
        )

        for item in items:
            order.addItem(item.productId, item.quantity, item.price)

        return CreateOrderResult.Created(order)

CreateOrderResult:
    Created(order: Order)
    EmptyOrder()
```

**Características:** Sem dependências externas. Só valida invariantes do agregado com dados já disponíveis.

#### Factory Orquestradora (Use Case)

Quando a criação precisa consultar repositórios ou chamar serviços, isso é um Use Case:

```
// domain/[context]/usecase/CreateProposalUseCase

class CreateProposalUseCase implements CreateProposalPort:
    creditLimitRepository: CreditLimitRepositoryPort
    calculator: FinancialCalculator

    function execute(command: CreateProposalCommand) -> CreateProposalResult:
        limit = creditLimitRepository.findByClientId(command.clientId)
        if limit is null:
            return CreateProposalResult.ClientNotFound(command.clientId)

        if not limit.isEligible():
            return CreateProposalResult.NotEligible(command.clientId)

        if command.amount.isGreaterThan(limit.availableLimit):
            return CreateProposalResult.InsufficientLimit(limit.availableLimit)

        calculation = calculator.calculate(command.amount, command.installments, limit.interestRate)

        proposal = new CreditProposal(
            id: ProposalId.generate(),
            clientId: command.clientId,
            amount: command.amount,
            installmentValue: calculation.pmt,
            totalDebt: calculation.totalDebt,
            status: PENDING,
            createdAt: command.timestamp
        )

        return CreateProposalResult.Created(proposal)

CreateProposalResult:
    Created(proposal: CreditProposal)
    ClientNotFound(clientId: ClientId)
    NotEligible(clientId: ClientId)
    InsufficientLimit(available: Money)
```

**Diferença chave:** Depende de `CreditLimitRepositoryPort` → não é Factory pura, é Use Case.

---

## Padrões Estratégicos

### Bounded Context

Limite onde um modelo se aplica. Cada contexto tem seu próprio modelo.

```
┌─────────────────┬─────────────────┬─────────────────────┐
│   Credit        │   Contract      │   Collection        │
│   Context       │   Context       │   Context           │
│                 │                 │                     │
│ - CreditLimit   │ - Contract      │ - Invoice           │
│ - Proposal      │ - CCB           │ - Payment           │
│ - Simulation    │ - Signature     │ - Dunning           │
└─────────────────┴─────────────────┴─────────────────────┘
```

**Regra prática:** Se o mesmo termo tem significados diferentes em áreas distintas do negócio, são contextos diferentes.

### Ubiquitous Language

Vocabulário compartilhado entre dev e negócio. Refletido no código.

```
// ✅ Linguagem do negócio
class CreditProposal:
    function approve()
    function reject(reason)

// ❌ Linguagem técnica
class CreditRequest:
    function setStatusApproved()
    function deny()
```

### Context Mapping

| Padrão | Quando Usar |
|--------|-------------|
| Shared Kernel | Código compartilhado entre contextos (Money, tipos comuns) |
| Customer/Supplier | Um contexto depende de outro e negocia o contrato |
| Anti-Corruption Layer | Traduz modelo externo para modelo interno |
| Published Language | API ou eventos como contrato público |

#### Anti-Corruption Layer (Detalhado)

Quando seu sistema consome uma API externa cujo modelo é diferente do seu domínio, use um ACL para traduzir:

```
// secondary/rest-client/scoring/adapter/ScoringAdapter (ACL)

class ScoringAdapter implements ScoringPort:
    externalClient: ScoringExternalClient
    mapper: ScoringAclMapper

    function evaluate(clientId: ClientId) -> ScoringResult:
        log.info("Calling scoring API clientId={}", clientId)
        externalResponse = externalClient.getScore(clientId.value)
        return mapper.toDomain(externalResponse)
```

```
// secondary/rest-client/scoring/mapper/ScoringAclMapper (traduz modelo externo)

class ScoringAclMapper:

    function toDomain(external: ExternalScoringResponse) -> ScoringResult:
        // API externa usa "rating" (A/B/C), nosso domínio usa score numérico
        score = mapRatingToScore(external.rating)
        return ScoringResult.Evaluated(score)

    private function mapRatingToScore(rating: String) -> Integer:
        RATING_TO_SCORE = { "A": 900, "B": 700, "C": 500, "D": 300 }
        result = RATING_TO_SCORE.get(rating)
        if result is null:
            return ScoringResult.UnknownRating(rating)
        return result
```

**Regras do ACL:**
- O domínio **nunca** conhece o modelo externo
- O mapper traduz tipos, nomes e estrutura do modelo externo para o modelo do domínio
- Localização: `secondary/rest-client/[context]/mapper/` (ver skill `hexagonal-architecture`)

---

## Decisão Rápida: Onde Colocar Lógica?

| Situação | Colocar em |
|----------|------------|
| Validação de estado do próprio objeto | Entity / Value Object (construtor, `require`) |
| Operação que muda estado da entidade | Método na Entity (`approve()`, `cancel()`) |
| Cálculo sem estado, sem dependências | Value Object ou função utilitária |
| Operação entre múltiplos agregados | Domain Service |
| Criação complexa com validações | Factory |
| Orquestração de ports e domain services | Use Case (camada Application) |
| Tradução de request/response | Adapter (camada Infrastructure) |

---

## Checklist

- [ ] Entities têm identidade única tipada
- [ ] Value Objects são imutáveis com auto-validação
- [ ] Value Objects usam métodos nomeados (`.add()`, não `+`)
- [ ] Aggregate Roots controlam consistência do cluster
- [ ] Domain Events nomeados no passado, imutáveis
- [ ] Repository Ports são interfaces/contratos no domínio
- [ ] Código usa linguagem ubíqua do negócio
- [ ] Result types em vez de exceptions para erros esperados