# Claude Code Skills

Colecao de 19 skills para o Claude Code que enforçam padroes de desenvolvimento: TDD, DDD, Arquitetura Hexagonal, Readable Code, Seguranca e mais.

## Instalacao Rapida

```bash
git clone <repo-url>
cd <repo>
bash install.sh
```

O script:
1. Copia 19 skills para `~/.claude/skills/`
2. Instala o hook de auto-loading em `~/.claude/hooks/`
3. Registra o hook em `~/.claude/hooks.json`
4. Guia a configuracao do `~/.claude/CLAUDE.md`

## Instalacao Manual

Se preferir instalar passo a passo, veja abaixo.

### 1. Copiar skills

```bash
cp -r skills/* ~/.claude/skills/
```

### 2. Copiar hook

```bash
mkdir -p ~/.claude/hooks
cp hooks/auto-skill-loader.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/auto-skill-loader.sh
```

### 3. Registrar hook

Crie ou edite `~/.claude/hooks.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/hooks/auto-skill-loader.sh\""
          }
        ]
      }
    ]
  }
}
```

### 4. Configurar CLAUDE.md

Copie o `CLAUDE.md` deste repo para `~/.claude/CLAUDE.md`, ou adicione a secao `## Auto-Skills` ao seu existente.

## Como Funciona

```
Usuario digita prompt
        |
        v
  Hook (auto-skill-loader)    <-- roda ANTES do Claude responder
  Regex match no prompt:
  "implement/criar" -> tdd-workflow
  "refatore"        -> safe-refactoring
  "bug/erro"        -> systematic-debugging
  "PR"              -> pr
  ... (15 patterns no total)
        |
   match? ---> SIM: injeta SKILL.md no contexto do Claude
        |
        +----> NAO: retorna {} (zero custo)
```

### 3 Camadas de Ativacao

| Camada | Como funciona | Confiabilidade |
|--------|--------------|----------------|
| **Hook** | Regex no prompt → injeta skill automaticamente | ~95% |
| **CLAUDE.md** | Tabela de fallback → Claude carrega via Read | ~80% |
| **P0 always-on** | readable-code, verification, defense-in-depth no CLAUDE.md | 100% |

## Skills (19)

### P0 — Sempre Ativas
| Skill | Descricao |
|-------|-----------|
| readable-code | Codigo explicito, sem magic numbers, sem syntax sugar |
| verification-before-completion | Evidencia antes de claims de conclusao |
| defense-in-depth | Validacao em multiplas camadas ao corrigir bugs |
| root-cause-tracing | Rastreamento backward de causa raiz |

### P1 — Alto Impacto
| Skill | Trigger |
|-------|---------|
| tdd-workflow | Implementar, criar, adicionar feature |
| safe-refactoring | Refatorar, extrair, melhorar, reorganizar |
| adr | Decisao arquitetural, architecture |
| task-generation | Decompor em tarefas, breakdown |
| pr | Criar PR, pull request |
| systematic-debugging | Bug, erro, falha, exception |
| security | Auth, validacao, OWASP, injection |
| receiving-code-review | Receber feedback de review |

### P2 — Contextuais
| Skill | Trigger |
|-------|---------|
| ddd-patterns | Domain, entity, aggregate, bounded context |
| hexagonal-architecture | Camada, port, adapter, clean arch |
| observability | Logging, metricas, tracing, monitor |
| brainstorming | Design, plan, architect, explorar ideias |
| testing-anti-patterns | Mock, test quality, anti-patterns |
| dispatching-parallel-agents | Agentes paralelos, concurrent |
| finishing-a-development-branch | Finalizar branch, wrap up |

## Personalizacao

- **Adicionar skills:** Crie `~/.claude/skills/<nome>/SKILL.md`
- **Adicionar triggers:** Edite `~/.claude/hooks/auto-skill-loader.sh`
- **Mudar prioridades:** Edite a secao Auto-Skills do `~/.claude/CLAUDE.md`
- **Variavel de ambiente:** `CLAUDE_SKILLS_DIR` para mudar o diretorio de skills
