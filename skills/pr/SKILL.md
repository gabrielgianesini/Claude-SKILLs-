---
name: pr
description: Criação padronizada de branches e Pull Requests. Garante nomes de branch, títulos e descrições no padrão do time. Usa gh CLI para operações no GitHub.
metadata:
  version: 2.0.0
  priority: P1
  activation: Quando o usuário pedir para criar PR, abrir pull request, ou preparar branch para merge. Exemplos - "cria a PR", "abre PR", "prepara o merge", "/pr".
  conflicts: Nenhum. Pode ser usada após qualquer outra skill.
---

# PR — Pull Request Padronizado

## Princípio

> Todo Pull Request segue o padrão do time: branch nomeada com card Jira, título com card Jira, descrição completa em português.
> O Claude usa `gh` CLI para criar branches e PRs no GitHub.

---

## Ferramenta

- **Primária:** `gh` CLI (GitHub CLI)
- **Fallback:** Se `gh` não estiver disponível, instruir o usuário a instalar (`gh auth login`)

---

## Padrão de Branch

### Regra Principal

PRs para a branch `master` devem ser do tipo **RELEASE** ou **HOTFIX**, nomeadas com o card Jira.

### Formato

```
RELEASE/CARD-JIRA
HOTFIX/CARD-JIRA
```

### Quando Usar Cada Tipo

| Tipo | Quando |
|------|--------|
| `RELEASE` | Features novas, refatorações, melhorias, conjunto de mudanças planejadas |
| `HOTFIX` | Correções urgentes em produção, bugs críticos |

### Exemplos

```
RELEASE/N3-4500   # feature nova
RELEASE/FIN-111   # melhoria
HOTFIX/N3-3191    # bug fix urgente
HOTFIX/PAY-1976   # correção crítica
```

### Como Determinar o Tipo

- Se o card Jira é um **bug** ou **correção** → `HOTFIX`
- Se o card Jira é uma **feature**, **melhoria** ou **refatoração** → `RELEASE`
- **Na dúvida**, perguntar ao usuário

---

## Padrão de Título do PR

### Formato

```
[CARD-JIRA] Descrição completa do que a PR faz
```

### Regras

- **Card Jira** entre colchetes no início (ex: `[PAY-1976]`, `[FIN-111]`)
- **Descrição** clara e completa do que a PR faz
- **Máximo 2 linhas** (idealmente 1 linha)
- **Idioma:** Português
- Se o usuário não informar o card Jira, **perguntar**

### Exemplos

```
[FIN-111] Implementação do módulo de simulação de crédito
[PAY-1976] Correção do cálculo de IOF para períodos de 30 dias
[N3-3191] Correção da descrição IOF na conciliação de cartão
```

---

## Padrão de Descrição do PR

### Template Obrigatório

```markdown
## Tipo da Alteração

- [ ] Refatoração
- [ ] Nova Funcionalidade
- [ ] Correção de Bug
- [ ] Documentação
- [ ] Configuração/Tarefa
- [ ] Outro:

## Descrição


### Contexto


## Changelog

-

## Como Testar

-

## Tarefas Relacionadas

- []()

## Notas para o Revisor

-

## Anexos

## Guias
- Guia para escrita de Pull Requests (documentacao interna do time)
- Guia para escrita de comentarios no Pull Request (documentacao interna do time)
- Guia para revisao de codigo (documentacao interna do time)
```

### Regras de Preenchimento

| Seção | Como Preencher |
|-------|----------------|
| **Tipo da Alteração** | Marcar com `[x]` o(s) tipo(s) que se aplicam |
| **Descrição** | Resumo do que foi feito (2-5 frases) |
| **Contexto** | Por que essa mudança é necessária? Qual problema resolve? |
| **Changelog** | Lista de mudanças concretas (bullet points) |
| **Como Testar** | Passos para o revisor validar as mudanças |
| **Tarefas Relacionadas** | Links para cards Jira, ADRs, ou issues |
| **Notas para o Revisor** | Pontos de atenção, decisões que merecem discussão |
| **Anexos** | Screenshots, diagramas, links relevantes |
| **Guias** | Manter sempre os 3 links padrão (não remover) |

---

## Fluxo de Criação

### Passo 1 — Coletar Informações

Se não fornecido no contexto da conversa, perguntar ao usuário:

1. **Card Jira** — ex: `N3-3191`, `PAY-1976`
2. **Tipo** — RELEASE ou HOTFIX? (inferir do card se possível: bug → HOTFIX, feature → RELEASE)

**NÃO perguntar se já tiver informação suficiente.** Se o usuário já trabalhou num card Jira durante a conversa, usar esse card. Se o contexto indica bug fix, usar HOTFIX automaticamente.

### Passo 1.5 — Verificar Commits

Antes de criar a PR, verificar que os commits seguem o padrão do CLAUDE.md:

```
Formato: [tipo]: [descrição curta]  (max 72 caracteres na primeira linha)
Corpo:   Refs: ADR-NNN, Tarefa N/Total

Tipos válidos: feat, fix, refactor, test, docs, chore
```

**Ações:**
- Se commits estão fora do padrão, informar o usuário antes de prosseguir
- Se há muitos commits "WIP" ou sem padrão, sugerir squash ou rebase interativo ao usuário
- Não alterar commits sem permissão explícita do usuário

### Passo 2 — Criar/Renomear Branch

```bash
# Se já está numa branch de trabalho, renomear
git branch -m HOTFIX/N3-3191

# Ou criar nova branch
git checkout -b HOTFIX/N3-3191
```

**IMPORTANTE:** Antes de renomear, verificar se a branch atual tem commits não pushados e informar o usuário.

### Passo 3 — Push da Branch

```bash
git push -u origin HOTFIX/N3-3191
```

### Passo 4 — Criar PR

```bash
gh pr create \
  --base master \
  --title "[N3-3191] Descrição da PR em português" \
  --body "$(cat <<'EOF'
[descrição preenchida com template completo]
EOF
)"
```

### Passo 5 — Confirmar

Retornar ao usuário no formato de resposta padrão (ver abaixo).

---

## Resposta a Bots (Greptile, etc.)

Se um bot como `greptile-apps` comentar na PR solicitando informações ou fazendo perguntas:

- **Responder em português**
- Manter o tom profissional e direto
- Usar `gh pr comment` ou `gh api` para responder

---

## Formato de Resposta do Claude

```
### 🔀 Pull Request

**Branch:** `HOTFIX/N3-3191`
**Base:** `master`
**Título:** [N3-3191] Descrição da PR

**PR criada:** [link]

> PR criada com sucesso. Revise a descrição e ajuste se necessário.
```

---

## Checklist

- [ ] Branch segue padrão `RELEASE/CARD-JIRA` ou `HOTFIX/CARD-JIRA`
- [ ] Título contém card Jira entre colchetes
- [ ] Título em português e com no máximo 2 linhas
- [ ] Descrição usa template completo
- [ ] Tipo da alteração marcado corretamente
- [ ] Seção "Como Testar" preenchida
- [ ] Tarefas relacionadas linkadas
- [ ] Guias mantidos no final da descrição
- [ ] PR criada via `gh pr create`
- [ ] URL da PR retornada ao usuário
