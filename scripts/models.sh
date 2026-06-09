#!/usr/bin/env bash
# Central registry of the local models in this playground.
# Each entry: KEY -> "HF_REPO:QUANT|description|extra llama-server args"
# Used by serve.sh / smoke-test.sh. llama.cpp auto-downloads from HF on first use
# (cached under ~/.cache/huggingface/hub), so no manual download step is needed.

# Ordered keys
MODEL_KEYS=(lfm2-1.2b-jp lfm2-8b-a1b gemma4-12b)

model_spec() {
  case "$1" in
    lfm2-1.2b-jp) echo "LiquidAI/LFM2.5-1.2B-JP-202606-GGUF:Q8_0|LFM2.5 1.2B Japanese/English (LIV-conv hybrid)|" ;;
    lfm2-8b-a1b)  echo "LiquidAI/LFM2.5-8B-A1B-GGUF:Q4_K_M|LFM2.5 8B MoE, 1.5B active params (reasoning)|" ;;
    # --no-mmproj: skip the bundled vision projector; llama.cpp b9330 can't load
    # gemma4's 'gemma4uv' projector type, and it's not needed for text generation.
    gemma4-12b)   echo "unsloth/gemma-4-12B-it-qat-GGUF:UD-Q4_K_XL|Gemma 4 12B QAT int4, reasoning (ungated mirror)|--no-mmproj" ;;
    *) return 1 ;;
  esac
}

model_repo()  { model_spec "$1" | cut -d'|' -f1; }
model_desc()  { model_spec "$1" | cut -d'|' -f2; }
model_extra() { model_spec "$1" | cut -d'|' -f3; }
