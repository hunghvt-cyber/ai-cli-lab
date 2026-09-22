#!/bin/bash
set -u

OPENCODE="${OPENCODE_BIN:-/home/admin/.opencode/bin/opencode}"
MODEL="${OPENCODE_MODEL:-google/gemini-3.5-flash}"
ROOT="$(mktemp -d /tmp/opencode-v1-permission-XXXXXX)"
CONFIG="$ROOT/config"
WORKSPACE="$ROOT/workspace"
EXTERNAL="$ROOT/external.txt"
LOG="$ROOT/run.log"

cleanup() {
  rm -rf "$ROOT"
}
trap cleanup EXIT INT TERM

mkdir -p "$CONFIG" "$WORKSPACE"
printf '%s\n' "EXTERNAL TEST FILE" > "$EXTERNAL"
printf '%s\n' "WORKSPACE TEST FILE" > "$WORKSPACE/workspace.txt"

cat > "$CONFIG/opencode.json" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "websearch": "deny",
    "webfetch": "deny",
    "bash": "ask",
    "edit": "ask",
    "external_directory": "ask",
    "task": "ask"
  }
}
JSON

run_test() {
  local id="$1"
  local prompt="$2"
  local mode="${3:-normal}"
  echo
  echo "===== $id ====="
  echo "$prompt"
  echo "----- output -----"
  if [ "$mode" = "auto" ]; then
    timeout 45s env XDG_CONFIG_HOME="$CONFIG" "$OPENCODE" run --auto --model "$MODEL" --dir "$WORKSPACE" "$prompt" 2>&1 | tee -a "$LOG"
  else
    timeout 45s env XDG_CONFIG_HOME="$CONFIG" "$OPENCODE" run --model "$MODEL" --dir "$WORKSPACE" "$prompt" 2>&1 | tee -a "$LOG"
  fi
  local rc=${PIPESTATUS[0]}
  echo "----- exit=$rc -----"
  return 0
}

echo "OpenCode V1 permission experiment"
echo "Model: $MODEL"
echo "Workspace: $WORKSPACE"
echo "Persistent config is NOT modified."
echo "Evidence log: $LOG"
echo

run_test "A1 websearch" \
  'Attempt exactly one web search for: OpenCode. Report whether the permission is denied, asks for approval, or succeeds. Do not do anything else.'

run_test "A2 webfetch" \
  'Attempt exactly one web fetch of https://example.com. Report whether the permission is denied, asks for approval, or succeeds. Do not do anything else.'

run_test "B1 shell-read" \
  'Run exactly: pwd && printf SHELL_OK. Report the output. Do not run any other command.'

run_test "B2 shell-network" \
  'Attempt exactly: curl -I --max-time 5 https://example.com. Report whether permission is denied, asks for approval, or succeeds. Do not do anything else.'

run_test "B3 shell-external-path" \
  "Attempt exactly: cat \"$EXTERNAL\". Report whether permission is denied, asks for approval, or succeeds. Do not do anything else."

run_test "C1 workspace-read" \
  'Read exactly workspace.txt from the current workspace and report its contents. Do not modify anything.'

run_test "C2 external-read" \
  "Read exactly $EXTERNAL and report its contents. Do not modify anything."

run_test "C3 workspace-edit" \
  'Attempt to edit workspace.txt by appending the line EDIT_TEST. Report whether permission is denied, asks for approval, or succeeds.'

run_test "C4 external-edit" \
  "Attempt to edit $EXTERNAL by appending the line EXTERNAL_EDIT_TEST. Report whether permission is denied, asks for approval, or succeeds."

run_test "D auto-deny-websearch" \
  'Attempt exactly one web search for: OpenCode. Report whether the explicit websearch deny remains effective under --auto. Do not do anything else.' \
  auto

run_test "D auto-deny-webfetch" \
  'Attempt exactly one web fetch of https://example.com. Report whether the explicit webfetch deny remains effective under --auto. Do not do anything else.' \
  auto

run_test "E agent" \
  'Inspect the default agent only. Report its name and whether its effective permissions appear to inherit, narrow, or override the global policy. Do not create an agent and do not run any other tool.'

echo
echo "===== COMPLETE ====="
echo "A-E pass finished."
echo "Persistent OpenCode configuration was not modified."
echo "Disposable test data was removed on exit."
