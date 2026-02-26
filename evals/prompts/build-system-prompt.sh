#!/bin/bash
# Concatena CLAUDE.md + todas as skills em um unico system-prompt.txt
# Uso: bash prompts/build-system-prompt.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$EVALS_DIR")"
OUTPUT="$SCRIPT_DIR/system-prompt.txt"

CLAUDE_MD="$ROOT_DIR/CLAUDE.md"
SKILLS_DIR="$ROOT_DIR/skills"

if [ ! -f "$CLAUDE_MD" ]; then
  echo "ERRO: CLAUDE.md nao encontrado em $CLAUDE_MD"
  exit 1
fi

if [ ! -d "$SKILLS_DIR" ]; then
  echo "ERRO: Diretorio skills/ nao encontrado em $SKILLS_DIR"
  exit 1
fi

echo "# INSTRUCOES DO SISTEMA" > "$OUTPUT"
echo "" >> "$OUTPUT"
echo "Voce e um assistente de desenvolvimento de software que segue rigorosamente as instrucoes abaixo." >> "$OUTPUT"
echo "As skills sao ativadas com base na intencao do usuario, conforme definido no CLAUDE.md." >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "---" >> "$OUTPUT"
echo "" >> "$OUTPUT"

cat "$CLAUDE_MD" >> "$OUTPUT"

SKILL_COUNT=0
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_file="$skill_dir/SKILL.md"
  if [ -f "$skill_file" ]; then
    echo "" >> "$OUTPUT"
    echo "---" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    cat "$skill_file" >> "$OUTPUT"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  fi
done

echo ""
echo "System prompt gerado com sucesso:"
echo "  Arquivo: $OUTPUT"
echo "  CLAUDE.md: incluido"
echo "  Skills: $SKILL_COUNT encontradas"
echo "  Tamanho: $(wc -c < "$OUTPUT") bytes"
