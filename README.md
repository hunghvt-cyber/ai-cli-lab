# ai-cli-lab

## Vision

Build a practical, reusable laboratory for AI CLI tools used by a human operator on real infrastructure.

The repository focuses on **AI CLI behavior, configuration, workflows, experiments, and operational patterns**. It is not intended to become another security-enforcement project.

## Goals

- Study and operate Gemini CLI, OpenCode, and future AI CLIs in a consistent way.
- Keep AI CLI behavior bounded by explicit user scope and authorization.
- Prefer existing, proven mechanisms over building custom infrastructure.
- Separate AI CLI workflow concerns from security enforcement.
- Record experiments and observed behavior so decisions are based on evidence.
- Keep the NAS operationally lightweight and avoid unnecessary services.

## Core principle

**Human decides. AI CLI executes within explicit scope.**

The AI CLI is an execution/helper layer, not the architect or final authority.

Default operational workflow:

**AUDIT → OBSERVE → REPORT → STOP**

Unless explicitly authorized, an AI CLI must not:
- expand scope;
- invent missing facts;
- modify systems;
- install software;
- restart services;
- delete or repair data;
- create credentials;
- continue into unrelated investigation;
- make architectural decisions on behalf of the operator.

## Repository separation

| Repository | Responsibility |
|---|---|
| [Ai-guard](https://github.com/hunghvt-cyber/Ai-guard) | Security enforcement, sandboxing, isolation |
| **ai-cli-lab** | Gemini CLI, OpenCode, other AI CLI workflows and experiments |
| [tapo-nas-lab](https://github.com/hunghvt-cyber/tapo-nas-lab) | Tapo/NAS application |

The AI CLI layer must not silently become the security-enforcement layer.

## Security philosophy

Do not assume that an AI CLI's permission prompts are a security boundary.

When stronger isolation is required, use established mechanisms such as containers, namespaces, VMs, restricted accounts, capability-based access, or the separate Ai-guard project.

The lab should test what existing mechanisms actually provide before adding custom enforcement.

## NAS operational model

The target environment includes a low-resource NAS where AI CLI tools may need to perform legitimate operational tasks such as:

- inspect system state;
- inspect Docker state;
- inspect recordings;
- inspect services;
- inspect disk/RAM/swap;
- perform explicitly authorized maintenance.

Access should therefore be designed around **capabilities and least privilege**, rather than giving an AI CLI unrestricted host access merely because it needs some host operations.

## Planned areas

### Gemini

- CLI configuration
- operational rules
- host/NAS workflows
- experiments
- behavior observations

### OpenCode

- CLI configuration
- permission model experiments
- Docker/VM isolation experiments
- NAS operational workflows
- behavior tests

### Shared

- common policies
- reusable workflows
- test methodology
- evidence/reporting conventions

## Non-goals

This repository will not:

- replace Ai-guard;
- become a general-purpose security framework;
- add enforcement without demonstrated need;
- turn every experiment into production infrastructure;
- grant broad host access simply for convenience.

## Working rule

Prefer:

**existing mechanism → test → observe → document → only then build**

rather than:

**design a large custom system → implement → discover whether it was necessary**

## Clay Worker Checkpoint

The current Clay reduction has reached a stable **headless worker + AI Guard end-to-end checkpoint**.

- Headless target: `workers/clay/bin/clay-worker`
- Provider/model proven: Groq / `openai/gpt-oss-120b`
- Outer boundary: [Ai-guard](https://github.com/hunghvt-cyber/Ai-guard) + Bubblewrap
- Clay's internal sandbox remains enabled inside the outer Guard.
- Secret injection uses the Guard secret-FD mechanism; the API key is not intentionally placed in argv or the workspace.
- Real NAS end-to-end test returned `AI_GUARD_CLAY_OK`.
- Current proof requires explicit `--network host`; Guard's default remains network `none`.

Detailed durable handoff: [docs/CLAY_GUARD_CHECKPOINT.md](docs/CLAY_GUARD_CHECKPOINT.md).

## Status

Initial repository setup. Architecture and workflow are intentionally kept small while Gemini CLI and OpenCode are evaluated.
