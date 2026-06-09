# local-llm-playground

ローカルLLM 3つを Mac（Apple Silicon）で動かすための置き場。
[llama.cpp](https://github.com/ggml-org/llama.cpp) で完全オフライン動作。

## セットアップ（初回のみ）

```bash
brew install llama.cpp
```

## 使い方

```bash
./scripts/serve.sh lfm2-1.2b-jp
```

起動したらブラウザで `http://localhost:8080` を開く（llama.cpp 標準のチャットUI）。
モデルキーは `lfm2-1.2b-jp` / `lfm2-8b-a1b` / `gemma4-12b`。引数なしで実行すると一覧が出る。

## モデル

| キー | モデル | サイズ |
|------|--------|--------|
| `lfm2-1.2b-jp` | [LFM2.5-1.2B-JP-202606](https://huggingface.co/LiquidAI/LFM2.5-1.2B-JP-202606)（日本語/英語） | ~1.2 GB |
| `lfm2-8b-a1b` | [LFM2.5-8B-A1B](https://huggingface.co/LiquidAI/LFM2.5-8B-A1B)（MoE・推論型） | ~5 GB |
| `gemma4-12b` | [Gemma 4 12B QAT](https://blog.google/innovation-and-ai/technology/developers-tools/quantization-aware-training-gemma-4/)（推論型） | ~7 GB |

重みは初回起動時に HuggingFace から自動DL（`~/.cache/huggingface/hub` にキャッシュ）。
