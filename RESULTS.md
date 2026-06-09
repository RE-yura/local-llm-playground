# Verification results

Verified 2026-06-09 on **Apple M5 Max / 64 GB / macOS 26.5.1**, llama.cpp build **b9330**,
via `./scripts/smoke-test.sh` (each model served through `llama-server`, OpenAI API). All three
load and generate correctly. ✅

| model | quant | gen speed | status |
|-------|-------|-----------|--------|
| LFM2.5-1.2B-JP-202606 | Q8_0 (~1.2 GB) | **~290 tok/s** | ✅ fluent JA/EN |
| LFM2.5-8B-A1B (MoE, reasoning) | Q4_K_M (~5 GB) | **~241 tok/s** | ✅ |
| Gemma 4 12B QAT (reasoning) | UD-Q4_K_XL (~7 GB) | **~55 tok/s** | ✅ |

## Sample outputs

**LFM2.5-1.2B-JP** — `日本語で、富士山について2文で説明してください。`
> 富士山は山梨県と静岡県の境に位置する成層火山で、標高3,776メートルから日本を象徴する景観として知られています。古くから信仰の対象とされ、世界文化遺産にも登録され、四季折々の自然美と登山の魅力で多くの人々を惹きつけています。

**LFM2.5-8B-A1B** — `Explain in 2 sentences what a Mixture-of-Experts model is.`
> A Mixture-of-Experts (MoE) model is a neural network architecture that combines multiple
> specialized subnetworks, called experts, whose outputs are aggregated via a gating mechanism.
> The gating network decides which experts to activate for each input, allowing the model to
> dynamically allocate computational resources and improve efficiency and performance.

**Gemma 4 12B QAT** — `Say hello and tell me the capital of Japan in one sentence.`
> Hello, the capital of Japan is Tokyo.

## Notes for whoever runs this next

- **Both LFM2.5-8B-A1B and Gemma 4 are reasoning models** — they emit chain-of-thought in the
  `reasoning_content` field separate from the final `content`. Give them a generous `max_tokens`
  (≥1024); a small budget gets fully consumed by reasoning and leaves `content` empty.
  `chat.sh` prints both fields and uses `max_tokens=1536`.
- **Gemma 4 is served text-only** (`--no-mmproj`). The unsloth GGUF bundles a vision projector
  whose type (`gemma4uv`) llama.cpp b9330 can't load yet; without `--no-mmproj` the server
  treats that as fatal and exits. Text generation is unaffected. Revisit once llama.cpp adds
  `gemma4uv` support if you want image input.
- **Ollama was not used.** Homebrew's ollama 0.24.0 refuses to pull the `gemma4` registry tag
  ("please download the latest version"). llama.cpp covers all three uniformly.
