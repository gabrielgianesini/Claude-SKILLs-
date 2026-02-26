#!/bin/bash
# Script para executar avaliacoes do sistema de skills
# Uso: bash scripts/run-evals.sh [--ui-only]
#
# Opcoes:
#   --ui-only    Apenas abre a UI com resultados anteriores (nao roda eval)
#   --help       Mostra ajuda

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(dirname "$SCRIPT_DIR")"

cd "$EVALS_DIR"

# --- Funcoes ---

show_help() {
  echo "Uso: bash scripts/run-evals.sh [opcao]"
  echo ""
  echo "Opcoes:"
  echo "  (sem opcao)   Gera system prompt, roda avaliacoes, e abre UI"
  echo "  --ui-only     Apenas abre a UI com resultados anteriores"
  echo "  --eval-only   Roda avaliacoes sem abrir UI"
  echo "  --help        Mostra esta ajuda"
  echo ""
  echo "Pre-requisitos:"
  echo "  - Docker instalado e rodando"
  echo "  - Arquivo .env com ANTHROPIC_API_KEY"
}

check_prereqs() {
  if ! command -v docker &> /dev/null; then
    echo "ERRO: Docker nao encontrado. Instale o Docker Desktop."
    exit 1
  fi

  if ! docker info &> /dev/null 2>&1; then
    echo "ERRO: Docker nao esta rodando. Inicie o Docker Desktop."
    exit 1
  fi

  if [ ! -f ".env" ]; then
    echo "ERRO: Arquivo .env nao encontrado."
    echo "Copie o template: cp .env.example .env"
    echo "E preencha ANTHROPIC_API_KEY com sua chave da Anthropic."
    exit 1
  fi

  if grep -q "sk-ant-xxxxxxx" .env 2>/dev/null; then
    echo "ERRO: ANTHROPIC_API_KEY ainda esta com valor de exemplo."
    echo "Edite o arquivo .env e coloque sua chave real."
    exit 1
  fi
}

build_system_prompt() {
  echo "==> Gerando system prompt..."
  bash prompts/build-system-prompt.sh
  echo ""
}

run_eval() {
  echo "==> Rodando avaliacoes com promptfoo..."
  echo "    Isso pode levar alguns minutos (depende do numero de testes)."
  echo ""
  docker compose run --rm promptfoo
  echo ""
  echo "==> Avaliacoes concluidas!"
}

open_ui() {
  echo "==> Abrindo UI em http://localhost:3000"
  docker compose --profile ui up -d promptfoo-ui
  echo ""
  echo "Acesse: http://localhost:3000"
  echo "Para parar: docker compose --profile ui down"
}

# --- Main ---

case "${1:-}" in
  --help)
    show_help
    ;;
  --ui-only)
    open_ui
    ;;
  --eval-only)
    check_prereqs
    build_system_prompt
    run_eval
    ;;
  "")
    check_prereqs
    build_system_prompt
    run_eval
    open_ui
    ;;
  *)
    echo "Opcao desconhecida: $1"
    show_help
    exit 1
    ;;
esac
