# Tapo/NAS Backup and Retention Primitive Audit

- Date (UTC): 20260926T022133Z
- Provider: gemini
- Gemini key selector: 1
- Workspace: /vol1/Docker/tapo-nas-lab
- Scope: READ-ONLY
- Shell discipline: one safe command per tool call

---

Gemini API Key

1. KEY1       used 0h 7m ago           
2. KEY2       used 18h 19m ago [AVAILABLE]
3. KEY3       used 19h 51m ago [AVAILABLE]
4. KEY4       used 19h 34m ago [AVAILABLE]
5. KEY5       used 19h 30m ago [AVAILABLE]
◆ Agent (gemini-3.1-flash-lite)
[?25l[2K  ⠋ Executing shell command…[2K[2K  ⠙ Executing shell command…[2K  ⠹ Executing shell command…[2K  ⠸ Executing shell command…[2K  ⠼ Executing shell command…[2K  ⠴ Executing shell command…[2K  ⠦ Executing shell command…[2K  ✓ Executed $find /workspace -maxdepth 2 -not -path '*/.*' (0.6s)
[?25h    · /workspace
    · /workspace/scripts
    · /workspace/scripts/tapo-lifecycle.py
    · /workspace/tests
    · /workspace/tests/20260919-0045-zeep-renew
    · /workspace/tests/20260919-0045-zeep-lifecycle
    · /workspace/tests/20260919-0045-zeep-lifecycle-v2
    · /workspace/tests/20260919-0130-segment-resolver
    · …
[?25l[2K  ⠋ Executing shell command…[2K  ⠙ Executing shell command…[2K  ⠹ Executing shell command…[2K  ✓ Executed $cat /workspace/scripts/tapo-lifecycle.py (0.2s)
[?25h    · import asyncio
    · import base64
    · import hashlib
    · import os
    · import secrets
    · from datetime import datetime, timezone
    · from aiohttp import web, ClientSession, ClientTimeout
    · from onvif import ONVIFCamera
    · …
[?25l[2K  ⠋ Executing shell command…[2K  ⠙ Executing shell command…[2K  ⠹ Executing shell command…[2K  ✓ Executed $find /workspace -maxdepth 2 -not -path '*/.*' (0.2s)
[?25h    · /workspace
    · /workspace/scripts
    · /workspace/scripts/tapo-lifecycle.py
    · /workspace/tests
    · /workspace/tests/20260919-0045-zeep-renew
    · /workspace/tests/20260919-0045-zeep-lifecycle
    · /workspace/tests/20260919-0045-zeep-lifecycle-v2
    · /workspace/tests/20260919-0130-segment-resolver
    · …
[?25l[2K  ⠋ Executing shell command…[2K  ⠙ Executing shell command…[2K  ⠹ Executing shell command…[2K  ✓ Executed $cat /workspace/tools/upload-missing-20260922.py (0.2s)
[?25h    · #!/usr/bin/env python3
    · import csv, os, subprocess, sys, time
    · CSV = "/vol1/Docker/tapo-nas-lab/audit/missing-20260922.csv"
    · LOG = "/tmp/upload_missing_20260922.log"
    · TOTAL = 2683
    · with open(CSV, newline="", encoding="utf-8") as f:
    ·     rows = list(csv.DictReader(f))
    · if len(rows) != TOTAL:
    · …
[?25l[2K  ⠋ Executing shell command…[2K  ⠙ Executing shell command…[2K  ⠹ Executing shell command…[2K  ⠸ Executing shell command…[2K  ✓ Executed $cat /workspace/compose.yml (0.3s)
[?25h    · services:
    ·   tapo-event-cam1:
    ·     env_file:
    ·       - .secrets/tapo.env
    ·     image: tapo-event-producer:test
    ·     command: python3 /app/event-logger/cam1-event-logger.py
    ·     network_mode: host
    ·     volumes:
    · …

  ### A. EXECUTIVE FACTS
  - The system is a prototype/test setup.
  - **Source of Truth:** Files recorded to `/vol1/Docker/tapo-recorder/recordings/` (mounted read-only into production containers).
  - **Current State:** The repo contains scripts for ONVIF event subscription management (`tapo-lifecycle.py`) and ad-hoc recovery tools (`upload-missing-20260922.py`), but lacks an automated, integrated production backup/retention scheduler.
  - **Verification:** Verification logic exists only in manual recovery tools (checking file existence and size).

  ### B. ACTUAL BACKUP PIPELINE
  - **None observed** in the workspace. The current system relies on manual scripts (e.g., `upload-missing-20260922.py`) to reconcile missing data.
  - **Pipeline Logic:** The `upload-missing` tool uses `rclone copyto` to move specific files to a remote `tapo-gdrive:`.

  ### C. ACTUAL RETENTION PIPELINE
  - **None observed.** There is no automated lifecycle script that enforces the D-7 retention policy.

  ### D. SCHEDULING
  - No `cron` or `systemd` timers are observable in the current file structure. The system is manually triggered or run via the containerized event-producer services.

  ### E. VERIFICATION / SAFETY GUARANTEES
  - The recovery tool `upload-missing-20260922.py` implements pre-upload verification:
    1. Checks `os.path.isfile(src)`.
    2. Compares `os.path.getsize(src)` with a hardcoded CSV reference value.
  - **Deficiency:** No automated post-upload verification of remote existence OR size comparison before local deletion is implemented.

  ### F. D-7 GAP ANALYSIS
  - The system lacks any mechanism to distinguish between "new" (<=7 days) and "old" (>=7 days) recordings.
  - The current "retention" policy appears to be "manual oversight" rather than automated deletion.

  ### G. OBSOLETE / HISTORICAL COMPONENTS
  - `audit/missing-20260922.csv`: Historical evidence of a specific gap event.
  - `tools/upload-missing-20260922.py`: Recovery tool; not suitable for production retention/backup.
  - `event-logger/*.bak-20260920`: Historical backup of source code.

  ### H. EVIDENCE
  - **Recovery Script:** `/workspace/tools/upload-missing-20260922.py` (demonstrates size checking).
  - **Service Definition:** `/workspace/compose.yml` (shows mount points for recordings).
  - **ONVIF Logic:** `/workspace/scripts/tapo-lifecycle.py`.

  ### I. SMALLEST SAFE IMPLEMENTATION PLAN
  *(Requirement: Stop after report. Implementation prohibited.)*