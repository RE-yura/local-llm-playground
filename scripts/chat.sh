#!/usr/bin/env bash
# Send a chat message to a running llama-server (started via serve.sh).
#
#   ./scripts/chat.sh "prompt" [port]            # streaming (default) + timing stats
#   STREAM=0 ./scripts/chat.sh "prompt" [port]   # wait for the full reply instead
#
# Timing (elapsed / time-to-first-token / tok/s) is printed to stderr, so piping
# stdout still gives you just the model's text.
set -euo pipefail
PROMPT="${1:-日本語で自己紹介してください。}"
PORT="${2:-8080}"
STREAM="${STREAM:-1}"

PROMPT="$PROMPT" PORT="$PORT" STREAM="$STREAM" python3 - <<'PY'
import json, os, sys, time, urllib.request

prompt = os.environ["PROMPT"]
port   = os.environ["PORT"]
stream = os.environ.get("STREAM", "1") != "0"

body = {
    "messages": [{"role": "user", "content": prompt}],
    "temperature": 0.3,
    "max_tokens": 1536,
    "stream": stream,
}
if stream:
    # ask the server for a final chunk carrying token usage
    body["stream_options"] = {"include_usage": True}

req = urllib.request.Request(
    f"http://localhost:{port}/v1/chat/completions",
    data=json.dumps(body).encode(),
    headers={"Content-Type": "application/json"},
)

t0 = time.monotonic()
t_first = None
timings = None
usage = None

if stream:
    in_reasoning = False
    with urllib.request.urlopen(req) as r:
        for raw in r:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                break
            chunk = json.loads(data)
            timings = chunk.get("timings", timings)
            usage = chunk.get("usage", usage)
            choices = chunk.get("choices") or [{}]
            delta = choices[0].get("delta", {}) if choices else {}
            rc, cc = delta.get("reasoning_content"), delta.get("content")
            if rc:
                if t_first is None: t_first = time.monotonic()
                if not in_reasoning:
                    sys.stdout.write("[reasoning] "); in_reasoning = True
                sys.stdout.write(rc); sys.stdout.flush()
            if cc:
                if t_first is None: t_first = time.monotonic()
                if in_reasoning:
                    sys.stdout.write("\n\n"); in_reasoning = False
                sys.stdout.write(cc); sys.stdout.flush()
    sys.stdout.write("\n")
else:
    with urllib.request.urlopen(req) as r:
        resp = json.load(r)
    t_first = time.monotonic()
    m = resp["choices"][0]["message"]
    if (m.get("reasoning_content") or "").strip():
        print("[reasoning]", m["reasoning_content"].strip(), "\n")
    print((m.get("content") or "").strip())
    timings = resp.get("timings")
    usage = resp.get("usage")

t_end = time.monotonic()
parts = [f"elapsed {t_end - t0:.2f}s"]
if t_first is not None:
    parts.append(f"TTFT {t_first - t0:.2f}s")

n_tok = (timings or {}).get("predicted_n") or (usage or {}).get("completion_tokens")
if timings and timings.get("predicted_per_second"):
    parts.append(f"{timings['predicted_per_second']:.1f} tok/s")
elif n_tok and t_first is not None and t_end > t_first:
    parts.append(f"{n_tok / (t_end - t_first):.1f} tok/s")
if n_tok:
    parts.append(f"{n_tok} tokens")

print("--- " + " | ".join(parts), file=sys.stderr)
PY
