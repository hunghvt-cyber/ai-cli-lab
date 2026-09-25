#!/usr/bin/env bash
set -euo pipefail

REPO=/vol1/Docker/ai-cli-lab
GUARD=/vol1/Docker/Ai-guard
WORKER="$REPO/workers/clay/bin/clay-worker"
WORKSPACE=/vol1/Docker/tapo-nas-lab
PROMPT="$REPO/docs/prompts/tapo-backup-retention-audit-primitives.txt"
KEY="${1:-1}"

if [ ! -f "$PROMPT" ]; then
  echo "ERROR: missing prompt: $PROMPT" >&2
  exit 1
fi
if ! [[ "$KEY" =~ ^[1-5]$ ]]; then
  echo "ERROR: Gemini key must be 1..5" >&2
  exit 1
fi

cd "$REPO"
git pull --ff-only

if ! git config user.name >/dev/null 2>&1 || ! git config user.email >/dev/null 2>&1; then
  echo "ERROR: Git author identity is not configured." >&2
  exit 4
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "=== Tapo backup/retention primitive audit ==="
echo "Provider: Gemini"
echo "Gemini key: $KEY"
echo "Workspace: $WORKSPACE"
echo "Audit: READ-ONLY"
echo "Primitive shell discipline: ENABLED"
echo

if ! "$GUARD/adapters/clay" \
  --provider gemini \
  --gemini-key "$KEY" \
  --worker "$WORKER" \
  --workspace "$WORKSPACE" \
  --network host \
  -- \
  --cwd /workspace \
  --prompt "$(cat "$PROMPT")" | tee "$tmp"; then
  echo
  echo "AUDIT FAILED: no GitHub report committed." >&2
  exit 2
fi

if grep -Eiq '(GROQ_API_KEY|GEMINI_API_KEY|CLAY_API_KEY|BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{20,})' "$tmp"; then
  echo "SAFETY STOP: possible credential material detected; report was NOT committed." >&2
  exit 3
fi

date_utc="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p docs/audits
report="docs/audits/tapo-backup-retention-primitives-${date_utc}.md"

{
  echo "# Tapo/NAS Backup and Retention Primitive Audit"
  echo
  echo "- Date (UTC): `$date_utc`"
  echo "- Provider: Gemini"
  echo "- Gemini key selector: `$KEY`"
  echo "- Workspace: `$WORKSPACE`"
  echo "- Scope: READ-ONLY"
  echo "- Shell discipline: one safe command per tool call"
  echo
  echo "---"
  echo
  cat "$tmp"
} > "$report"

git add "$report"
git commit -m "audit: Tapo backup retention primitives $date_utc"
git push origin main

echo
echo "AUDIT REPORT PUSHED: $report"
