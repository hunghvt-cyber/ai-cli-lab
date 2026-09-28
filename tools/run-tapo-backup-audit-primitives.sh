#!/usr/bin/env bash
set -euo pipefail

REPO=/vol1/Docker/ai-cli-lab
GUARD=/vol1/Docker/Ai-guard
WORKER="$REPO/workers/clay/bin/clay-worker"
WORKSPACE=/vol1/Docker/tapo-nas-lab
PROMPT="$REPO/docs/prompts/tapo-backup-retention-audit-primitives.txt"
PROVIDER=""
KEY=""

if [ "$#" -eq 0 ]; then
  echo "=== AI Provider Selector ==="
  echo "1. Gemini"
  echo "2. Groq"
  echo "3. OpenRouter"
  read -r -p "Select provider [1-2]: " provider_choice
  case "$provider_choice" in
    1) PROVIDER="gemini" ;;
    2) PROVIDER="groq" ;;
    3) PROVIDER="openrouter" ;;
    *) echo "ERROR: provider must be 1 or 2" >&2; exit 1 ;;
  esac
elif [[ "${1:-}" =~ ^[1-5]$ ]]; then
  PROVIDER="gemini"
  KEY="$1"
elif [ "$1" = "gemini" ] || [ "$1" = "groq" ] || [ "$1" = "openrouter" ]; then
  PROVIDER="$1"
  KEY="${2:-}"
else
  echo "ERROR: usage: $0 [gemini [1-5]|groq|openrouter|1-5]" >&2
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

[ -f "$PROMPT" ] || { echo "ERROR: missing prompt: $PROMPT" >&2; exit 1; }
cd "$REPO"

date_utc="$(date -u +%Y%m%dT%H%M%SZ)"
log_dir="/tmp/tapo-audit-primitives-${date_utc}"
mkdir -p "$log_dir"
live_log="$log_dir/live.log"
raw_log="$log_dir/raw.log"

echo "=== Tapo backup/retention primitive audit ==="
echo "Provider: $PROVIDER"
if [ "$PROVIDER" = "gemini" ]; then
  echo "Gemini key: $KEY"
fi
echo "Workspace: $WORKSPACE"
echo "Audit: READ-ONLY"
echo "Primitive shell discipline: ENABLED"
echo "Output is withheld until secret scan passes."
echo

set +e
case "$PROVIDER" in
  gemini)
    "$GUARD/adapters/clay" --provider gemini --gemini-key "$KEY" --worker "$WORKER" --workspace "$WORKSPACE" --network host --ssh-key /home/clay/.ssh/id_ed25519 --clay-sandbox-mode unleashed-auto -- --cwd /workspace --prompt "$(cat "$PROMPT")" >"$raw_log" 2>&1
    ;;
  groq)
    "$GUARD/adapters/clay" --provider groq --worker "$WORKER" --workspace "$WORKSPACE" --network host --ssh-key /home/clay/.ssh/id_ed25519 -- --cwd /workspace --prompt "$(cat "$PROMPT")" >"$raw_log" 2>&1
    ;;
  openrouter)
    CLAY_OPENROUTER_SECRET_ENV=/vol1/Docker/ai-cli-lab/secrets/openrouter.env \
      "$GUARD/adapters/clay" --provider openrouter --worker "$WORKER" --workspace "$WORKSPACE" --network host --ssh-key /home/clay/.ssh/id_ed25519 -- --cwd /workspace --prompt "$(cat "$PROMPT")" >"$raw_log" 2>&1
    ;;
esac
clay_status=$?
set -e

if grep -Eiq '(GROQ_API_KEY|GEMINI_API_KEY|OPENROUTER_API_KEY|CLAY_API_KEY|TAPO_USER|TAPO_PASSWORD|TAPO_[A-Z0-9_]*(KEY|TOKEN|SECRET|PASS|PASSWORD|USER)|PASSWORD|PASSWD|BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{20,})' "$raw_log"; then
  echo "SAFETY STOP: possible credential material detected; raw output withheld." >&2
  echo "Audit exit status: $clay_status" >&2
  echo "Log directory: $log_dir" >&2
  exit 3
fi

if [ "$clay_status" -ne 0 ]; then
  echo "AUDIT FAILED: Clay/Guard exit status $clay_status" >&2
  echo "Clean log preserved at: $raw_log" >&2
  exit 2
fi

cp "$raw_log" "$live_log"
cat "$live_log"
echo
echo "=== CLAY/GUARD EXIT STATUS: $clay_status ==="
echo "CLEAN AUDIT OUTPUT: $live_log"
