---
name: tdd-workflow
description: Enforces TDD Red-Green-Refactor for new features, methods, classes, and bug fixes. Activated when user intends to create, implement, add, build, fix, correct, or debug.
metadata:
  version: 2.0.0
  priority: P1
  activation: intent-based
  conflicts: Do NOT activate for refactoring existing code — use safe-refactoring instead.
---

# TDD Workflow — Red Green Refactor

## Princípio

> Nenhum código de produção existe sem um teste que o justifique.
> O teste é escrito PRIMEIRO, falha PRIMEIRO, e só então o código nasce.

---

## Fluxo para Features Novas

### Passo 1 — Entender o Comportamento

Antes de escrever qualquer código, listar os comportamentos esperados:

```
Comportamentos de Money:
- Criar Money com amount e currency
- Rejeitar amount negativo
- Somar dois Money da mesma currency
- Rejeitar soma de currencies diferentes
```

### Passo 2 — RED (Teste que Falha)

Criar arquivo de teste espelhando a estrutura de produção:

```
# Produção (ainda NÃO existe)
domain/src/main/.../credit/model/Money

# Teste (criar PRIMEIRO)
domain/src/test/.../credit/model/MoneyTest
```

Escrever UM teste por vez. O teste mais simples primeiro:

```
class MoneyTest:

    test "should create Money with valid amount and currency":
        money = Money.create(100.00, Currency.BRL)

        assert money.amount == 100.00
        assert money.currency == Currency.BRL
```

**Rodar o teste. Confirmar que falha.** Informar ao usuário:
> "Teste falha porque a classe Money não existe ainda. Vou implementar o mínimo para passar."

### Passo 3 — GREEN (Código Mínimo)

Implementar APENAS o necessário para o teste passar. Nada mais.

```
class Money:
    amount: Decimal
    currency: Currency

    static function create(amount, currency):
        return new Money(amount, currency)
```

**Rodar o teste. Confirmar que passa.**

### Passo 4 — Próximo Teste (Repetir RED → GREEN)

```
test "should reject negative amount":
    assertThrows IllegalArgumentException:
        Money.create(-1.00, Currency.BRL)
```

Falha → adicionar validação → passa → próximo teste.

### Passo 5 — REFACTOR (Opcional, Perguntar)

Após todos os comportamentos cobertos, perguntar:

> "Todos os testes passando. Deseja refatorar algo ou adicionar mais cenários?"

Refatorar SOMENTE com todos os testes verdes. Se um teste quebrar, desfazer.

---

## Fluxo para Bug Fixes

### Passo 1 — Reproduzir com Teste

```
test "should calculate IOF correctly for 30-day period — bug #1234":
    // Cenário que reproduz o bug reportado
    result = calculator.calculateIof(amount: 1000.00, days: 30)

    // Valor correto esperado (não o valor com bug)
    assert result == 3.08
```

**Rodar. Confirmar que falha** (reproduz o bug).

### Passo 2 — Corrigir com Código Mínimo

Alterar o mínimo necessário para o teste passar.

### Passo 3 — Confirmar Regressão

Rodar TODOS os testes do módulo. Nenhum pode ter quebrado.

---

## Regras de Estrutura de Testes

### Nomenclatura

```
// Padrão: should [comportamento] when [condição]
test "should reject proposal when client has no credit limit"
test "should calculate monthly installment for 12 months"
```

### Organização (Arrange-Act-Assert)

```
test "should sum two Money of same currency":
    // Arrange
    first = Money.create(100.00, Currency.BRL)
    second = Money.create(50.00, Currency.BRL)

    // Act
    result = first.add(second)

    // Assert
    assert result.amount == 150.00
    assert result.currency == Currency.BRL
```

### Um Conceito por Teste

```
// ❌ ERRADO — testa múltiplos conceitos
test "should validate Money":
    // testa criação, soma, subtração, validação tudo junto

// ✅ CERTO — um conceito isolado
test "should reject negative amount"
test "should reject currency mismatch on add"
```

### Sem Lógica no Teste

```
// ❌ ERRADO — lógica no teste (if, for, cálculos)
test "should calculate total":
    expected = 0
    for item in items:
        expected = expected + item.price
    assert result == expected

// ✅ CERTO — valor esperado hardcoded
test "should calculate total of three items":
    result = order.total()
    assert result.amount == 300.00
```

---

## Testes por Camada

| Camada | Tipo de Teste | Dependências |
|--------|--------------|--------------|
| Domain (Entities, VOs) | Unitário puro | Nenhuma — sem mocks, sem framework |
| Domain Services | Unitário puro | Nenhuma ou mocks simples |
| Use Cases | Unitário com mocks | Mocks para ports secundários |
| Primary Adapters | Integração | Framework de teste HTTP |
| Secondary Adapters | Integração | Banco em memória ou containers |

```
// Teste de Use Case com mock
class SimulateCreditUseCaseTest:

    creditLimitRepository = mock(CreditLimitRepositoryPort)
    calculator = new FinancialCalculator()
    useCase = new SimulateCreditUseCase(creditLimitRepository, calculator)

    test "should return simulation when client is eligible":
        // Arrange
        when creditLimitRepository.findByClientId(any) then return validCreditLimit()

        // Act
        result = useCase.simulate(validCommand())

        // Assert
        assert result is SimulateCreditResult.Success
```

---

## Infraestrutura de Testes

### Test Fixtures / Builders

Quando o bloco Arrange se repete entre testes, extrair para fixture ou builder:

```
// test/domain/credit/model/fixtures/MoneyFixtures

class MoneyFixtures:
    static function tenReais() -> Money:
        return Money.create(10.00, Currency.BRL)

    static function hundredReais() -> Money:
        return Money.create(100.00, Currency.BRL)

    static function zeroBrl() -> Money:
        return Money.ZERO_BRL
```

**Regras:**
- Fixtures ficam no pacote de **teste**, nunca em produção
- Nomes descritivos (`tenReais()`, não `money1()`)
- Builders para objetos complexos (muitos campos), static methods para simples
- Não criar fixture "genérica" que serve para tudo — cada teste deve expressar o que é relevante

### Testes de Integração (Secondary Adapters)

| Tipo | Ferramenta | Quando Usar |
|------|-----------|-------------|
| Banco em memória | H2, SQLite | Testes rápidos de queries simples |
| Testcontainers | Docker container real | Testes com DB real (Postgres, MySQL, Mongo) |
| WireMock / MockServer | Mock de API HTTP | Testes de clients REST externos |
| Embedded Broker | Kafka/RabbitMQ embedded | Testes de consumers/publishers |

**Regras para integração:**
- Cada teste limpa seu próprio estado (não depende de ordem de execução)
- Usar transação com rollback ou truncate entre testes
- WireMock: configurar stubs específicos por cenário, não um stub genérico
- Testar cenários de erro (timeout, connection refused, 500)

```
// test/secondary/persistence/credit/adapter/CreditLimitRepositoryAdapterTest

class CreditLimitRepositoryAdapterTest:
    // Arrange: banco in-memory ou testcontainer
    repository = new CreditLimitRepositoryAdapter(testDataSource)

    test "should save and retrieve credit limit":
        limit = CreditLimitFixtures.validLimit()
        repository.save(limit)

        found = repository.findByClientId(limit.clientId)

        assert found is not null
        assert found.totalLimit == limit.totalLimit
```

---

## Formato de Resposta do Claude

Ao implementar com TDD, seguir este formato:

```
### 🔴 RED — [nome do teste]

[código do teste]

> Teste falha porque: [motivo]

### 🟢 GREEN — [o que foi implementado]

[código de produção]

> Teste passa. [X] de [Y] comportamentos cobertos.

### 🔵 REFACTOR? (quando todos passarem)

> Todos os testes passando. Deseja refatorar ou adicionar cenários?
```

---

## Testes de Caracterização

Usados **antes de refatorar** código sem testes, ou para **documentar comportamento legado**.

Diferente do TDD normal: aqui o código já existe e o teste **descobre** o comportamento, não o define.

### Quando Usar

- Safe Refactoring pede inventário de testes e não existem testes
- Código legado precisa ser entendido antes de modificar
- Comportamento atual não está documentado

### Fluxo

```
1. Identificar método/classe a caracterizar
2. Escrever teste com assertion VAZIA ou ERRADA de propósito
3. Rodar — ver o valor real que o código retorna
4. Atualizar assertion com o valor real
5. Repetir para outros inputs (borda, erro, extremos)
```

### Exemplo

```
// Passo 1-2: assertion errada de propósito
test "characterize: IOF calculation for 30 days":
    result = calculator.calculateIof(amount: 1000.00, days: 30)
    assert result == 0  // vai falhar — quero ver o valor real

// Passo 3: teste falha com "expected 0, got 3.08"

// Passo 4: atualizar com o valor real
test "characterize: IOF calculation for 30 days":
    result = calculator.calculateIof(amount: 1000.00, days: 30)
    assert result == 3.08  // comportamento atual documentado
```

### Regras

- Prefixar com `characterize:` para diferenciar de testes normais
- **Não corrigir bugs** durante caracterização — documentar o que existe
- Anotar se o valor parece errado: `// TODO: possível bug — verificar regra`
- Estes testes são temporários — após refatoração, substituir por testes definitivos

---

## Checklist

- [ ] Teste criado ANTES do código de produção
- [ ] Teste confirmado como RED (falha) antes de implementar
- [ ] Código mínimo para GREEN (sem over-engineering)
- [ ] Estrutura de teste espelha produção
- [ ] Nomenclatura: `should [behavior] when [condition]`
- [ ] Arrange-Act-Assert
- [ ] Um conceito por teste
- [ ] Sem lógica condicional nos testes
- [ ] Bug fix: teste reproduz o bug antes do fix
- [ ] Testes de caracterização: prefixados com `characterize:`, valor real do sistema