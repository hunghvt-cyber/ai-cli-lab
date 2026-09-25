# Clay + AI Guard Integration Checkpoint

## Status

**PASS — end-to-end integration verified on the NAS.**

Date: 2026-09-25

This document is the durable handoff record for the current Clay Reduction / AI Worker state. Read this before changing the Clay worker or its AI Guard integration.

## Repositories

- Worker/lab: `hunghvt-cyber/ai-cli-lab`
- Security boundary: `hunghvt-cyber/Ai-guard`
- NAS worker path: `/vol1/Docker/ai-cli-lab/workers/clay/bin/clay-worker`
- NAS guard path: `/vol1/Docker/Ai-guard`

## Architecture

The intended runtime is:

```
ChatGPT
  ↓
Clay headless worker
  ↓
AI Guard adapter
  ↓
Bubblewrap
  ↓
staged clay-worker
  ↓
Clay internal sandbox
  ↓
shell / file tools
  ↓
Gemini ×5 / Groq / OpenRouter
```

AI Guard is the outer enforcement boundary. Clay's own sandbox remains a secondary inner isolation layer.

ChatGPT is the architect/decision layer. The worker is an execution layer.

## Verified Clay state

Clay was reduced from the upstream `sammwyy/clay` source while preserving the stable core needed for a headless worker.

Successful reductions include:

- MCP removal
- Skills removal
- Subagent removal
- Tasks/TodoWrite/repo_map removal
- Demo/mm build removal
- interactive help/exit/logout removal
- ClayApp/TUI separation
- stable headless `clay-worker` target

The failed TUI task-renderer deletion was restored and must not be treated as a successful reduction.

The current worker target is:

```
workers/clay/bin/clay-worker
```

It is a dynamically linked ARM64/aarch64 executable and requires the host's normal runtime libraries.

## Provider state

### Gemini

- Five-key pool.
- Provider path: Clay `custom`.
- Model: `gemini-3.1-flash-lite`.
- API base: `https://generativelanguage.googleapis.com/v1beta/openai`.
- Five Gemini keys are stored outside GitHub/workspace.
- No automatic rotation, cooldown, or failover is used.
- Real-NAS guarded Tapo test passed.

### Groq

- Provider: `groq`.
- Model: `openai/gpt-oss-120b`.
- API base: `https://api.groq.com/openai/v1`.
- Real-NAS guarded Tapo test passed.
- Full long audit attempt hit the provider's 8K TPM limit.

### OpenRouter

- Provider path: Clay `custom`.
- API base: `https://openrouter.ai/api/v1`.
- Current configured model is stored outside GitHub in `openrouter.env`.
- Real-NAS one-shot integration passed:
  `OpenRouter → Clay → AI Guard → Bubblewrap → Tapo workspace`.
- Full Tapo audit attempt was blocked by OpenRouter's free-model daily limit (HTTP 429).
- Retain OpenRouter as a fallback provider; do not treat the failed full audit as a Tapo audit result.

### Dropped providers

- SambaNova: dropped after completion requests returned authentication failure.
- Mistral: dropped after previous experiments; not part of the current runtime pool.

Current active provider pool:

```
Gemini ×5
Groq
OpenRouter
```

Do not add another provider unless an existing provider becomes unusable for a concrete operational reason.

## Clay worker functional facts

Standalone worker tests previously passed:

- one-shot inference
- workspace-contained `read_file`
- workspace escape protection
- shell tool execution
- resource limits
- process kill/recovery

Clay sandbox resource limits observed:

- CPU: 60 seconds
- virtual memory: 1 GiB
- file size: 512 MiB
- processes: 64
- open files: 1024
- core dump: disabled

Host prerequisite discovered and installed:

```
uidmap
```

This provides:

```
/usr/bin/newuidmap
/usr/bin/newgidmap
```

The Clay internal sandbox requires these on this NAS and works after installation.

## AI Guard integration

The adapter is:

```
adapters/clay
```

It stages the worker through AI Guard, injects the selected provider credential through the Guard secret-FD mechanism, injects required non-secret provider/model variables, defaults network policy to `none`, and requires explicit `--network host` for the current provider integrations.

The outer Guard uses `--clearenv` before adding explicitly allowed environment variables.

API keys are not intentionally placed in the worker command line or workspace.

## Real-NAS integration validation — PASS

The real Tapo workspace passed the Guard isolation test:

- `/workspace` is writable and usable.
- `/vol1` is not visible.
- host `/home/admin/.ssh` is not visible.
- host `/root/.ssh` is not visible.
- only the intended Tapo repository path is allowlisted.

Guard regression suite passed.

### Groq → Tapo

Observed:

```
GROQ_TAPO_FINAL_OK
```

### Gemini → Tapo

Observed:

```
GEMINI_TAPO_FINAL_OK
```

### OpenRouter → Tapo

Observed:

```
OPENROUTER_CLAY_OK
```

These prove the three active provider paths can execute the Clay worker through AI Guard against the real Tapo workspace.

## Central secret store

Current intended provider secret store:

```
/vol1/Docker/ai-cli-lab/secrets/
├── groq.env
├── gemini-keys
├── openrouter.env
└── state/
    └── gemini-key-last-used
```

Secret values must never be committed, printed, or exposed in audit output.

The old `/vol1/Docker/gemini` infrastructure remains separate and must not be deleted without explicit approval.

## Important boundaries

Do not weaken either sandbox, broaden filesystem exposure, expose Docker sockets, put API keys into argv/workspace, or make network access implicit.

If a future integration test fails, preserve exact failure output and diagnose the specific layer.

## Current network limitation

The working provider proofs use:

```
--network host
```

AI Guard does not yet have an egress-only policy for allowing only the required provider endpoint.

Do not silently change the default from `none` to broad networking.

## Source-of-truth workflow

```
GitHub source of truth
  ↓
NAS git pull --ff-only
  ↓
build/test
  ↓
PASS → keep/commit
FAIL → rollback
```

## Next operational task: Tapo backup/retention audit

The next task remains a **read-only audit of the actual Tapo backup and retention system**.

Audit scope:

- actual backup/upload/archive/manifest/reconciliation/retention files;
- actual NAS paths;
- cron/systemd timers/services;
- recent logs and execution evidence;
- rclone configuration and commands without exposing secrets;
- remote path mapping;
- already-uploaded detection;
- retry/error behavior;
- remote existence plus exact-size verification;
- active recorder-file protection;
- existing cleanup/deletion scripts;
- recording filename/date structure;
- current backup source of truth;
- D-7 retention implementation and gaps.

Target policy:

```
Rolling D-7

newer than 7 days → KEEP
age >= 7 days → eligible only after remote backup verification
active file being written → NEVER delete
```

Historical September cleanup rules are not production retention logic.

### Audit security issue to fix before the next run

A previous OpenRouter audit attempt caused the worker to read `/workspace/.secrets/tapo.env` and expose Tapo credential values in the live log.

This means the current audit prompt/worker boundary has **not yet demonstrated sufficient secret exclusion**.

Before the next full audit:

1. explicitly forbid reading `.secrets/`, `.env`, credential files, and provider secret paths;
2. add runner detection for Tapo credential patterns, including `TAPO_USER` and `TAPO_PASSWORD`;
3. ensure a detected secret causes a fail-closed stop with no GitHub report;
4. preserve the existing read-only rule.

Do not weaken the Guard filesystem boundary merely to obtain host-only facts. If a required host fact is not observable from the sandbox, the audit must report `NOT OBSERVABLE` rather than bypassing the boundary.

## Do not confuse these projects

- `ai-cli-lab`: AI CLI/worker experiments and execution workflows.
- `Ai-guard`: security enforcement and sandbox boundary.
- `tapo-nas-lab`: Tapo/NAS application.

The Clay worker belongs to `ai-cli-lab`; the security boundary belongs to `Ai-guard`.
