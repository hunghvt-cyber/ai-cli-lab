#!/usr/bin/env bash
set -euo pipefail

REPO=/vol1/Docker/ai-cli-lab
GUARD=/vol1/Docker/Ai-guard
WORKER="$REPO/workers/clay/bin/clay-worker"
WORKSPACE=/vol1/Docker/tapo-nas-lab
PROMPT="$REPO/docs/prompts/tapo-backup-retention-audit-primitives.txt"
SECRETS="$REPO/secrets/openrouter.env"

if [ ! -f "$PROMPT" ]; then
  echo "ERROR: missing prompt: $PROMPT" >&2
  exit 1
fi

if [ ! -f "$SECRETS" ]; then
  echo "ERROR: missing OpenRouter secret file: $SECRETS" >&2
  exit 1
fi

cd "$REPO"
git pull --ff-only

if ! git config user.name >/dev/null 2>&1 || ! git config user.email >/dev/null 2>&1; then
  echo "ERROR: Git author identity is not configured." >&2
  exit 4
fi

set -a
. "$SECRETS"
set +a

[ -n "\${OPENROUTER_API_KEY:-}" ] || { echo "ERROR: OPENROUTER_API_KEY is missing." >&2; exit 1; }
[ -n "\${OPENROUTER_BASE_URL:-}" ] || { echo "ERROR: OPENROUTER_BASE_URL is missing." >&2; exit 1; }
[ -n "\${OPENROUTER_MODEL:-}" ] || { echo "ERROR: OPENROUTER_MODEL is missing." >&2; exit 1; }

export CLAY_API_KEY="$OPENROUTER_API_KEY"
export CLAY_BASE_URL="$OPENROUTER_BASE_URL"
export CUSTOM_MODEL="$OPENROUTER_MODEL"

date_utc="$(date -u +%Y%m%dT%H%M%SZ)"
log_dir="/tmp/tapo-audit-primitives-openrouter-\${date_utc}"
mkdir -p "$log_dir"
live_log="$log_dir/live.log"

echo "=== Tapo backup/retention primitive audit ==="
echo "Provider: openrouter"
echo "Model: $OPENROUTER_MODEL"
echo "Workspace: $WORKSPACE"
echo "Audit: READ-ONLY"
echo "Primitive shell discipline: ENABLED"
echo "Live log: $live_log"
echo

set +e
"$GUARD/adapters/clay" \
  --provider custom \
  --worker "$WORKER" \
  --workspace "$WORKSPACE" \
  --network host \
  -- \
  --cwd /workspace \
  --prompt "$(cat "$PROMPT")" 2>&1 | tee "$live_log"
clay_status="\${PIPESTATUS[0]}"
set -e

echo
echo "=== CLAY/GUARD EXIT STATUS: $clay_status ==="

if [ "$clay_status" -ne 0 ]; then
  echo "AUDIT FAILED: no GitHub report committed." >&2
  echo "Live log preserved at: $live_log" >&2
  exit 2
fi

if grep -Eiq '(GROQ_API_KEY|GEMINI_API_KEY|OPENROUTER_API_KEY|CLAY_API_KEY|BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{20,})' "$live_log"; then
  echo "SAFETY STOP: possible credential material detected; report was NOT committed." >&2
  echo "Live log preserved at: $live_log" >&2
  exit 3
fi

report="docs/audits/tapo-backup-retention-primitives-openrouter-\${date_utc}.md"

{
  echo "# Tapo/NAS Backup and Retention Primitive Audit"
  echo
  echo "- Date (UTC): $date_utc"
  echo "- Provider: openrouter"
  echo "- Model: $OPENROUTER_MODEL"
  echo "- Workspace: $WORKSPACE"
  echo "- Scope: READ-ONLY"
  echo "- Shell discipline: one safe command per tool call"
  echo
  echo "---"
  echo
  cat "$live_log"
} > "$report"

git add "$report"
git commit -m "audit: Tapo backup retention primitives OpenRouter $date_utc"
git push origin main

echo
echo "AUDIT REPORT PUSHED: $report"
echo "Live log preserved at: $live_log"
