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
Groq / Gemini
```

AI Guard is the **outer enforcement boundary**. Clay's own sandbox remains a **secondary inner isolation layer**.

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

The failed TUI task-renderer deletion was restored and must **not** be treated as a successful reduction.

The current worker target is:

```
workers/clay/bin/clay-worker
```

It is a dynamically linked ARM64/aarch64 executable and requires the host's normal runtime libraries.

## Clay worker functional facts

### Groq

- Provider: `groq`
- Model: `openai/gpt-oss-120b`
- API base: `https://api.groq.com/openai/v1`

### Gemini

- Provider path: Clay `custom` provider
- Model: `gemini-3.1-flash-lite`
- API base: `https://generativelanguage.googleapis.com/v1beta/openai`
- Five Gemini keys are stored outside GitHub/workspace and selected manually.
- No automatic rotation, cooldown, or failover is used.

Standalone and guarded tests confirmed that Gemini 3.1 Flash-Lite is reachable through the OpenAI-compatible endpoint.

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

It:

1. receives a Clay worker path;
2. stages the worker through AI Guard as a read-only program;
3. receives the selected provider credential outside the workspace;
4. writes the secret temporarily with restrictive permissions;
5. injects the secret into Bubblewrap through the Guard secret-FD mechanism;
6. injects only the required non-secret provider/model variables;
7. defaults network policy to `none`;
8. requires explicit `--network host` for the current provider integrations because egress-only networking is not implemented yet.

The outer Guard uses `--clearenv` before adding explicitly allowed environment variables.

API keys are not intentionally placed in the worker command line or workspace.

## Real-NAS integration validation — PASS

The following real-NAS paths were validated:

```
/vol1/Docker/tapo-nas-lab
/vol1/Docker/ai-cli-lab/workers/clay/bin/clay-worker
/vol1/Docker/Ai-guard
```

### AI Guard regression

The full Guard regression suite passed:

```
guarded program
secret environment
non-secret environment
filesystem
workspace guard
policy guard
root guard
home
docker sockets
capabilities/session
pid namespace
network namespace
network host mode
symlink escape

ALL TESTS PASSED
```

### Tapo workspace security

The real Tapo workspace passed the Guard isolation test:

- `/workspace` is writable and usable.
- `/vol1` is not visible.
- host `/home/admin/.ssh` is not visible.
- host `/root/.ssh` is not visible.

The adapter/Guard allowlist permits only the intended Tapo repository path and continues to reject general `/vol1` paths.

### Groq → Tapo

Observed successful result:

```
◆ Agent (openai/gpt-oss-120b)

  GROQ_TAPO_FINAL_OK
```

### Gemini → Tapo

Observed successful result:

```
◆ Agent (gemini-3.1-flash-lite)

  GEMINI_TAPO_FINAL_OK
```

The Gemini selector displayed all five keys, and the explicitly selected key's last-used state was updated without exposing the secret value.

These tests prove the two provider paths can execute the Clay worker inside AI Guard against the real Tapo workspace.

## Multi-provider design

Current provider roles:

- Groq = primary
- Gemini 3.1 Flash-Lite = backup
- Provider #3 = reserved

Credential locations on the NAS:

```
~/.config/clay/groq.env
~/.config/clay/gemini-keys
~/.config/clay/state/gemini-key-last-used
```

Credential files are outside the repositories and workspace.

The old Gemini infrastructure remains separate and has **not** been deleted.

Do not delete `/vol1/Docker/gemini` until the operator explicitly approves that cleanup.

## Important boundaries

Do **not** weaken either sandbox merely to make a future test pass.

In particular, do not immediately:

- disable Clay's internal sandbox;
- remove user namespaces;
- bypass `uidmap`;
- broaden filesystem exposure;
- expose `/vol1`;
- expose Docker sockets;
- put API keys into argv;
- put API keys into the workspace;
- make network access implicit.

If a future integration test fails, preserve the exact failure output first and diagnose the specific layer.

## Current network limitation

The current working provider proofs use:

```
--network host
```

This is deliberate. AI Guard does not yet have an egress-only policy for allowing only the required provider endpoint.

Do not silently change the default from `none` to broad networking.

## Source-of-truth workflow

Use:

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

Avoid fragile direct edits on the NAS when a repository change is appropriate.

## Current checkpoint

The Clay + AI Guard multi-provider integration is now a **verified PASS checkpoint** on the real NAS.

The verified state includes:

1. Guard regression suite PASS.
2. Groq → Clay → Guard → Tapo workspace PASS.
3. Gemini → Clay → Guard → Tapo workspace PASS.
4. Five-key Gemini selector/state path PASS.
5. Groq regression after Gemini integration PASS.
6. Gemini API URL corrected to the no-trailing-slash OpenAI-compatible base path.
7. Tapo workspace allowlist committed in AI Guard.

Do not continue reducing Clay solely for LOC reduction. Future work should first be driven by a demonstrated functional or security requirement.

## Next operational task

Use the verified Clay + AI Guard path to perform a **read-only audit of the Tapo backup and retention system**.

Audit scope:

- actual `tapo-nas-lab` backup/upload/archive/manifest/reconciliation/retention files;
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

Audit rules:

- read-only;
- do not upload;
- do not delete;
- do not restart services;
- do not install packages;
- do not modify recorder/Event Logger;
- do not modify production recordings;
- report facts and evidence before proposing changes.

Target retention policy:

```
Rolling D-7

newer than 7 days → KEEP
age >= 7 days → eligible for deletion only after remote backup verification
active file being written → NEVER delete
```

Historical cleanup rules from September 2026 are not production retention logic.

## Do not confuse these projects

- `ai-cli-lab`: AI CLI/worker experiments and execution workflows.
- `Ai-guard`: security enforcement and sandbox boundary.
- `tapo-nas-lab`: Tapo/NAS application.

The Clay worker belongs to `ai-cli-lab`; the security boundary belongs to `Ai-guard`.
