---
name: safe-refactoring
description: Safe refactoring with parallel implementation and feature toggles. Activated when user wants to refactor, improve, extract, reorganize, rewrite, or address technical debt. NOT for new features — use tdd-workflow instead.
metadata:
  version: 2.0.0
  priority: P1
  activation: intent-based
  conflicts: Do NOT use TDD Red-Green-Refactor for refactoring. This skill replaces it. Readable Code still applies to the new implementation.
---

# Safe Refactoring — Feature Toggle Strategy

## Princípio

> Refactoring NUNCA modifica código existente diretamente.
> Sempre criar implementação paralela com feature toggle para rollback instantâneo.

---

## Quando Usar

| Situação | Usar esta Skill? |
|----------|-----------------|
| Reescrever algoritmo existente | ✅ Sim |
| Extrair classe/método de código existente | ✅ Sim |
| Mudar estrutura interna mantendo comportamento | ✅ Sim |
| Criar feature nova do zero | ❌ Não — usar TDD |
| Corrigir bug | ❌ Não — usar TDD (bug fix mode) |
| Renomear variável/método | ❌ Não — refactor trivial, fazer direto |

---

## Fluxo Obrigatório (5 Fases)

### Fase 1 — Inventário de Testes

Antes de tocar em qualquer código:

1. **Listar testes existentes** que cobrem o comportamento
2. **Avaliar cobertura** — há gaps?
3. **Adicionar testes faltantes** se necessário
4. **Baseline verde:** todos os testes DEVEM passar

```
Pergunta obrigatória ao usuário:
> "Vou refatorar [X]. Encontrei [N] testes cobrindo este comportamento.
>  Há [gaps identificados]. Quer que eu adicione testes antes de prosseguir?"
```

Se não existem testes: **criar testes de caracterização primeiro** (testes que documentam o comportamento atual, mesmo que seja incorreto).

### Fase 2 — Implementação Paralela

1. Criar nova implementação em arquivo/classe separado
2. Implementar **mesma interface/port** que o código antigo
3. Manter código antigo **100% intacto** — não modificar, não deletar

```
// ANTIGO — NÃO TOCAR
// domain/[context]/service/LegacyFinancialCalculator
class LegacyFinancialCalculator implements FinancialCalculatorPort:
    ...

// NOVO — implementação paralela
// domain/[context]/service/NewFinancialCalculator
class NewFinancialCalculator implements FinancialCalculatorPort:
    ...
```

**Nomear claramente:** Prefixar o antigo com `Legacy` se necessário, ou o novo com `New`/`V2`. Remover prefixo na Fase 5 (limpeza).

### Fase 3 — Feature Toggle

Toggle configurável externamente. Default = implementação antiga.

```
// main/config/CalculatorConfig

class CalculatorConfig:
    useNewCalculator: Boolean = from config("feature.toggle.new-calculator", default: false)

    function financialCalculator() -> FinancialCalculatorPort:
        if useNewCalculator:
            return new NewFinancialCalculator()
        return new LegacyFinancialCalculator()
```

```
# Arquivo de configuração — toggle desabilitado por default
feature:
  toggle:
    new-calculator: false
```

**Onde colocar o toggle:** No módulo `main/config/` (camada de wiring), nunca no domínio.

**Mecanismo de toggle** depende da linguagem/framework:
- Arquivo de config (YAML, JSON, .env)
- Variável de ambiente
- Feature flag service (LaunchDarkly, Unleash, etc.)
- Parâmetro de DI/IoC container

### Fase 4 — Validação e Deploy

```
1. Toggle OFF  → deploy → confirmar que tudo funciona (antigo rodando)
2. Toggle ON em staging → rodar testes de integração/E2E
3. Toggle ON em canary (5-10% tráfego) → monitorar métricas
4. Toggle ON para 100% → monitorar por [período acordado]
5. Se problemas em qualquer etapa → Toggle OFF = rollback instantâneo
```

**Métricas para monitorar:**
- Taxa de erro (comparar antes/depois)
- Latência (P50, P95, P99)
- Resultados de negócio (valores calculados, aprovações)

### Fase 5 — Limpeza (Após Estabilização)

Somente após período de estabilidade em produção:

1. Remover classe `Legacy`
2. Renomear `New` para nome definitivo
3. Remover feature toggle do config
4. Remover propriedade do arquivo de configuração
5. Consolidar testes (remover duplicação)

---

## Formato de Resposta do Claude

```
### 📋 Inventário

Testes existentes: [lista]
Gaps identificados: [lista ou "nenhum"]
Recomendação: [adicionar testes / prosseguir]

### 🔀 Implementação Paralela

[código da nova implementação]

> Código antigo mantido intacto em [caminho].

### 🔧 Feature Toggle

[código do toggle]

> Default: implementação antiga.
> Para ativar: [instrução de config]

### 📊 Plano de Validação

1. Deploy com toggle OFF
2. Staging com toggle ON
3. Canary X%
4. Rollout 100%
5. Limpeza após [período]
```

---

## Checklist

### Preparação
- [ ] Testes existentes identificados e passando
- [ ] Gaps de cobertura avaliados
- [ ] Testes adicionais criados se necessário
- [ ] Baseline verde confirmado

### Implementação
- [ ] Nova implementação em classe/arquivo separado
- [ ] Mesma interface/port que o código antigo
- [ ] Código antigo 100% intacto
- [ ] Nova implementação segue regras de Readable Code

### Toggle
- [ ] Feature toggle implementado na camada de wiring/config
- [ ] Configurável externamente (config file, env var, ou feature flag service)
- [ ] Default = implementação antiga

### Validação
- [ ] Deploy com toggle OFF funciona
- [ ] Staging com toggle ON funciona
- [ ] Métricas comparadas (erro, latência)

### Limpeza (pós-estabilização)
- [ ] Código antigo removido
- [ ] Toggle removido
- [ ] Testes consolidados
- [ ] Nomes definitivos aplicados