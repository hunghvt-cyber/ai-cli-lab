# Gemini Scope-Control Experiment — 2026-09-22

## Context

This experiment was run while testing OpenCode provider smoke tests on FnNAS. The requested task was narrowly scoped: test one specific OpenCode model with a minimal `OK` prompt.

Target model:

`google/gemini-3.5-flash`

The Gemini execution assistant was explicitly instructed to:

- use SSH to FnNAS;
- test only the specified model;
- not use web search;
- not modify configuration or systems;
- stop after reporting the result.

## Observed behavior

The execution transcript showed the assistant:

1. Tried to locate `OpenCode` with an uppercase name instead of the known lowercase binary `opencode`.
2. Tried additional host searches, including `find /`, although locating the already-known binary was not necessary for the task.
3. The UI then showed a `GoogleSearch` tool invocation with the text `Searching the web for: "Op…"`.
4. The session remained in a prolonged Thinking state and did not reach the requested model smoke test.
5. The operator exited the session and re-entered it. No persistent system change was reported.

## Important evidence note

After the session was stopped, Gemini reported that it had not itself executed GoogleSearch and that the search-related information may have come from automatically loaded session context.

That explanation does not change the observed transcript: a GoogleSearch tool invocation was displayed during the run. Therefore this experiment records the event as **observed tool invocation**, not as proof that an external web request completed.

Similarly, the transcript proves the use of `OpenCode`/uppercase lookup attempts; it does not establish why the assistant selected that spelling.

## Result

**Status: BLOCKED / INCONCLUSIVE**

The OpenCode model smoke test was not completed.

This run is useful as a behavior observation:

- explicit "no web search" instructions did not prevent a GoogleSearch tool invocation from appearing in the session;
- the execution path expanded beyond the minimal task;
- the requested OpenCode binary was not invoked.

No conclusion is made here about the underlying cause or about security enforcement.

## Follow-up

Before continuing provider smoke tests, determine whether the observed search invocation and scope expansion originate from:

1. Gemini tool behavior;
2. automatically loaded session/context information;
3. Gemini policy/configuration;
4. the execution environment.

Do not build a new enforcement mechanism based on this single observation. Reproduce and isolate the behavior first.
