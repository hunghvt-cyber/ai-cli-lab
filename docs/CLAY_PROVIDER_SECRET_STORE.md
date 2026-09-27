# Clay Provider Secret Store

## Canonical location

All active Clay provider credentials are kept outside GitHub and outside the Tapo workspace:

```
/vol1/Docker/ai-cli-lab/secrets/
├── groq.env
├── gemini-keys
├── openrouter.env
└── state/
    └── gemini-key-last-used
```

This directory is the single intended secret store for the active Clay provider pool:

- Gemini ×5
- Groq
- OpenRouter

## OpenRouter

OpenRouter is an active fallback provider for the Clay worker.

- Provider path: Clay `custom`
- API base: `https://openrouter.ai/api/v1`
- Model selection: stored outside GitHub in `openrouter.env`
- Real-NAS proof: `OpenRouter → Clay → AI Guard → Bubblewrap → Tapo workspace` passed with marker `OPENROUTER_CLAY_OK`.

A provider HTTP 429 is a provider quota/rate-limit failure and must not be recorded as a Tapo audit result.

## Secret handling

- Never commit secret values.
- Never print secret values.
- Never put API keys in argv.
- Never place provider secrets inside the Tapo workspace.
- AI Guard must inject provider credentials through its secret mechanism.
- The old `/vol1/Docker/gemini` infrastructure is separate legacy infrastructure and must not be deleted without explicit approval.

## Adapter alignment

The canonical paths above are the intended source of truth for provider secrets. If the AI Guard adapter still defaults to legacy per-user paths, that adapter alignment is a separate implementation task; do not assume the GitHub documentation alone changes the live NAS.

## Current operational limitation

The current provider integrations use explicit `--network host`. Do not make network access implicit or broaden filesystem exposure to compensate for provider limitations.
