---
name: adr
description: Architecture Decision Record. Must be created BEFORE any development begins — new features, bug fixes, or refactoring. Defines context, decision, consequences, and implementation roadmap so that both humans and AI have a clear north star before writing code.
metadata:
  version: 1.0.0
  priority: P0
  activation: always — before any implementation skill (TDD, Safe Refactoring)
  conflicts: None. This skill runs FIRST, then hands off to TDD or Safe Refactoring.
---

# ADR — Architecture Decision Record

## Princípio

> Nenhum código é escrito antes de existir uma ADR aprovada.
> A ADR é o contrato entre quem pede e quem implementa (humano ou IA).
> Se a ADR não está clara o suficiente para uma IA executar, não está clara o suficiente para ninguém.

---

## Quando Criar

| Situação | Criar ADR? |
|----------|-----------|
| Feature nova | ✅ Sempre |
| Bug fix | ✅ Sempre (ADR simplificada) |
| Refatoração | ✅ Sempre |
| Renomear variável / fix de typo | ❌ Não |
| Atualizar dependência sem breaking change | ❌ Não |

**Regra:** Se vai ativar TDD ou Safe Refactoring, a ADR vem antes.

---

## Fluxo

```
1. Usuário descreve o que quer
2. Claude cria ADR (rascunho)
3. Usuário revisa e aprova (ou pede ajustes)
4. ADR aprovada → Claude inicia implementação via TDD ou Safe Refactoring
```

**Claude NÃO deve iniciar código antes da ADR ser aprovada pelo usuário.**

### Modo Simplificado (Escape Hatch)

Quando o CLAUDE.md ativa o pipeline simplificado (usuário pede urgência — "só faz", "direto", "rápido"):

A ADR é reduzida a **≤ 10 linhas** apresentadas **inline na conversa** (sem arquivo separado):

```markdown
**ADR inline:** [título]
- **Contexto:** [2-3 frases do problema]
- **Decisão:** [2-3 frases do que será feito]
- **Regras:** [lista curta das regras de negócio]
- **Testes:** [lista curta dos cenários esperados]
> Aprovar para gerar tarefas e iniciar execução?
```

**O que NÃO pode ser pulado no modo simplificado:**
- Contexto e decisão (mesmo que curtos)
- Regras de negócio testáveis
- Casos de teste esperados
- Aprovação do usuário

---

## Template: Feature Nova

```markdown
# ADR-[NNN]: [Título curto e descritivo]

## Status
[Proposta | Aprovada | Substituída por ADR-XXX]

## Data
[YYYY-MM-DD]

## Contexto
[Qual problema estamos resolvendo? Por que agora? Qual é o cenário atual?]

## Decisão
[O que vamos fazer. Ser específico: padrões, camadas, tipos envolvidos.]

## Consequências

### Positivas
- [benefício 1]
- [benefício 2]

### Negativas / Trade-offs
- [custo ou risco aceito 1]
- [custo ou risco aceito 2]

## Escopo

### Incluído
- [o que FAZ parte desta entrega]

### Excluído
- [o que NÃO faz parte — será tratado em outra ADR ou momento]

## Design Técnico

### Camada de Domínio
- Entities: [listar entidades novas ou modificadas]
- Value Objects: [listar VOs novos]
- Domain Events: [listar eventos]
- Domain Services: [listar se necessário]
- Repository Ports: [listar interfaces]

### Camada de Aplicação
- Use Cases: [listar use cases e seus commands/results]
- Ports Primários: [listar interfaces de entrada]

### Camada de Infraestrutura
- Primary Adapters: [controllers, consumers, etc.]
- Secondary Adapters: [repository impls, API clients, etc.]
- ORM Entities: [se aplicável]

### Contratos
- Endpoints: [método, path, request/response resumido]
- Eventos publicados: [nome, payload resumido]
- Eventos consumidos: [nome, origem]

## Regras de Negócio
1. [Regra clara e testável]
2. [Regra clara e testável]
3. [Regra clara e testável]

## Casos de Teste Esperados
- [ ] [cenário positivo principal]
- [ ] [cenário de borda 1]
- [ ] [cenário de erro 1]
- [ ] [cenário de validação 1]

## Dependências
- [sistemas, serviços ou ADRs que esta decisão depende]

## Observabilidade
- Logs: [quais eventos logar e em qual nível]
- Métricas: [o que medir, se aplicável]
- Alertas: [condições que geram alerta, se aplicável]

## Segurança (se aplicável)

### Inputs Externos
- [campo]: [tipo, formato esperado, validação]

### Dados Sensíveis Envolvidos
- [dado]: [como será protegido — masking, encryption, etc.]

### Autenticação / Autorização
- [quem pode acessar esta funcionalidade]
- [que permissões são necessárias]
```

---

## Template: Bug Fix

```markdown
# ADR-[NNN]: Fix — [Descrição curta do bug]

## Status
[Proposta | Aprovada]

## Data
[YYYY-MM-DD]

## Bug
- **Reportado em:** [ticket, mensagem, observação]
- **Comportamento atual:** [o que está acontecendo de errado]
- **Comportamento esperado:** [o que deveria acontecer]
- **Impacto:** [quem é afetado e com que gravidade]

## Causa Raiz
[Análise de por que o bug acontece. Se ainda não sabe, indicar que investigação é necessária.]

## Correção Proposta
[O que vai mudar. Ser específico: qual arquivo, qual método, qual lógica.]

## Escopo

### Incluído
- [o que FAZ parte deste fix]

### Excluído
- [melhorias ou refatorações que NÃO entram agora]

## Testes de Regressão
- [ ] [teste que reproduz o bug — deve falhar antes do fix]
- [ ] [teste que confirma o fix — deve passar depois]
- [ ] [testes existentes que NÃO podem quebrar]

## Observabilidade
- [log ou alerta a adicionar para detectar recorrência]
```

---

## Template: Refatoração

```markdown
# ADR-[NNN]: Refactor — [O que está sendo refatorado]

## Status
[Proposta | Aprovada]

## Data
[YYYY-MM-DD]

## Contexto
[Por que refatorar? Qual problema o código atual causa?]

## Decisão
[Como será a nova implementação. Diferenças em relação ao código atual.]

## Estratégia
- Implementação paralela com feature toggle (ver skill Safe Refactoring)
- Toggle name: `feature.toggle.[nome]`
- Default: implementação antiga

## Escopo

### Incluído
- [o que será refatorado]

### Excluído
- [o que NÃO será tocado]

## Testes
- Testes existentes: [listar ou indicar cobertura]
- Gaps identificados: [testes faltantes]
- Testes de caracterização: [se necessário criar antes]

## Critérios de Estabilização
- Período: [ex: 1 semana em produção sem incidentes]
- Métricas: [erro rate, latência — comparar antes/depois]

## Limpeza Pós-Estabilização
- [ ] Remover implementação antiga
- [ ] Remover feature toggle
- [ ] Consolidar testes
- [ ] Renomear para nomes definitivos
```

---

## Regras de Qualidade da ADR

### Uma boa ADR:
- É compreensível por alguém que não participou da discussão
- Tem regras de negócio **testáveis** (não vagas)
- Tem escopo claro com **inclusões e exclusões** explícitas
- Tem casos de teste esperados que guiam o TDD
- É curta o suficiente para ser lida em 5 minutos

### Uma ADR ruim:
- "Implementar o endpoint de simulação" (sem regras, sem design)
- Regras vagas: "deve ser rápido" (quanto é rápido?)
- Sem escopo: não diz o que está fora
- Sem testes esperados: o dev não sabe quando terminou

---

## Formato de Resposta do Claude

```
### 📄 ADR-[NNN]: [Título]

[ADR completa no template apropriado]

> Revise a ADR acima. Quando aprovada, inicio a implementação via [TDD / Safe Refactoring].
> Algo que precisa ajustar no escopo, regras ou design?
```

**Claude DEVE esperar aprovação explícita antes de escrever código.**

---

## Numeração

### Com acesso ao sistema de arquivos
- Verificar `docs/adr/` e usar o próximo número disponível

### Sem acesso ao sistema de arquivos (chat, API)
- Perguntar ao usuário: "Qual o último número de ADR do projeto? (ou devo começar do 001?)"
- Se o usuário não souber, usar `ADR-XXX` como placeholder e instruir: "Substitua XXX pelo próximo número ao salvar"

### Regras
- Sequência incremental: ADR-001, ADR-002, ...
- Nunca reutilizar número — ADRs substituídas mantêm o número original com status "Substituída por ADR-XXX"
- Número é atribuído na criação, não na aprovação

## Armazenamento

Sugerir ao usuário salvar em:
```
docs/adr/
├── ADR-001-titulo-descritivo.md
├── ADR-002-titulo-descritivo.md
└── ...
```

---

## Checklist

- [ ] ADR criada ANTES de qualquer código
- [ ] Template correto para o tipo (feature, bug, refactoring)
- [ ] Contexto claro — problema e motivação
- [ ] Decisão específica — não genérica
- [ ] Escopo com inclusões E exclusões
- [ ] Regras de negócio testáveis
- [ ] Casos de teste esperados listados
- [ ] Design técnico com camadas e tipos
- [ ] Observabilidade planejada
- [ ] Aprovação do usuário ANTES de implementar