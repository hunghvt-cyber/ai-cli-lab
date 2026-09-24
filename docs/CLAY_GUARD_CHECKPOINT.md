# Clay + AI Guard Integration Checkpoint

## Status

**PASS — end-to-end integration verified on the NAS.**

Date: 2026-09-24

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
Groq API
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

Provider used for the current checkpoint:

- Provider: `groq`
- Model: `openai/gpt-oss-120b`
- API base: `https://api.groq.com/openai/v1`

Standalone worker tests previously passed:

- one-shot Groq inference
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
3. receives `GROQ_API_KEY` from the operator environment;
4. writes the secret temporarily with restrictive permissions;
5. injects the secret into Bubblewrap through the Guard secret-FD mechanism;
6. injects non-secret `CLAY_PROVIDER=groq`;
7. injects `GROQ_MODEL`;
8. defaults network policy to `none`;
9. requires explicit `--network host` for the current Groq integration because egress-only networking is not implemented yet.

The outer Guard uses `--clearenv` before adding the explicitly allowed environment variables.

The Groq API key is therefore not intentionally placed in the worker command line or workspace.

## End-to-end proof

The following command was executed successfully on the NAS:

```sh
cd /vol1/Docker/Ai-guard && \
./adapters/clay \
  --worker /vol1/Docker/ai-cli-lab/workers/clay/bin/clay-worker \
  --workspace /tmp/clay-guard-test \
  --network host \
  -- \
  --prompt 'Reply with exactly: AI_GUARD_CLAY_OK'
```

Observed result:

```
◆ Agent (openai/gpt-oss-120b)

  AI_GUARD_CLAY_OK
```

This proves, in one real run:

- adapter invocation works;
- AI Guard program staging works;
- secret injection works;
- Bubblewrap starts successfully;
- the staged ARM64 Clay worker starts successfully;
- Clay's **nested internal sandbox** starts successfully inside the outer Guard;
- Groq network access works when explicitly using host networking;
- the selected Groq model responds;
- the one-shot worker exits normally.

## AI Guard test status

Before this integration checkpoint, the AI Guard regression suite passed:

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

The current integration therefore builds on an already passing Guard test suite.

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

The current working proof uses:

```
--network host
```

This is deliberate and temporary for the integration checkpoint. AI Guard does not yet have an egress-only policy for allowing only the required Groq endpoint.

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

## Next step

The Clay + AI Guard integration is considered a **stable checkpoint**.

Do not continue reducing Clay solely for LOC reduction at this point. Future work should first be driven by a demonstrated functional or security requirement.

Potential future work, in separate steps:

1. strengthen/verify AI Guard policy around Clay;
2. design egress-only network policy for the required provider endpoint;
3. add more guarded-worker regression tests;
4. consider additional AI worker adapters (for example future Qwen/other CLI workers);
5. only then revisit further Clay reduction if there is a concrete reason.

## Do not confuse these projects

- `ai-cli-lab`: AI CLI/worker experiments and execution workflows.
- `Ai-guard`: security enforcement and sandbox boundary.
- `tapo-nas-lab`: Tapo/NAS application.

The Clay worker belongs to `ai-cli-lab`; the security boundary belongs to `Ai-guard`.
