# Clay multi-provider setup

## Current providers

- Gemini: primary pool; five keys using Gemini's OpenAI-compatible endpoint and `gemini-3.1-flash-lite`.
- Groq: secondary provider; `openai/gpt-oss-120b`.
- OpenRouter: secondary provider; generic `custom` interface.
- SambaNova: dropped from the active provider pool after completion requests returned authentication failure.
- Mistral: dropped from the active provider pool; previous experiments are not part of the current runtime design.

There is no automatic failover or automatic key rotation.

## Current pool

```text
Gemini ×5
Groq
OpenRouter
```

## Credential locations

Credentials are outside the repository and outside the Clay workspace.

```text
/vol1/Docker/ai-cli-lab/secrets/
├── groq.env
├── gemini-keys
├── openrouter.env
└── state/
    └── gemini-key-last-used
```

Compatibility paths under `~/.config/clay` may point to these files.

Never print or commit secret values.

## OpenRouter

OpenRouter uses the existing generic custom-provider path:

```text
CLAY_PROVIDER=custom
CLAY_API_KEY=<OpenRouter key>
CLAY_BASE_URL=https://openrouter.ai/api/v1
CUSTOM_MODEL=<selected OpenRouter model>
```

A real-NAS test proved:

```text
OpenRouter → Clay → AI Guard → Bubblewrap → Tapo workspace
```

with a successful one-shot response. The OpenRouter free-model daily limit was subsequently exhausted during the full audit attempt, so OpenRouter remains a fallback provider.

## Security boundary

AI Guard remains the outer enforcement boundary. Clay's internal sandbox remains the secondary isolation layer.

Do not broaden the filesystem allowlist, expose Docker sockets, put API keys in argv/workspace, make network access implicit, or weaken either sandbox merely to accommodate a provider.

## Provider cleanup

SambaNova and Mistral are no longer active providers. Their provider-specific runtime configuration should not be retained merely for historical experiments. Historical documentation may remain where it records useful test results.

Do not add another provider unless an existing provider becomes unusable for a concrete operational reason.
