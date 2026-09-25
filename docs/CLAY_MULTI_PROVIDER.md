# Clay multi-provider setup

## Current providers

- Groq: primary; `GROQ_API_KEY`, model defaults to `openai/gpt-oss-120b`.
- Gemini: backup; uses Gemini's OpenAI-compatible endpoint and `gemini-3.1-flash-lite`.
- Provider #3: reserved; use the generic `custom` provider interface when selected later.

There is no automatic failover or automatic key rotation.

## Credential locations

Credentials are outside the repository and outside the Clay workspace:

```text
~/.config/clay/groq.env
~/.config/clay/gemini-keys
~/.config/clay/state/gemini-key-last-used
```

`gemini-keys` keeps the existing format:

```text
KEY1=<secret>
KEY2=<secret>
KEY3=<secret>
KEY4=<secret>
KEY5=<secret>
```

The Gemini key file must be mode 0600 (400/440 are also accepted).

Do not commit these files to GitHub.

## Migrating the existing Gemini keys

The old Gemini key file is currently:

```text
/vol1/Docker/gemini/secrets/api-keys
```

After the new Clay path has been created and verified, copy the existing file without printing its contents:

```sh
mkdir -p ~/.config/clay/state
install -m 600 /vol1/Docker/gemini/secrets/api-keys ~/.config/clay/gemini-keys
touch ~/.config/clay/state/gemini-key-last-used
chmod 600 ~/.config/clay/state/gemini-key-last-used
```

Verify only the key names:

```sh
awk -F= '/^KEY[0-9]+=/{print $1}' ~/.config/clay/gemini-keys
```

Expected names are `KEY1` through `KEY5`. Never print the values.

Do not delete `/vol1/Docker/gemini` until the guarded Gemini integration has passed.

## Guarded invocation

Groq remains compatible with the existing command:

```sh
cd /vol1/Docker/Ai-guard
./adapters/clay \
  --provider groq \
  --worker /vol1/Docker/ai-cli-lab/workers/clay/bin/clay-worker \
  --workspace /vol1/Docker/tapo-nas-lab \
  --network host \
  -- \
  --cwd /workspace \
  --prompt 'Reply exactly: GROQ_CLAY_GUARD_OK'
```

Gemini:

```sh
cd /vol1/Docker/Ai-guard
./adapters/clay \
  --provider gemini \
  --worker /vol1/Docker/ai-cli-lab/workers/clay/bin/clay-worker \
  --workspace /vol1/Docker/tapo-nas-lab \
  --network host \
  -- \
  --cwd /workspace \
  --prompt 'Reply exactly: GEMINI_CLAY_GUARD_OK'
```

Without `GEMINI_KEY_CHOICE`, the Gemini path displays the five-key status menu and asks for a key.

For deterministic testing, select a key without the menu:

```text
GEMINI_KEY_CHOICE=1
```

The selected key is recorded only by name and timestamp in `gemini-key-last-used`.

## Security boundary

For Gemini, Clay runs as:

```text
CLAY_PROVIDER=custom
CLAY_API_KEY=<selected Gemini key>
CLAY_BASE_URL=https://generativelanguage.googleapis.com/v1beta/openai/
CUSTOM_MODEL=gemini-3.1-flash-lite
```

Only `CLAY_API_KEY` is passed through AI Guard's secret-env mechanism. The key is not intentionally placed in argv or the workspace.

For Groq, the existing `GROQ_API_KEY` secret-env path remains unchanged.

## Provider #3

Provider #3 does not require another architecture. The generic custom interface is already reserved:

```text
CLAY_PROVIDER=custom
CLAY_API_KEY=<key>
CLAY_BASE_URL=<OpenAI-compatible endpoint>
CUSTOM_MODEL=<model>
```

No provider #3 is enabled until its service and model are chosen.

## Validation order

1. Verify the five Gemini key names only.
2. Run Guard regression tests.
3. Test Groq through the real Tapo workspace.
4. Test Gemini through the real Tapo workspace.
5. Verify Gemini key selection/status and state updates.
6. Re-test Groq.
7. Only after both paths pass, remove the old Gemini runtime after explicit approval.
