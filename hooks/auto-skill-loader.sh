#!/usr/bin/env bash
# auto-skill-loader.sh — Hook de keyword-matching para skills do Claude Code
# Le o prompt do usuario via $CLAUDE_USER_PROMPT, faz regex match contra tabela de keywords,
# injeta SKILL.md correspondentes no additionalContext.
# Se nenhum match, retorna JSON vazio (zero custo).
#
# Uso: Copiar para ~/.claude/hooks/ e registrar em ~/.claude/hooks.json
# O SKILLS_DIR deve apontar para onde estao os skills (padrao: ~/.claude/skills)

set -euo pipefail

PROMPT="${CLAUDE_USER_PROMPT:-}"

# Sair rapido se nao tem prompt
if [[ -z "$PROMPT" ]]; then
  echo '{}'
  exit 0
fi

# Diretorio de skills — ajuste se necessario
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
MATCHED_SKILLS=()

# Lowercase para match case-insensitive
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Tabela de patterns → skills
# Skills P0 (readable-code, verification-before-completion, defense-in-depth, root-cause-tracing)
# NAO tem trigger — sao ativadas via CLAUDE.md (sempre no contexto) ou como sub-skills.

match_skill() {
  local pattern="$1"
  local skill="$2"
  if echo "$PROMPT_LOWER" | grep -qiE "$pattern"; then
    MATCHED_SKILLS+=("$skill")
  fi
}

match_skill 'implement|criar|adicionar|feature|build|develop|code' 'tdd-workflow'
match_skill 'refactor|refator|extrair|melhorar|reorganizar|tech.debt|limpar' 'safe-refactoring'
match_skill 'adr|design.decision|arquitetura|architecture' 'adr'
match_skill 'task|decomp|quebrar|breakdown|planejar.implement' 'task-generation'
match_skill 'pr$|pr |pull.request|merge|branch' 'pr'
match_skill 'debug|bug|erro|error|falha|failure|traceback|exception' 'systematic-debugging'
match_skill 'security|auth|validat|owasp|injection|xss|encrypt' 'security'
match_skill 'hexagonal|camada|layer|port|adapter|clean.arch' 'hexagonal-architecture'
match_skill 'ddd|domain|entity|value.object|aggregate|bounded.context' 'ddd-patterns'
match_skill 'observ|logging|logar|metric|tracing|monitor|health.check' 'observability'
match_skill 'review|code.review|feedback|revisar' 'receiving-code-review'
match_skill 'brainstorm|design|plan|architect|explore.idea' 'brainstorming'
match_skill 'test.anti|mock|test.quality' 'testing-anti-patterns'
match_skill 'parallel|concurrent|dispatch|multiple.agent' 'dispatching-parallel-agents'
match_skill 'finish|complete|merge.branch|close.branch|wrap.up' 'finishing-a-development-branch'

# Sem matches — zero custo
if [[ ${#MATCHED_SKILLS[@]} -eq 0 ]]; then
  echo '{}'
  exit 0
fi

# Deduplicar
UNIQUE_SKILLS=($(printf '%s\n' "${MATCHED_SKILLS[@]}" | sort -u))

# Montar additionalContext lendo cada skill matched
CONTEXT=""
for skill in "${UNIQUE_SKILLS[@]}"; do
  SKILL_FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$SKILL_FILE" ]]; then
    CONTENT=$(cat "$SKILL_FILE")
    CONTEXT="${CONTEXT}\n\n---\n## Skill carregada automaticamente: ${skill}\n\n${CONTENT}"
  fi
done

# Escapar para JSON
if [[ -n "$CONTEXT" ]]; then
  if command -v python3 &>/dev/null; then
    ESCAPED=$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$CONTEXT")
  elif command -v python &>/dev/null; then
    ESCAPED=$(python -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$CONTEXT")
  elif command -v jq &>/dev/null; then
    ESCAPED=$(echo "$CONTEXT" | jq -Rs .)
  else
    ESCAPED=$(echo "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')
    ESCAPED="\"${ESCAPED}\""
  fi
  echo "{\"additionalContext\": ${ESCAPED}}"
else
  echo '{}'
fi
