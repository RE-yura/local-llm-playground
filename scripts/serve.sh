#!/usr/bin/env bash
# Start an OpenAI-compatible llama.cpp server for one of the playground models.
#
#   ./scripts/serve.sh <model-key> [port]
#
# Then chat at http://localhost:<port> (web UI) or POST to /v1/chat/completions.
# Ctrl+C to stop. Model weights are auto-downloaded from HuggingFace on first run.
set -euo pipefail
cd "$(dirname "$0")"
source ./models.sh

KEY="${1:-}"; PORT="${2:-8080}"
if [[ -z "$KEY" ]] || ! model_repo "$KEY" >/dev/null 2>&1; then
  echo "Usage: $0 <model-key> [port]"
  echo "Available models:"
  for k in "${MODEL_KEYS[@]}"; do printf "  %-14s %s\n" "$k" "$(model_desc "$k")"; done
  exit 1
fi

REPO="$(model_repo "$KEY")"
echo ">> Serving '$KEY'  ($(model_desc "$KEY"))"
echo ">> Repo: $REPO   Port: $PORT   UI: http://localhost:$PORT"
# shellcheck disable=SC2046  # intentional word-splitting of extra args
exec llama-server -hf "$REPO" --jinja --port "$PORT" -c 8192 $(model_extra "$KEY")
