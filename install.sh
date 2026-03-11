#!/usr/bin/env bash
# install.sh — Instala skills, hooks e CLAUDE.md para o Claude Code
# Uso: git clone <repo> && cd <repo> && bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_SRC="$SCRIPT_DIR/skills"
HOOKS_SRC="$SCRIPT_DIR/hooks"
CLAUDE_MD_SRC="$SCRIPT_DIR/CLAUDE.md"

echo "=== Instalador de Skills para Claude Code ==="
echo ""

# -----------------------------------------------
# 1. Verificar que o repo foi clonado corretamente
# -----------------------------------------------
if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "ERRO: Diretorio skills/ nao encontrado em $SCRIPT_DIR"
  echo "Execute este script de dentro do repositorio clonado."
  exit 1
fi

SKILL_COUNT=$(ls -d "$SKILLS_SRC"/*/ 2>/dev/null | wc -l)
echo "[1/5] Encontradas $SKILL_COUNT skills em $SKILLS_SRC"

# -----------------------------------------------
# 2. Criar diretorios
# -----------------------------------------------
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/hooks"
echo "[2/5] Diretorios criados: ~/.claude/skills/ e ~/.claude/hooks/"

# -----------------------------------------------
# 3. Copiar skills (preserva existentes, sobrescreve com as novas)
# -----------------------------------------------
INSTALLED=0
for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p "$CLAUDE_DIR/skills/$skill_name"
  cp "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$skill_name/SKILL.md"
  INSTALLED=$((INSTALLED + 1))
done
echo "[3/5] $INSTALLED skills copiadas para ~/.claude/skills/"

# -----------------------------------------------
# 4. Copiar hook e tornar executavel
# -----------------------------------------------
cp "$HOOKS_SRC/auto-skill-loader.sh" "$CLAUDE_DIR/hooks/auto-skill-loader.sh"
chmod +x "$CLAUDE_DIR/hooks/auto-skill-loader.sh"
echo "[4/5] Hook copiado para ~/.claude/hooks/auto-skill-loader.sh"

# -----------------------------------------------
# 5. Configurar hooks.json (merge se ja existir)
# -----------------------------------------------
HOOKS_JSON="$CLAUDE_DIR/hooks.json"
HOOK_CMD='bash "$HOME/.claude/hooks/auto-skill-loader.sh"'

if [[ -f "$HOOKS_JSON" ]]; then
  # Verificar se o hook ja esta registrado
  if grep -q "auto-skill-loader" "$HOOKS_JSON" 2>/dev/null; then
    echo "[5/5] hooks.json ja contem auto-skill-loader — pulando"
  else
    echo ""
    echo "ATENCAO: ~/.claude/hooks.json ja existe."
    echo "Adicione manualmente o seguinte ao seu hooks.json:"
    echo ""
    echo '  "UserPromptSubmit": ['
    echo '    {'
    echo '      "hooks": ['
    echo '        {'
    echo '          "type": "command",'
    echo '          "command": "bash \"$HOME/.claude/hooks/auto-skill-loader.sh\""'
    echo '        }'
    echo '      ]'
    echo '    }'
    echo '  ]'
    echo ""
    echo "[5/5] hooks.json NAO modificado (ja existia)"
  fi
else
  cp "$SCRIPT_DIR/hooks.json" "$HOOKS_JSON"
  echo "[5/5] hooks.json criado em ~/.claude/hooks.json"
fi

# -----------------------------------------------
# 6. CLAUDE.md — informar o usuario
# -----------------------------------------------
echo ""
echo "=== Instalacao concluida ==="
echo ""
echo "Skills instaladas:"
ls "$CLAUDE_DIR/skills/" | sed 's/^/  - /'
echo ""

CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
if [[ -f "$CLAUDE_MD" ]]; then
  if grep -q "Auto-Skills" "$CLAUDE_MD" 2>/dev/null; then
    echo "~/.claude/CLAUDE.md ja contem secao Auto-Skills — nenhuma acao necessaria."
  else
    echo "PROXIMO PASSO: Adicione a secao Auto-Skills ao seu ~/.claude/CLAUDE.md"
    echo "Copie o conteudo da secao '## Auto-Skills' do arquivo:"
    echo "  $CLAUDE_MD_SRC"
    echo ""
    echo "Ou para usar o CLAUDE.md completo deste repo:"
    echo "  cp $CLAUDE_MD_SRC $CLAUDE_MD"
  fi
else
  echo "Voce nao tem ~/.claude/CLAUDE.md ainda."
  read -rp "Deseja copiar o CLAUDE.md deste repo? [S/n] " RESP
  RESP="${RESP:-S}"
  if [[ "$RESP" =~ ^[Ss]$ ]]; then
    cp "$CLAUDE_MD_SRC" "$CLAUDE_MD"
    echo "CLAUDE.md copiado para ~/.claude/CLAUDE.md"
  else
    echo "Pulado. Copie manualmente quando quiser:"
    echo "  cp $CLAUDE_MD_SRC $CLAUDE_MD"
  fi
fi

echo ""
echo "Pronto! Abra o Claude Code em qualquer projeto e as skills serao carregadas automaticamente."
