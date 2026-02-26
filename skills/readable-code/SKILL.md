---
name: readable-code
description: Always active. Enforces explicit, readable code with no magic numbers, no syntax sugar, no functional patterns. Every line must be understandable by a junior developer without language-specific knowledge.
metadata:
  version: 2.0.0
  priority: P0
  activation: always
---

# Readable Code — Código Legível e Manutenível

## Princípio

> O código deve ser legível como um texto. Um dev que nunca viu a linguagem
> deve entender a lógica lendo de cima para baixo, sem pesquisar syntax.

**Esta skill está SEMPRE ativa e tem prioridade sobre todas as outras em questões de sintaxe e legibilidade.**

---

## Regras Obrigatórias

### 1. Zero Números Mágicos

Todo valor literal deve ser extraído para constante nomeada que descreva seu propósito.

```
// ❌ ERRADO
dailyRate = iofRate / 100
factor = days / 365

// ✅ CERTO
PERCENTAGE_DIVISOR = 100
DAYS_IN_YEAR = 365

dailyRate = iofRate / PERCENTAGE_DIVISOR
factor = days / DAYS_IN_YEAR
```

**Exceções aceitas:**
- `0`, `1` como índice de lista (`list[0]`)
- Constantes nomeadas já fornecidas pela linguagem (ex: `BigDecimal.ZERO`)
- Valores em ranges de iteração (`1..n`, `range(1, n)`)

### 2. Sem Operator Overloading

Quando a linguagem permite sobrecarga de operadores em tipos customizados ou tipos de precisão arbitrária, usar chamadas de método explícitas.

```
// ❌ ERRADO — parece primitivo, mascara o tipo real
total = requestedAmount + tac
iof = operationValue * rate

// ✅ CERTO — explícito sobre o que está acontecendo
total = requestedAmount.add(tac)
iof = operationValue.multiply(rate)
```

**Mapeamento de referência (adaptar à linguagem do projeto):**

| Operador | Método Explícito |
|----------|-----------------|
| `a + b` | `a.add(b)` |
| `a - b` | `a.subtract(b)` |
| `a * b` | `a.multiply(b)` |
| `a / b` | `a.divide(b, scale, roundingMode)` |
| `a += b` | `a = a.add(b)` |
| `-a` | `a.negate()` |
| `a > b` | `a.compareTo(b) > 0` ou `a.isGreaterThan(b)` |

> **Impacto em DDD:** Value Objects como `Money` NÃO devem declarar operadores sobrecarregados. Devem expor métodos nomeados.

**Nota:** Para linguagens sem operator overloading nativo (Go, Java puro), esta regra já é satisfeita naturalmente.

### 3. Sem Funções Funcionais

Loops imperativos em vez de HOFs (Higher-Order Functions).

```
// ❌ ERRADO
total = items.fold(0, (acc, item) -> acc + item.value)
names = users.map(user -> user.name)
adults = users.filter(user -> user.age >= 18)

// ✅ CERTO
total = 0
for item in items:
    total = total + item.value

names = new List()
for user in users:
    names.add(user.name)

adults = new List()
for user in users:
    if user.age >= MINIMUM_ADULT_AGE:
        adults.add(user)
```

**Aplica-se a:** `map`, `filter`, `reduce`, `fold`, `flatMap`, `zip`, `sumOf`, `groupBy`, `forEach` com lógica, list comprehensions, LINQ queries.

**Exceção:** `forEach` simples sem transformação pode ser aceito se for idiomático da linguagem e não contiver lógica.

### 4. Sem Syntax Sugar

Priorizar formas explícitas. Adaptar à linguagem do projeto:

| Categoria | Evitar | Preferir |
|---|---|---|
| Destructuring | `(a, b) = pair` | `result = pair; a = result.first; b = result.second` |
| Expression body | `fun f(x) = x + 1` | Função com bloco e return explícito |
| Funções locais | Função dentro de função | Extrair como método privado da classe |
| Ternário complexo | `a ? b ? c : d : e` | `if/else` com blocos nomeados |
| String interpolation complexa | `"${a.calc(b).format()}"` | Variável intermediária + interpolação simples |
| Operador Elvis/null-coalescing em cadeia | `a?.b?.c ?: d` | Verificações explícitas com variáveis |
| Implicit returns | Última expressão como retorno | `return` explícito |

**Princípio geral:** Se um dev precisa pesquisar a syntax para entender o que acontece, é syntax sugar demais.

### 5. Variáveis Intermediárias Nomeadas

Toda expressão composta deve ser decomposta passo a passo.

```
// ❌ ERRADO — exige interpretação mental
cetMonthly = (1.0 + cetYearly) ^ (1.0 / 12.0) - 1.0

// ✅ CERTO — cada passo nomeado
GROWTH_FACTOR_BASELINE = 1.0
MONTHS_IN_YEAR = 12.0

yearlyGrowthFactor = GROWTH_FACTOR_BASELINE + cetYearly
yearlyToMonthlyExponent = GROWTH_FACTOR_BASELINE / MONTHS_IN_YEAR
monthlyGrowthFactor = power(yearlyGrowthFactor, yearlyToMonthlyExponent)
cetMonthly = monthlyGrowthFactor - GROWTH_FACTOR_BASELINE
```

### 6. Nomes Descritivos Completos

```
// ❌ ERRADO
amt = value
i = index
acc = accumulated
cf = cashFlow

// ✅ CERTO
amortizationAmount = value
installmentIndex = index
accumulatedIof = accumulated
cashFlowValue = cashFlow
```

**Exceção:** `i`, `j` em loops simples de iteração por índice são aceitos se o contexto é óbvio.

### 7. Documentação em Algoritmos Complexos

Algoritmos não triviais devem ter documentação explicando: **o quê**, **por quê** e **como**.

```
/**
 * Calcula a Taxa Interna de Retorno (TIR) usando Newton-Raphson.
 *
 * Encontra iterativamente a taxa que zera o VPL dos fluxos de caixa.
 * Necessário porque fluxos com datas irregulares não têm solução fechada.
 *
 * @param cashFlows — lista de valores (negativo = desembolso, positivo = recebimento)
 * @param dates — datas correspondentes a cada fluxo
 * @return taxa anual que zera o NPV
 * @throws ConvergenceException se não convergir em MAX_ITERATIONS
 */
```

Usar o formato de documentação padrão da linguagem do projeto (KDoc, JSDoc, XMLDoc, GoDoc, etc.).

### 8. Result Pattern para Erros Esperados

Não usar exceptions/throw para controle de fluxo. Usar tipos explícitos.

```
// ❌ ERRADO — exception para controle de fluxo
function findClient(id):
    throw ClientNotFoundException(id)

// ✅ CERTO — tipo de resultado explícito
FindClientResult:
    Found(client)
    NotFound(clientId)

function findClient(id) -> FindClientResult:
    ...
```

Implementação varia por linguagem:
- **Kotlin/Java:** sealed class / sealed interface
- **TypeScript:** discriminated union (`{ type: "found", client } | { type: "not_found", id }`)
- **C#:** OneOf, result types, ou abstract record
- **Go:** múltiplos retornos (`client, err`) ou tipo Result customizado
- **Rust:** `Result<T, E>` nativo

---

## Checklist Rápido

- [ ] Nenhum número literal sem constante nomeada
- [ ] Zero operator overloading em tipos de precisão/customizados
- [ ] Zero `fold`, `map`, `filter`, `zip`, `sumOf` — só `for`
- [ ] Zero syntax sugar que exija conhecimento avançado da linguagem
- [ ] Expressões compostas decompostas em variáveis nomeadas
- [ ] Nomes descritivos completos (sem abreviações)
- [ ] Documentação em todo algoritmo não trivial
- [ ] Result Pattern em vez de exceptions para fluxo