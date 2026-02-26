---
name: observability
description: Logging, monitoring, and tracing patterns. Activated when user works with logs, error handling, monitoring, tracing, metrics, or when implementing adapters that interact with external systems.
metadata:
  version: 2.0.0
  priority: P2
  activation: intent-based
  conflicts: Domain layer must remain silent (no direct logging). Logs live in adapters only.
---

# Pragmatic Observability

## Princípio

> O código deve ser rastreável sem poluir a lógica de negócio.
> Logs servem para diagnóstico técnico e auditoria de estado.
> O domínio é SILENCIOSO — adapters fazem o log.

---

## Regra Central: Quem Loga o Quê

| Camada | Loga? | O que |
|--------|-------|-------|
| Domain (Entities, VOs, Services) | ❌ Nunca | Retorna Result/Event — adapter decide se loga |
| Use Cases | ⚠️ Raro | Apenas orquestração crítica (início/fim de saga) |
| Primary Adapters (Controllers) | ✅ Sempre | Request recebido, response enviado, erros HTTP |
| Secondary Adapters (Repos, Clients) | ✅ Sempre | Query/chamada feita, resultado, erros de integração |
| Config/Wiring | ✅ Startup | Feature toggles ativos, beans/serviços carregados |

---

## Níveis de Log

| Nível | Quando Usar | Exemplo |
|-------|-------------|---------|
| `DEBUG` | Detalhes para troubleshooting local | `"Finding credit limit clientId={}"` |
| `INFO` | Mudanças de estado importantes | `"Proposal approved proposalId={} clientId={}"` |
| `WARN` | Falhas esperadas/recuperáveis | `"Client not eligible clientId={} reason={}"` |
| `ERROR` | Falhas inesperadas que exigem ação | `"Database connection failed after {} retries"` |

**Regra prática:** Se alguém vai precisar acordar de madrugada por causa disso → `ERROR`. Se pode esperar o horário comercial → `WARN`. Se é fluxo normal → `INFO`.

---

## Padrões Obrigatórios

### 1. Structured Logging (Key-Value)

```
// ❌ ERRADO — string concatenada, difícil de parsear
log.info("Proposal " + proposalId + " approved for client " + clientId)

// ❌ ERRADO — template sem contexto estruturado
log.info("Proposal approved: {}, {}", proposalId, clientId)

// ✅ CERTO — structured com chaves nomeadas
log.info("Proposal approved proposalId={} clientId={}", proposalId, clientId)
```

**Por quê:** Ferramentas de observabilidade (Datadog, Splunk, CloudWatch, Grafana Loki, ELK) filtram por `proposalId=X`. Strings concatenadas não permitem isso.

**Alternativa JSON (se o framework suportar):**
```
log.info({ event: "proposal_approved", proposalId: "123", clientId: "456" })
```

### 2. Correlation ID (Rastreabilidade)

Toda operação deve carregar um ID de correlação para rastrear o fluxo completo de um request.

```
// primary/shared/CorrelationIdFilter (ou middleware, interceptor, etc.)

class CorrelationIdFilter:
    HEADER = "X-Correlation-Id"
    CONTEXT_KEY = "correlationId"

    function handle(request, response, next):
        correlationId = request.header(HEADER) or generateUUID()

        // Colocar no contexto de logging (MDC, AsyncLocalStorage, context.Context, etc.)
        loggingContext.put(CONTEXT_KEY, correlationId)
        response.setHeader(HEADER, correlationId)

        try:
            next(request, response)
        finally:
            loggingContext.clear()
```

**Configurar o formato de log para incluir automaticamente:**
```
// Formato de log — correlationId em toda linha
[timestamp] [level] [logger] correlationId={correlationId} - {message}
```

**Implementação varia por linguagem:**
- **Java/Kotlin:** SLF4J MDC
- **Node.js:** AsyncLocalStorage ou cls-hooked
- **Go:** context.Context
- **C#:** Activity/CorrelationManager
- **Python:** contextvars

### 3. Sem Strings Mágicas

```
// ❌ ERRADO — string duplicada em vários lugares
log.info("Proposal approved proposalId={} clientId={}", id, client)
log.info("Proposal approved proposalId={} clientId={}", id, client)  // outro arquivo

// ✅ CERTO — constantes de log centralizadas
module LogMessages:
    PROPOSAL_APPROVED = "Proposal approved proposalId={} clientId={}"
    PROPOSAL_REJECTED = "Proposal rejected proposalId={} clientId={} reason={}"
    CLIENT_NOT_FOUND = "Client not found clientId={}"
    INTEGRATION_ERROR = "Integration error service={} operation={} error={}"
    INTEGRATION_TIMEOUT = "Integration timeout service={} operation={} timeoutMs={}"

log.info(LogMessages.PROPOSAL_APPROVED, proposalId, clientId)
```

### 4. Log em Adapters — Padrão Entry/Exit/Error

```
// secondary/rest-client/external/adapter/ScoringApiAdapter

class ScoringApiAdapter implements ScoringPort:
    client: ScoringApiClient

    function evaluate(clientId) -> ScoringResult:
        // ENTRY
        log.info("Calling scoring API clientId={}", clientId)

        try:
            response = client.evaluate(clientId.toString())

            // EXIT (sucesso)
            log.info("Scoring API responded clientId={} score={} status={}",
                clientId, response.score, response.status)

            return mapper.toDomain(response)

        catch TimeoutException:
            // EXIT (falha recuperável)
            log.warn(LogMessages.INTEGRATION_TIMEOUT,
                "scoring-api", "evaluate", TIMEOUT_MS)
            return ScoringResult.Unavailable("Timeout")

        catch Exception as e:
            // EXIT (falha inesperada)
            log.error(LogMessages.INTEGRATION_ERROR,
                "scoring-api", "evaluate", e.message,
                e)  // stack trace completo no ERROR
            return ScoringResult.Unavailable(e.message)
```

**Padrão:**
- `INFO` na entrada (o que vai fazer)
- `INFO` na saída com sucesso (resultado resumido)
- `WARN` em falha recuperável (timeout, retry)
- `ERROR` em falha inesperada (com exception/stack trace)

### 5. Controller — Log de Request/Response

```
// primary/rest-server/[context]/controller/CreditController

@POST("/proposals")
function createProposal(request) -> HttpResponse:
    log.info("POST /proposals clientId={} amount={}", request.clientId, request.amount)

    result = createProposalPort.execute(request.toCommand())

    match result:
        Created:
            log.info("Proposal created proposalId={} clientId={}",
                result.proposal.id, request.clientId)
            return HTTP 201, result.proposal.toResponse()

        NotEligible:
            log.warn("Proposal rejected clientId={} reason=not_eligible", request.clientId)
            return HTTP 422, error("Client not eligible")

        ClientNotFound:
            log.warn(LogMessages.CLIENT_NOT_FOUND, request.clientId)
            return HTTP 404, error("Client not found")
```

### 6. Logging de Domain Events

Quando o adapter publica Domain Events (ver skill `ddd-patterns` e `hexagonal-architecture`):

```
// secondary/persistence/[context]/adapter/ ou secondary/message-publisher/

// Publicação bem-sucedida
log.info("Domain event published type={} aggregateId={} correlationId={}",
    event.type, event.aggregateId, correlationId)

// Falha na publicação
log.error("Domain event publish failed type={} aggregateId={} error={}",
    event.type, event.aggregateId, error.message, error)
```

**Regras:**
- Logar no **adapter que publica**, não no domínio
- Nível `INFO` para publicação bem-sucedida
- Nível `ERROR` para falha na publicação (pode causar inconsistência)
- Campos obrigatórios: `type`, `aggregateId`, `correlationId`

### 7. Logging de Result Types

Quando o Controller (Primary Adapter) recebe um Result do Use Case, o nível de log depende do tipo de resultado:

```
match result:
    Success:
        log.info("Operation succeeded operationId={} resultType=success", operationId)
    ExpectedFailure (ClientNotFound, NotEligible, InsufficientLimit):
        log.warn("Operation failed operationId={} resultType={} reason={}",
            operationId, result.type, result.reason)
```

| Result Type | Nível | Motivo |
|-------------|-------|--------|
| Success | `INFO` | Fluxo normal concluído |
| Erro esperado de negócio (NotEligible, InsufficientLimit) | `WARN` | Falha esperada, não precisa acordar ninguém |
| Erro de infraestrutura (Timeout, ConnectionError) | `ERROR` | Falha inesperada, requer ação |

> **Referência:** Ver propagação completa de erros na skill `hexagonal-architecture`, seção "Propagação de Erros Entre Camadas".

### 8. Exceção Global — Log Centralizado

```
// primary/shared/GlobalExceptionHandler (ou error middleware)

class GlobalExceptionHandler:

    function handleUnexpected(exception) -> HttpResponse:
        log.error("Unhandled exception type={} message={}",
            exception.type, exception.message,
            exception)  // stack trace
        return HTTP 500, error("Internal server error")

    function handleValidation(exception) -> HttpResponse:
        log.warn("Validation failed fields={}", exception.invalidFields)
        return HTTP 400, error("Validation failed")
```

---

## O que NÃO Logar

| Não Logar | Motivo |
|-----------|--------|
| Senhas, tokens, API keys | Segurança |
| CPF, cartão de crédito, SSN completo | LGPD/GDPR/PCI |
| Request/response body inteiro | Performance e volume |
| Dados dentro de loops (N logs por request) | Volume explosivo |
| Stack trace em WARN | Poluição — stack trace só em ERROR |

**Mascaramento:**

```
// ✅ Logar apenas últimos dígitos
log.info("Processing payment card=****{}", card.lastFourDigits)

// ✅ Logar apenas ID, não dados pessoais
log.info("Client found clientId={}", clientId)
// NÃO: log.info("Client found name={} cpf={}", name, cpf)
```

---

## Métricas

### Tipos de Métricas

| Tipo | Quando Usar | Exemplo |
|------|------------|---------|
| Counter | Contagem de eventos cumulativa | `requests_total`, `errors_total`, `events_published_total` |
| Histogram | Distribuição de valores (latência, tamanho) | `request_duration_seconds`, `payload_size_bytes` |
| Gauge | Valor instantâneo que sobe e desce | `active_connections`, `queue_size`, `cache_hit_ratio` |

### Onde Instrumentar por Camada

| Camada | Métricas | Tipo |
|--------|----------|------|
| Primary Adapter | `request_count`, `request_duration`, `response_status` | Counter, Histogram, Counter |
| Secondary Adapter | `external_call_count`, `external_call_duration`, `external_call_errors` | Counter, Histogram, Counter |
| Use Case | `operation_count`, `operation_result` (por tipo: success/failure) | Counter |
| Config/Wiring | `feature_toggle_status` (0 ou 1 por toggle) | Gauge |

### Padrão de Nomenclatura

```
[serviço]_[subsistema]_[métrica]_[unidade]

Exemplos:
  credit_api_request_duration_seconds
  credit_scoring_call_errors_total
  credit_proposals_created_total
  credit_feature_toggle_status
```

### Logs vs Métricas — Quando Usar Cada

| Pergunta | Use |
|----------|-----|
| "O que aconteceu neste request específico?" | Log |
| "Quantos requests falharam nos últimos 5 minutos?" | Métrica (Counter) |
| "Qual a latência P95 da API de scoring?" | Métrica (Histogram) |
| "Por que este request falhou?" | Log (com correlationId) |
| "O feature toggle está ativo?" | Métrica (Gauge) |

---

## Tracing Distribuído

### Quando Usar

- Chamadas entre serviços (microserviços)
- Operações assíncronas (mensageria, filas)
- Queries a banco de dados (quando latência é concern)
- Chamadas a APIs externas

### Conceitos

| Conceito | Descrição |
|----------|-----------|
| Trace | Fluxo completo de um request, do início ao fim |
| Span | Uma operação individual dentro do trace (HTTP call, DB query, message publish) |
| Trace ID | Identificador único do trace completo |
| Span ID | Identificador único de cada operação |

### Padrão

```
// Criar span por operação significativa
span = tracer.startSpan("scoring-api.evaluate")
span.setAttribute("client.id", clientId)

try:
    result = scoringClient.evaluate(clientId)
    span.setStatus(OK)
finally:
    span.end()
```

### Propagação

- Via headers HTTP: W3C Trace Context (`traceparent`) ou B3
- Via mensageria: headers da mensagem
- Via contexto interno: MDC, AsyncLocalStorage, context.Context

### Integração com Logging

> **Regra:** O `correlationId` dos logs DEVE ser o `traceId` quando tracing está ativo.
> Isso permite correlacionar logs e traces na mesma ferramenta de observabilidade.

```
// Configurar no CorrelationIdFilter
correlationId = request.header("traceparent")?.extractTraceId() or generateUUID()
loggingContext.put("correlationId", correlationId)
```

---

## Health Checks

### Endpoints Obrigatórios

| Endpoint | Propósito | Retorno |
|----------|-----------|---------|
| `/health/live` | Aplicação está rodando (liveness) | `200 OK` se processo está vivo |
| `/health/ready` | Dependências acessíveis (readiness) | `200 OK` se todas as deps estão acessíveis |

### O que Verificar no Readiness

| Dependência | Verificação |
|-------------|-------------|
| Banco de dados | Conexão ativa (query simples: `SELECT 1`) |
| APIs externas | Endpoint acessível ou cache fresh |
| Message broker | Conexão ativa com o broker |
| Cache (Redis, etc.) | Conexão ativa (PING) |

### Regras

- Liveness: **nunca** verificar dependências externas (pode causar cascata de falhas)
- Readiness: verificar **todas** as dependências necessárias
- Não logar em cada chamada de health check (volume excessivo)
- Timeout curto para verificações (< 3 segundos)

---

## Checklist

- [ ] Domínio não faz log — retorna Result/Event
- [ ] Primary Adapters logam request/response
- [ ] Secondary Adapters logam entry/exit/error
- [ ] Structured logging com chaves nomeadas (key=value ou JSON)
- [ ] Correlation ID propagado via contexto de logging da linguagem
- [ ] Constantes para mensagens recorrentes
- [ ] Dados sensíveis mascarados ou omitidos
- [ ] ERROR = precisa acordar alguém. WARN = pode esperar
- [ ] Stack trace apenas em ERROR, não em WARN
- [ ] Exception handler global como safety net
- [ ] Domain Events logados no adapter de publicação (type, aggregateId, correlationId)
- [ ] Result types logados com nível adequado (Success=INFO, Business failure=WARN, Infra failure=ERROR)
- [ ] Métricas instrumentadas em adapters (request count, duration, errors)
- [ ] Nomenclatura de métricas padronizada: `[serviço]_[subsistema]_[métrica]_[unidade]`
- [ ] Health checks implementados (/health/live e /health/ready)