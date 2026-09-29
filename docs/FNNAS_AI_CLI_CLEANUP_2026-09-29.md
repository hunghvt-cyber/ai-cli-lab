# FnNAS AI CLI Cleanup — 2026-09-29

## Scope

Completed cleanup of obsolete Gemini CLI / OpenCode runtime artifacts on the real FnNAS host.

## Completed

- Removed legacy Gemini CLI runtime:
  - /usr/local/bin/gemini
  - /vol1/Docker/gemini
  - /vol1/Docker/gemini-webui
  - old Gemini CLI configuration/cache
  - old Gemini Docker image/container artifacts
  - /vol1/Docker/gemini-backup-20260921-075650.tar.gz
- Removed obsolete OpenCode runtime:
  - ~/.opencode
  - ~/.config/opencode
  - ~/.cache/opencode
  - ~/.local/share/opencode
  - ~/.local/bin/oc
  - /home/admin/ai-cli-lab/opencode
- Removed orphan Docker volumes: 2
- Removed dangling Docker images: 7
- Removed confirmed obsolete Docker images for cloudcmd, ttyd, dozzle, go2rtc and docker/compose.
- Removed obsolete test/backup artifacts:
  - /vol1/Docker/ai-guard-test-workspace
  - /vol1/Docker/fnnas-test-trigger.txt
  - /vol1/Docker/DockerInventory.backup-v1-20260815-224747
  - /vol1/Docker/tapo-phase1-test (207M)
- Removed old Gemini backup:
  - /vol1/Docker/backups/gemini-auto.bak (final remaining Gemini backup artifact)

## Final host state at checkpoint

- Docker containers running: 6
- Docker volumes: 0
- Dangling Docker images: 0
- /vol1: 287G used / 466G total / 179G available (62%)
- Production Tapo data at /vol1/Docker/tapo-nas-lab was not modified.
- Tapo recorder/event services were not restarted or modified.

## Intentional Gemini/OpenCode references retained

These are source code, tests, project documentation, secrets/infrastructure, Git metadata, or historical snapshot data; they are not obsolete runtime installations:

- Ai-guard/adapters/gemini
- Ai-guard/adapters/opencode
- Ai-guard/tests/opencode-behavior
- Ai-guard/poc/gemini-docker-relay
- Ai-guard/projects/GEMINI
- Ai-guard/projects/OPENCODE
- ai-cli-lab/gemini
- ai-cli-lab/opencode
- ai-cli-lab/secrets/gemini-keys
- project GEMINI.md files
- Git metadata containing historical opencode references
- fnnas-system-snapshot

## Next project focus

Return to Tapo Backup/Retention. The production recordings and recorder stack remain untouched.
