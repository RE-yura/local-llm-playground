#!/usr/bin/env bash
# Verify all three playground models load and generate, one at a time.
# Starts a temporary llama-server per model, sends a prompt, prints the reply,
# then shuts it down. Exits non-zero if any model fails.
set -uo pipefail
cd "$(dirname "$0")"
source ./models.sh
PORT=8088
declare -A PROMPTS=(
  [lfm2-1.2b-jp]="日本語で、富士山について2文で説明してください。"
  [lfm2-8b-a1b]="Explain in 2 sentences what a Mixture-of-Experts model is."
  [gemma4-12b]="Write a haiku about local LLMs running on a laptop."
)

fail=0
for KEY in "${MODEL_KEYS[@]}"; do
  echo "============================================================"
  echo ">> $KEY — $(model_desc "$KEY")"
  echo "============================================================"
  log="/tmp/smoke_${KEY}.log"
  # shellcheck disable=SC2046  # intentional word-splitting of extra args
  llama-server -hf "$(model_repo "$KEY")" --jinja --port "$PORT" -c 4096 $(model_extra "$KEY") >"$log" 2>&1 &
  pid=$!
  ok=0
  for _ in $(seq 1 200); do
    curl -s "http://localhost:$PORT/health" 2>/dev/null | grep -q '"ok"' && { ok=1; break; }
    kill -0 "$pid" 2>/dev/null || { echo "!! server exited early — see $log"; break; }
    sleep 3
  done
  if [[ "$ok" == 1 ]]; then
    echo "PROMPT: ${PROMPTS[$KEY]}"
    echo "REPLY:"
    ./chat.sh "${PROMPTS[$KEY]}" "$PORT" || { echo "!! request failed"; fail=1; }
  else
    echo "!! $KEY did NOT become ready"; fail=1
  fi
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  echo
done

echo "============================================================"
[[ "$fail" == 0 ]] && echo "ALL MODELS OK ✅" || echo "SOME MODELS FAILED ❌"
exit "$fail"
