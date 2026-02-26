---
name: security
description: Security patterns for input validation, authentication, authorization, secrets management, and protection against common vulnerabilities (OWASP Top 10). Activated when handling user input, authentication, authorization, sensitive data, or external integrations.
metadata:
  version: 1.0.0
  priority: P1
  activation: intent-based — when working with user input, authentication, authorization, sensitive data, API keys, encryption, or external integrations.
  conflicts: For code placement decisions, defer to hexagonal-architecture. For domain validation rules, defer to ddd-patterns. For logging of sensitive data, defer to observability.
---

# Security — Segurança no Desenvolvimento

## Princípio

> Segurança não é feature — é propriedade do sistema.
> Todo input é hostil até que validado.
> Todo dado sensível é tóxico até que protegido.

---

## Quando Ativar

| Situação | Ativar? |
|----------|---------|
| Feature que recebe input externo (API, form, file upload) | Sempre |
| Implementar autenticação ou autorização | Sempre |
| Trabalhar com dados sensíveis (CPF, cartão, senhas, tokens) | Sempre |
| Integrar com API externa (enviar/receber credenciais) | Sempre |
| Criar endpoint público | Sempre |
| Código interno entre camadas (domain ↔ use case) | Não necessário |

---

## Validação de Input — Onde e Como

A validação acontece em **3 camadas**, cada uma com responsabilidade diferente:

| Camada | O que Validar | Como | Exemplo |
|--------|--------------|------|---------|
| Primary Adapter | Formato, tipo, tamanho, campos obrigatórios | Framework validation (annotations, decorators, schemas) | `@NotBlank`, `@Size(max=100)`, Zod schema |
| Use Case / Command | Pré-condições de negócio | Validação no construtor do Command | `require amount > 0`, `require installments in [6,12,24]` |
| Domain | Invariantes do modelo | Value Object constructors, Entity guards | `Money(amount < 0) → reject`, `Email(invalid) → reject` |

### Regra de Ouro

> **Valide na fronteira, reforce no domínio. Nunca confie que a camada anterior validou.**

```
// ❌ ERRADO — confiar que o controller validou
class CreateProposalUseCase:
    function execute(command):
        // assume que amount é positivo porque o controller validou
        proposal = new CreditProposal(amount: command.amount)

// ✅ CERTO — Value Object valida invariante
class Money:
    constructor(amount, currency):
        require amount >= 0, "Amount cannot be negative"
        // mesmo que o controller já tenha validado, o domínio garante
```

### Input Sanitization

```
// Sanitizar ANTES de processar

// ✅ Trim em strings de texto livre
name = request.name.trim()

// ✅ Normalizar emails
email = request.email.trim().toLowerCase()

// ✅ Rejeitar caracteres inesperados em campos restritos
if not matches(request.documentId, "^[0-9]{11}$"):
    return HTTP 400, "Invalid document format"
```

---

## OWASP Top 10 — Regras Práticas

### 1. Injection (SQL, NoSQL, LDAP, OS Command)

```
// ❌ NUNCA — concatenação de string em queries
query = "SELECT * FROM clients WHERE id = '" + clientId + "'"

// ✅ SEMPRE — queries parametrizadas
query = "SELECT * FROM clients WHERE id = ?"
params = [clientId]
```

**Regra:** Zero concatenação em queries. Usar prepared statements, query builders do ORM, ou parâmetros nomeados. Sempre.

### 2. Broken Authentication

| Regra | Implementação |
|-------|--------------|
| Tokens com expiração | JWT com `exp`, refresh tokens com rotação |
| Armazenamento seguro | Tokens em httpOnly cookies ou secure storage (nunca localStorage) |
| Rate limiting em login | Limitar tentativas por IP/conta (ex: 5 tentativas em 15 min) |
| Senhas com hash seguro | bcrypt, scrypt ou argon2 (nunca MD5, SHA-1) |

### 3. Sensitive Data Exposure

```
// ❌ NUNCA retornar dados sensíveis na response
return new ClientResponse(
    name: client.name,
    cpf: client.cpf,          // NÃO!
    password: client.password  // NUNCA!
)

// ✅ Retornar apenas o necessário, mascarar quando preciso
return new ClientResponse(
    name: client.name,
    maskedCpf: maskCpf(client.cpf)  // "***.***.***-89"
)
```

**Cross-ref:** Ver skill `observability` — seção "O que NÃO Logar" para regras de masking em logs.

### 4. XML External Entities (XXE)

- Desabilitar processamento de entidades externas em XML parsers
- Preferir JSON sobre XML quando possível

### 5. Broken Access Control

```
// ❌ ERRADO — verificar permissão apenas no frontend
if user.isAdmin():
    showDeleteButton()

// ✅ CERTO — verificar permissão no backend (adapter + use case)

// Primary Adapter: middleware/filter verifica autenticação
@Authenticated
@POST("/proposals/{id}/approve")
function approve(request, authenticatedUser):
    command = new ApproveProposalCommand(
        proposalId: request.id,
        approvedBy: authenticatedUser.id  // actor vem do token, não do request
    )
    return approveProposalPort.execute(command)

// Use Case: verifica autorização de negócio
class ApproveProposalUseCase:
    function execute(command) -> ApproveResult:
        user = userRepository.findById(command.approvedBy)
        if not user.hasPermission(Permission.APPROVE_PROPOSAL):
            return ApproveResult.Unauthorized(command.approvedBy)
        // ...
```

### 6. Security Misconfiguration

| Regra | Ação |
|-------|------|
| Debug mode em produção | Desabilitar sempre — sem stack traces para o cliente |
| Headers de segurança | HSTS, X-Content-Type-Options, X-Frame-Options, CSP |
| CORS | Restringir origens permitidas (nunca `*` em produção) |
| Default credentials | Trocar todas as credenciais default antes do deploy |

### 7. Cross-Site Scripting (XSS)

- Output encoding em toda resposta HTML
- Content Security Policy (CSP) headers
- Sanitizar input HTML (se permitir rich text)

### 8. Insecure Deserialization

- Nunca desserializar dados não confiáveis sem schema validation
- Usar type whitelists quando possível
- Preferir formatos simples (JSON com schema) sobre formatos binários opacos

### 9. Using Components with Known Vulnerabilities

- Executar dependency scanning regularmente (Dependabot, Snyk, OWASP Dependency-Check)
- Não ignorar alertas de segurança em dependências
- Preferir bibliotecas mantidas ativamente

### 10. Insufficient Logging & Monitoring

- Logar eventos de segurança: login, logout, falhas de autenticação, mudanças de permissão
- Ver skill `observability` para padrões de structured logging
- Alertas em padrões anômalos (muitas falhas de login, acesso a recursos proibidos)

---

## Gestão de Secrets

### Regra Principal

> **Nenhum secret deve existir em código-fonte ou arquivos commitados.**

### Onde Armazenar

| Ambiente | Onde |
|----------|------|
| Local (dev) | Variáveis de ambiente, `.env` (no `.gitignore`) |
| CI/CD | Secrets do pipeline (GitHub Secrets, GitLab CI Variables) |
| Produção | Secret Manager (Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) |

### `.gitignore` Obrigatório

```
# Secrets — NUNCA commitar
.env
.env.*
*.pem
*.key
credentials.json
**/secrets/
```

### Rotação

- API keys e tokens: rotacionar periodicamente (ex: a cada 90 dias)
- Após incidente de segurança: rotacionar imediatamente todos os secrets expostos
- Usar secrets com expiração quando possível

---

## Autenticação e Autorização na Arquitetura Hexagonal

### Onde Cada Responsabilidade Vive

```
┌─────────────────────────────────────────────────────────────┐
│ PRIMARY ADAPTER (middleware/filter)                          │
│  → Autenticação: Quem é você? (validar token, sessão)       │
│  → Extrair identidade do usuário do token                   │
│  → Rejeitar requests não autenticados (HTTP 401)            │
├─────────────────────────────────────────────────────────────┤
│ USE CASE                                                     │
│  → Autorização de negócio: Você pode fazer ISSO?             │
│  → Recebe actor como parâmetro (não busca do contexto)       │
│  → Retorna Result.Unauthorized quando necessário             │
├─────────────────────────────────────────────────────────────┤
│ DOMAIN                                                       │
│  → Regras de domínio que dependem do ator                    │
│  → Ex: "Só o gerente da conta pode aprovar"                  │
│  → Modelado como regra de negócio, não como "segurança"      │
└─────────────────────────────────────────────────────────────┘
```

### Regra do Actor

> **O ator (quem está executando a ação) é um parâmetro explícito do Use Case, nunca um contexto global.**

```
// ❌ ERRADO — buscar usuário de contexto global
class ApproveProposalUseCase:
    function execute(command):
        user = SecurityContext.getCurrentUser()  // acoplamento global

// ✅ CERTO — actor como parâmetro do command
class ApproveProposalCommand:
    proposalId: ProposalId
    approvedBy: UserId        // actor explícito

class ApproveProposalUseCase:
    function execute(command) -> ApproveResult:
        // usar command.approvedBy para verificar permissão
```

---

## Dados Sensíveis em Logs (Complemento à Observability)

### Classificação de Dados

| Categoria | Exemplos | Pode Logar? |
|-----------|----------|-------------|
| Identificador público | userId, orderId, correlationId | Sim |
| PII (dado pessoal) | nome, email, telefone, endereço | Não (ou mascarado) |
| Dado financeiro | número do cartão, conta bancária | Nunca |
| Credencial | senha, token, API key | Nunca |
| Documento | CPF, RG, SSN, passaporte | Não (ou últimos dígitos) |

### Padrões de Masking

```
// CPF: mostrar apenas últimos 2 dígitos
maskCpf("12345678901") -> "***.***.***-01"

// Email: mostrar primeiro caractere + domínio
maskEmail("joao@email.com") -> "j***@email.com"

// Cartão: mostrar apenas últimos 4 dígitos
maskCard("4111111111111111") -> "****-****-****-1111"

// Token/API Key: nunca logar, nem mascarado
// Log apenas que o token foi usado, não o valor
log.info("API call authenticated tokenType={} userId={}", "Bearer", userId)
```

### Audit Logging (Eventos de Segurança)

Eventos que **devem** ser logados para auditoria:

```
// Login bem-sucedido
log.info("User login success userId={} ip={} method={}", userId, ip, "password")

// Login falhou
log.warn("User login failed email={} ip={} reason={}", maskEmail(email), ip, "invalid_password")

// Mudança de permissão
log.info("Permission changed userId={} permission={} action={} changedBy={}",
    targetUserId, "APPROVE_PROPOSAL", "granted", adminUserId)

// Acesso a dados sensíveis
log.info("Sensitive data accessed userId={} resource={} resourceId={}",
    userId, "client_cpf", clientId)
```

---

## Integração com ADR

Quando uma feature lida com input externo ou dados sensíveis, a ADR deve incluir:

```markdown
## Segurança (se aplicável)

### Inputs Externos
- [campo 1]: [tipo, formato esperado, validação]
- [campo 2]: [tipo, formato esperado, validação]

### Dados Sensíveis Envolvidos
- [dado 1]: [como será protegido — masking, encryption, etc.]
- [dado 2]: [como será protegido]

### Autenticação / Autorização
- [quem pode acessar esta funcionalidade]
- [que permissões são necessárias]
- [actor é parâmetro do use case? sim/não]
```

> **Referência:** Ver skill `adr` para templates completos.

---

## Checklist

- [ ] Todos os inputs externos validados na fronteira (Primary Adapter)
- [ ] Value Objects e Entities auto-validam invariantes no construtor
- [ ] Zero concatenação de strings em queries (SQL, NoSQL, LDAP)
- [ ] Dados sensíveis mascarados em logs (ver skill `observability`)
- [ ] Secrets não estão hardcoded nem commitados (`.env` no `.gitignore`)
- [ ] Autenticação implementada no adapter (middleware/filter), não no domínio
- [ ] Autorização verificada no Use Case com actor como parâmetro explícito
- [ ] Eventos de segurança logados para auditoria (login, auth failure, permission change)
- [ ] Response DTOs não expõem dados sensíveis desnecessários
- [ ] Headers de segurança configurados (HSTS, CSP, X-Frame-Options)
- [ ] Dependency scanning configurado para vulnerabilidades conhecidas
- [ ] ADR inclui seção de segurança quando feature lida com input externo ou dados sensíveis
