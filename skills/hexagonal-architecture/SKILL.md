---
name: hexagonal-architecture
description: Ports & Adapters architecture. Activated when user asks where to put code, which layer, folder structure, or discusses separation between domain, application, and infrastructure.
metadata:
  version: 2.0.0
  priority: P2
  activation: intent-based
  conflicts: For domain modeling decisions, defer to ddd-patterns. For syntax, defer to readable-code.
---

# Hexagonal Architecture — Ports & Adapters

## Princípio

> Dependências apontam para DENTRO (domínio). O domínio não conhece nada externo.

```
┌─────────────────────────────────────────────────────────────┐
│                     INFRASTRUCTURE                          │
│  (Controllers, Repositories Impl, External API Clients)     │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                   APPLICATION                       │   │
│   │  (Use Cases, Application Services)                  │   │
│   │                                                     │   │
│   │   ┌─────────────────────────────────────────────┐   │   │
│   │   │                 DOMAIN                      │   │   │
│   │   │  (Entities, VOs, Events, Services, Ports)   │   │   │
│   │   └─────────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Camadas e Regras

### 1. DOMAIN (Núcleo)

**Localização:** `domain/[context]/`

**Contém:**
- Entities e Aggregate Roots
- Value Objects
- Domain Events
- Domain Services
- Repository Ports (interfaces/contratos)
- Domain Exceptions
- Regras de negócio

**NÃO contém:**
- Frameworks (ORM, DI, HTTP)
- Anotações/decorators de infraestrutura
- DTOs de API
- Logs (domínio é silencioso — ver skill observability)

```
// domain/[context]/model/CreditLimit

class CreditLimit:
    id: CreditLimitId
    clientId: ClientId
    totalLimit: Money
    usedLimit: Money

    // Sem imports de frameworks!

    function availableLimit() -> Money:
        return totalLimit.subtract(usedLimit)

    function isEligible() -> Boolean:
        return availableLimit().isGreaterThan(Money.ZERO_BRL)
```

```
// domain/[context]/ports/secondary/CreditLimitRepositoryPort

interface CreditLimitRepositoryPort:
    function findByClientId(clientId: ClientId) -> CreditLimit or null
    function save(creditLimit: CreditLimit)
```

### 2. APPLICATION (Use Cases)

**Localização:** `domain/[context]/usecase/` e `domain/[context]/ports/primary/`

**Contém:**
- Use Cases (orquestração)
- Commands e Queries (DTOs de entrada)
- Result types (DTOs de saída)
- Ports primários (interfaces de entrada)

**NÃO contém:**
- Regras de negócio (pertencem ao domínio)
- Detalhes de infraestrutura
- Anotações de framework

```
// domain/[context]/ports/primary/SimulateCreditPort

interface SimulateCreditPort:
    function simulate(command: SimulateCreditCommand) -> SimulateCreditResult

class SimulateCreditCommand:
    clientId: String
    amount: Decimal
    installments: Integer

SimulateCreditResult:
    Success(simulation: SimulationData)
    ClientNotFound(clientId: String)
    NotEligible(reason: String)
```

```
// domain/[context]/usecase/SimulateCreditUseCase

class SimulateCreditUseCase implements SimulateCreditPort:
    creditLimitRepository: CreditLimitRepositoryPort
    calculator: FinancialCalculator

    function simulate(command) -> SimulateCreditResult:
        clientId = ClientId.from(command.clientId)
        amount = new Money(command.amount, Currency.BRL)

        limit = creditLimitRepository.findByClientId(clientId)
        if limit is null:
            return SimulateCreditResult.ClientNotFound(command.clientId)

        if not limit.isEligible():
            return SimulateCreditResult.NotEligible("Client not eligible")

        simulation = calculator.simulate(
            availableLimit: limit.availableLimit,
            requestedAmount: amount,
            installments: command.installments,
            rate: limit.interestRate
        )

        return SimulateCreditResult.Success(simulation)
```

### 3. PRIMARY ADAPTERS (Entrada)

**Localização:** `primary/[tipo]/[context]/`

**Contém:**
- REST/HTTP Controllers
- GraphQL Resolvers
- CLI Commands
- Message Consumers (Kafka, SQS, RabbitMQ)
- Request/Response DTOs
- Mappers (Request → Command, Result → Response)
- Logs de entrada/saída

```
// primary/rest-server/[context]/controller/CreditController

// Anotações/decorators do framework aqui — NÃO no domínio
@RestController("/api/v1/credit")
class CreditController:
    simulateCreditPort: SimulateCreditPort    // Depende do Port, não do UseCase

    @POST("/simulate")
    function simulate(request: SimulateRequest) -> HttpResponse:
        log.info("Received simulation request clientId={}", request.clientId)

        command = new SimulateCreditCommand(
            clientId: request.clientId,
            amount: request.amount,
            installments: request.installments
        )

        result = simulateCreditPort.simulate(command)

        match result:
            Success -> return HTTP 200, result.simulation.toResponse()
            ClientNotFound -> return HTTP 404, error("Client not found")
            NotEligible -> return HTTP 422, error(result.reason)
```

### Message Consumers (Primary Adapter)

Consumers de mensagens (Kafka, SQS, RabbitMQ) são **Primary Adapters** — recebem input externo.

```
// primary/message-consumer/[context]/consumer/ProposalEventConsumer

@KafkaListener(topic = "proposal-events")
class ProposalEventConsumer:
    processProposalPort: ProcessProposalPort

    function onMessage(message: ProposalMessage):
        log.info("Received message type={} proposalId={} correlationId={}",
            message.type, message.proposalId, message.correlationId)

        command = new ProcessProposalCommand(
            proposalId: ProposalId.from(message.proposalId),
            action: message.type,
            correlationId: message.correlationId
        )

        result = processProposalPort.execute(command)

        match result:
            Success:
                log.info("Message processed proposalId={}", message.proposalId)
            NotFound:
                log.warn("Proposal not found proposalId={}", message.proposalId)
            Error:
                log.error("Failed to process message proposalId={} error={}",
                    message.proposalId, result.error)
```

**Estrutura de pastas para consumers:**

```
primary/
    message-consumer/
        [context]/
            consumer/          # Consumer classes
            mapper/            # Message DTO → Command
            message/           # Incoming message DTOs
```

**Regras (mesmas que Controllers):**
- Depender do Port, não do Use Case diretamente
- Converter Message DTO → Command (mapper)
- Logar entrada, saída e erros (ver skill `observability`)
- Tratar Result types com match/when

### 4. SECONDARY ADAPTERS (Saída)

**Localização:** `secondary/[tipo]/[context]/`

**Contém:**
- Repository Implementations
- External API Clients
- Message Publishers
- Cache Implementations
- ORM Entities (separadas do domínio!)
- Mappers (Domain ↔ ORM/DTO)
- Logs de integração

```
// secondary/persistence/[context]/adapter/CreditLimitRepositoryAdapter

@Repository
class CreditLimitRepositoryAdapter implements CreditLimitRepositoryPort:
    ormRepository: CreditLimitOrmRepository
    mapper: CreditLimitMapper

    function findByClientId(clientId: ClientId) -> CreditLimit or null:
        log.debug("Finding credit limit clientId={}", clientId)
        entity = ormRepository.findByClientId(clientId.toString())
        if entity is null:
            return null
        return mapper.toDomain(entity)

    function save(creditLimit: CreditLimit):
        log.debug("Saving credit limit id={}", creditLimit.id)
        entity = mapper.toEntity(creditLimit)
        ormRepository.save(entity)
```

```
// secondary/persistence/[context]/entity/CreditLimitEntity

// Anotações ORM aqui — separado do domínio!
@Entity("credit_limits")
class CreditLimitEntity:
    @Id id: UUID
    @Column("client_id") clientId: String
    @Column("total_limit") totalLimit: Decimal
    @Column("used_limit") usedLimit: Decimal
```

### Domain Event Dispatch (Secondary Adapter)

Após persistir o aggregate, o adapter publica os eventos coletados:

```
// secondary/persistence/[context]/adapter/OrderRepositoryAdapter

@Repository
class OrderRepositoryAdapter implements OrderRepositoryPort:
    ormRepository: OrderOrmRepository
    mapper: OrderMapper
    eventPublisher: DomainEventPublisher

    function save(order: Order):
        entity = mapper.toEntity(order)
        ormRepository.save(entity)

        events = order.domainEvents()
        for event in events:
            log.info("Publishing domain event type={} aggregateId={}",
                event.type, event.aggregateId)
            eventPublisher.publish(event)

        order.clearEvents()
```

**Regras:**
- Publicar eventos **após** persistência bem-sucedida
- Logar cada evento publicado com `type` e `aggregateId` (ver skill `observability`)
- Para alta confiabilidade, considerar Outbox Pattern (ver skill `ddd-patterns`)

---

## Fluxo de Dependências

```
Request → Controller → Port Primário → Use Case → Port Secundário ← Adapter ← DB
              │                            │               │                │
           PRIMARY                     DOMAIN           DOMAIN          SECONDARY
           ADAPTER                                                      ADAPTER
```

**Regra:** Código de infraestrutura DEPENDE do domínio. Nunca o contrário.

---

## Estrutura de Pastas

```
project/
├── domain/
│   ├── [context]/                          # Bounded Context (ex: credit)
│   │   ├── model/                          # Entities, VOs, Typed IDs
│   │   ├── event/                          # Domain Events
│   │   ├── ports/
│   │   │   ├── primary/                    # Input ports + Commands + Results
│   │   │   └── secondary/                  # Output ports (Repository, etc.)
│   │   ├── usecase/                        # Use Case implementations
│   │   └── service/                        # Domain Services
│   └── shared/                             # Shared Kernel
│       ├── model/                          # Money, tipos comuns
│       └── event/                          # DomainEvent interface
│
├── primary/
│   └── rest-server/
│       └── [context]/
│           ├── controller/
│           ├── mapper/                     # Request ↔ Command, Result ↔ Response
│           ├── request/
│           └── response/
│
├── secondary/
│   ├── persistence/
│   │   └── [context]/
│   │       ├── adapter/                    # Implementa ports
│   │       ├── entity/                     # ORM entities
│   │       ├── mapper/                     # Domain ↔ ORM
│   │       └── repository/                 # Framework repository interfaces
│   │
│   └── rest-client/                        # APIs externas
│       └── external/
│           ├── adapter/
│           ├── client/
│           ├── dto/
│           └── mapper/                     # External DTO ↔ Domain
│
├── main/                                   # Wiring, bootstrap
│   ├── Application
│   └── config/
│       └── AppConfig                       # DI, Feature Toggles
│
└── tests/                                  # Espelha estrutura de produção
    ├── domain/[context]/
    ├── primary/[context]/
    └── secondary/[context]/
```

**Nota:** Adaptar extensões de arquivo e convenções de pastas à linguagem do projeto.

---

## Decisão Rápida: Onde Colocar?

| O que | Onde | Módulo |
|-------|------|--------|
| Entity, VO, Domain Event | `[context]/model/` ou `event/` | domain |
| Repository interface | `[context]/ports/secondary/` | domain |
| Use Case interface | `[context]/ports/primary/` | domain |
| Use Case implementation | `[context]/usecase/` | domain |
| Domain Service | `[context]/service/` | domain |
| Factory pura (sem deps) | `[context]/model/` ou `[context]/factory/` | domain |
| Factory com deps/ports | `[context]/usecase/` (é um Use Case) | domain (application) |
| HTTP Controller | `[context]/controller/` | primary |
| Request/Response DTO | `[context]/request/` ou `response/` | primary |
| Request/Response Mapper | `[context]/mapper/` ou inline no controller | primary |
| ORM Entity | `[context]/entity/` | secondary/persistence |
| Domain ↔ ORM Mapper | `[context]/mapper/` | secondary/persistence |
| Repository implementation | `[context]/adapter/` | secondary/persistence |
| External API client | `external/client/` | secondary/rest-client |
| External DTO ↔ Domain Mapper | `external/mapper/` | secondary/rest-client |
| Feature Toggle config | `config/` | main |

---

## Anti-Patterns

| Anti-Pattern | Problema | Solução |
|---|---|---|
| ORM annotations no domínio | Domínio acoplado ao framework | ORM Entity separada no adapter + mapper |
| Use Case retorna ORM Entity | Infra vazando para cima | Retornar modelo de domínio |
| Regra de negócio no Controller | Lógica fora do domínio | Mover para Entity ou Domain Service |
| Framework DI no domínio | Domínio depende de framework | Injeção via construtor puro |
| Repository com Page/Sort/Query | Conceito de infra no port | Port simples, paginação no adapter |

---

## Mappers — Conversão Entre Camadas

### Onde Ficam

| Conversão | Quem Faz | Localização |
|-----------|----------|-------------|
| Request DTO → Command | Primary Adapter | `primary/[tipo]/[context]/mapper/` ou inline no controller |
| Result → Response DTO | Primary Adapter | `primary/[tipo]/[context]/mapper/` ou inline no controller |
| Domain Model → ORM Entity | Secondary Adapter | `secondary/persistence/[context]/mapper/` |
| ORM Entity → Domain Model | Secondary Adapter | `secondary/persistence/[context]/mapper/` |
| External API DTO → Domain Model | Secondary Adapter | `secondary/rest-client/[context]/mapper/` |

### Regras

1. **Mappers nunca ficam no domínio** — domínio não sabe que DTOs e ORM entities existem
2. **Um mapper por par de tipos** — `CreditLimitMapper` converte `CreditLimit ↔ CreditLimitEntity`
3. **Métodos nomeados `toDomain()` e `toEntity()` / `toResponse()`**
4. **Sem lógica de negócio no mapper** — apenas tradução de campos
5. **Mappers devem ser testados** quando a conversão não é trivial (campos calculados, enums diferentes, nullability)

### Exemplo

```
// secondary/persistence/[context]/mapper/CreditLimitMapper

class CreditLimitMapper:

    function toDomain(entity: CreditLimitEntity) -> CreditLimit:
        return new CreditLimit(
            id: CreditLimitId.from(entity.id),
            clientId: ClientId.from(entity.clientId),
            totalLimit: new Money(entity.totalLimit, Currency.BRL),
            usedLimit: new Money(entity.usedLimit, Currency.BRL)
        )

    function toEntity(domain: CreditLimit) -> CreditLimitEntity:
        return new CreditLimitEntity(
            id: domain.id.value,
            clientId: domain.clientId.value,
            totalLimit: domain.totalLimit.amount,
            usedLimit: domain.usedLimit.amount
        )
```

```
// primary/rest-server/[context]/mapper/SimulationMapper

class SimulationMapper:

    function toResponse(result: SimulateCreditResult.Success) -> SimulationResponse:
        return new SimulationResponse(
            installmentValue: result.simulation.pmt,
            totalDebt: result.simulation.totalDebt,
            interestRate: result.simulation.rate
        )
```

### Quando Testar Mappers

| Situação | Testar? |
|----------|---------|
| Mapeamento campo-a-campo direto | ❌ Trivial demais |
| Conversão de tipos (String → UUID, Decimal → Money) | ✅ Sim |
| Campos nullable no ORM, non-null no domínio | ✅ Sim |
| Enums com nomes diferentes entre camadas | ✅ Sim |
| Campos calculados ou derivados | ✅ Sim |

---

## Propagação de Erros Entre Camadas

O Result Pattern começa no domínio e se transforma em cada camada até virar resposta HTTP/mensagem.

### Fluxo Completo

```
Domain                  → Use Case               → Controller              → HTTP
─────────────────────────────────────────────────────────────────────────────────────
Entity retorna Result   → Use Case repassa        → Controller converte     → Status code
                          ou combina Results         Result em Response        + body

Money.subtract()        → SimulateUseCase         → CreditController        → 200, 404, 422
 └─ InsufficientFunds     └─ SimulateResult          └─ match result:
                              └─ Success                    Success → 200 + body
                              └─ ClientNotFound             ClientNotFound → 404
                              └─ NotEligible                NotEligible → 422
```

### Regras de Propagação

```
DOMÍNIO
  ↓ retorna Result type (sealed class, union, etc.)
  ↓ NÃO lança exception para erros esperados
  ↓ Exception APENAS para erros de programação (bugs, invariantes violadas)

USE CASE
  ↓ recebe Result do domínio
  ↓ pode combinar múltiplos Results
  ↓ retorna seu próprio Result type (pode ser diferente do domínio)
  ↓ NÃO captura exceptions — deixa subir

PRIMARY ADAPTER (Controller)
  ↓ recebe Result do Use Case
  ↓ converte para HTTP status + response body (via match/when)
  ↓ loga resultado (INFO para sucesso, WARN para erro esperado)
  ↓ NÃO tem lógica de negócio no match

GLOBAL EXCEPTION HANDLER (safety net)
  ↓ captura exceptions NÃO tratadas (bugs, erros de infra)
  ↓ loga com ERROR + stack trace
  ↓ retorna HTTP 500 genérico
```

### Exemplo Completo

```
// --- DOMAIN ---
// domain/[context]/model/CreditLimit

class CreditLimit:
    function reserveAmount(amount: Money) -> ReserveResult:
        if amount.isGreaterThan(availableLimit()):
            return ReserveResult.InsufficientLimit(availableLimit())
        return ReserveResult.Reserved(/* updated limit */)

ReserveResult:
    Reserved(updatedLimit: CreditLimit)
    InsufficientLimit(available: Money)


// --- USE CASE ---
// domain/[context]/usecase/CreateProposalUseCase

class CreateProposalUseCase:
    function execute(command) -> CreateProposalResult:
        limit = repository.findByClientId(command.clientId)
        if limit is null:
            return CreateProposalResult.ClientNotFound(command.clientId)

        reserveResult = limit.reserveAmount(command.amount)
        match reserveResult:
            InsufficientLimit -> return CreateProposalResult.InsufficientLimit(reserveResult.available)
            Reserved -> // continue...

        // ... criar proposta
        return CreateProposalResult.Created(proposal)

CreateProposalResult:
    Created(proposal)
    ClientNotFound(clientId)
    InsufficientLimit(available: Money)
    NotEligible(reason)


// --- CONTROLLER ---
// primary/rest-server/[context]/controller/ProposalController

@POST("/proposals")
function create(request) -> HttpResponse:
    log.info("POST /proposals clientId={}", request.clientId)

    result = createProposalPort.execute(request.toCommand())

    match result:
        Created:
            log.info("Proposal created id={}", result.proposal.id)
            return HTTP 201, mapper.toResponse(result.proposal)
        ClientNotFound:
            log.warn("Client not found clientId={}", result.clientId)
            return HTTP 404, error("Client not found")
        InsufficientLimit:
            log.warn("Insufficient limit clientId={}", request.clientId)
            return HTTP 422, error("Insufficient credit limit")
        NotEligible:
            log.warn("Not eligible clientId={}", request.clientId)
            return HTTP 422, error(result.reason)


// --- GLOBAL HANDLER (safety net) ---
// primary/shared/GlobalExceptionHandler

function handleUnexpected(exception) -> HttpResponse:
    log.error("Unhandled exception type={} message={}", exception.type, exception.message, exception)
    return HTTP 500, error("Internal server error")
```

### O que NÃO Fazer

```
// ❌ Controller capturando exception do domínio
try:
    result = useCase.execute(command)
catch ClientNotFoundException:
    return HTTP 404
// Use Result type em vez de try/catch

// ❌ Use Case convertendo para HTTP status
function execute(command):
    return HttpResponse(404, "Not found")
// Use Case retorna Result — controller converte

// ❌ Domínio logando erro
class CreditLimit:
    function reserve(amount):
        log.warn("Insufficient limit")  // NÃO!
        return InsufficientLimit(...)
// Domínio retorna Result silenciosamente — adapter loga
```

---

## Checklist

- [ ] Domínio sem imports de frameworks
- [ ] Entities com comportamento de negócio
- [ ] Ports são interfaces/contratos no domínio
- [ ] Controllers só fazem Request → Command e Result → Response
- [ ] ORM Entities separadas do modelo de domínio
- [ ] Logs nos adapters, não no domínio
- [ ] Testes de domínio unitários puros (sem framework, sem banco)
- [ ] Testes de adapters como integração
- [ ] Mappers em adapters, nunca no domínio
- [ ] Mappers testados quando conversão não é trivial
- [ ] Erros propagam como Result types (domínio → use case → controller → HTTP)
- [ ] Exceptions apenas para bugs, não para fluxo esperado
- [ ] Global exception handler como safety net (HTTP 500)