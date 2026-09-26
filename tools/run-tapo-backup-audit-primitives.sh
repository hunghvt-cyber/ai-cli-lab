#!/usr/bin/env bash
set -euo pipefail

REPO=/vol1/Docker/ai-cli-lab
GUARD=/vol1/Docker/Ai-guard
WORKER="$REPO/workers/clay/bin/clay-worker"
WORKSPACE=/vol1/Docker/tapo-nas-lab
PROMPT="$REPO/docs/prompts/tapo-backup-retention-audit-primitives.txt"
PROVIDER=""
KEY=""

# Interactive by default; keep legacy "2" => Gemini key 2 compatibility.
if [ "$#" -eq 0 ]; then
  echo "=== AI Provider Selector ==="
  echo "1. Gemini"
  echo "2. Groq"
  read -r -p "Select provider [1-2]: " provider_choice
  case "$provider_choice" in
    1) PROVIDER="gemini" ;;
    2) PROVIDER="groq" ;;
    *) echo "ERROR: provider must be 1 or 2" >&2; exit 1 ;;
  esac
elif [[ "${1:-}" =~ ^[1-5]$ ]]; then
  PROVIDER="gemini"
  KEY="$1"
elif [ "$1" = "gemini" ] || [ "$1" = "groq" ]; then
  PROVIDER="$1"
  KEY="${2:-}"
else
  echo "ERROR: usage: $0 [gemini [1-5]|groq|1-5]" >&2
  exit 1
fi

if [ "$PROVIDER" = "gemini" ] && [ -z "$KEY" ]; then
  echo
  echo "=== Gemini Key Selector ==="
  echo "1. KEY1"
  echo "2. KEY2"
  echo "3. KEY3"
  echo "4. KEY4"
  echo "5. KEY5"
  read -r -p "Select key [1-5]: " KEY
fi

if [ "$PROVIDER" = "gemini" ] && ! [[ "$KEY" =~ ^[1-5]$ ]]; then
  echo "ERROR: Gemini key must be 1..5" >&2
  exit 1
fi

if [ ! -f "$PROMPT" ]; then
  echo "ERROR: missing prompt: $PROMPT" >&2
  exit 1
fi
cd "$REPO"
git pull --ff-only

if ! git config user.name >/dev/null 2>&1 || ! git config user.email >/dev/null 2>&1; then
  echo "ERROR: Git author identity is not configured." >&2
  exit 4
fi

date_utc="$(date -u +%Y%m%dT%H%M%SZ)"
log_dir="/tmp/tapo-audit-primitives-${date_utc}"
mkdir -p "$log_dir"
live_log="$log_dir/live.log"

echo "=== Tapo backup/retention primitive audit ==="
echo "Provider: $PROVIDER"
if [ "$PROVIDER" = "gemini" ]; then
  echo "Gemini key: $KEY"
fi
echo "Workspace: $WORKSPACE"
echo "Audit: READ-ONLY"
echo "Primitive shell discipline: ENABLED"
echo "Live log: $live_log"
echo

set +e
if [ "$PROVIDER" = "gemini" ]; then
  "$GUARD/adapters/clay" \
    --provider gemini \
    --gemini-key "$KEY" \
    --worker "$WORKER" \
    --workspace "$WORKSPACE" \
    --network host \
    -- \
    --cwd /workspace \
    --prompt "$(cat "$PROMPT")" 2>&1 | tee "$live_log"
else
  "$GUARD/adapters/clay" \
    --provider groq \
    --worker "$WORKER" \
    --workspace "$WORKSPACE" \
    --network host \
    -- \
    --cwd /workspace \
    --prompt "$(cat "$PROMPT")" 2>&1 | tee "$live_log"
fi
clay_status="${PIPESTATUS[0]}"
set -e

echo
echo "=== CLAY/GUARD EXIT STATUS: $clay_status ==="

if [ "$clay_status" -ne 0 ]; then
  echo "AUDIT FAILED: no GitHub report committed." >&2
  echo "Live log preserved at: $live_log" >&2
  exit 2
fi

if grep -Eiq '(GROQ_API_KEY|GEMINI_API_KEY|OPENROUTER_API_KEY|CLAY_API_KEY|TAPO_|PASSWORD|PASSWD|BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{20,})' "$live_log"; then
  echo "SAFETY STOP: possible credential material detected; report was NOT committed." >&2
  echo "Live log preserved at: $live_log" >&2
  exit 3
fi

mkdir -p docs/audits
report="docs/audits/tapo-backup-retention-primitives-${date_utc}.md"

{
  echo "# Tapo/NAS Backup and Retention Primitive Audit"
  echo
  echo "- Date (UTC): $date_utc"
  echo "- Provider: $PROVIDER"
  if [ "$PROVIDER" = "gemini" ]; then
    echo "- Gemini key selector: $KEY"
  fi
  echo "- Workspace: $WORKSPACE"
  echo "- Scope: READ-ONLY"
  echo "- Shell discipline: one safe command per tool call"
  echo
  echo "---"
  echo
  cat "$live_log"
} > "$report"

git add "$report"
git commit -m "audit: Tapo backup retention primitives $date_utc"
git push origin main

echo
echo "AUDIT REPORT PUSHED: $report"
echo "Live log preserved at: $live_log"
