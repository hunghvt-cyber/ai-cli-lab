# OpenCode V1 Permission Experiment

Target: OpenCode 1.18.32 on FnNAS (aarch64).

## Purpose

Test the native OpenCode V1 permission system before adding any custom enforcement.

This is an experiment only. It must not modify NAS services, recordings, Gemini configuration, or Ai-guard.

## Initial policy under test

- websearch: deny
- webfetch: deny
- bash: ask by default
- edit: ask by default
- external_directory: ask by default
- task: ask by default
- explicit deny must remain effective even with auto-approval

## Test groups

### A — Web boundary
- Attempt web search.
- Attempt web fetch.
- Record whether the action is denied, asks for approval, or succeeds.

### B — Shell boundary
- Run harmless read-only commands.
- Run a command that attempts network access.
- Run a command that attempts to access a path outside the workspace.
- Record every permission decision.

### C — File boundary
- Read a workspace file.
- Read an external file.
- Attempt to edit a workspace file.
- Attempt to edit an external file.

### D — Auto approval
- Repeat selected tests with --auto.
- Verify that explicit deny rules still block denied capabilities.

### E — Agent boundary
- Inspect the default agent.
- Test whether agent-level permissions can override or narrow the global policy.
- Do not create persistent agents during the first experiment.

## Safety

- Use a disposable test workspace only.
- Do not expose /vol1, /root, SSH credentials, Docker socket, or NAS recordings.
- Do not start/stop/restart services.
- Do not install additional software.
- Do not modify OpenCode persistent configuration until the experiment design is approved.
- Capture observed behavior as evidence.

## Exit condition

Stop after the first complete A-E pass and report facts. Do not implement a workaround based on failures during the experiment.
