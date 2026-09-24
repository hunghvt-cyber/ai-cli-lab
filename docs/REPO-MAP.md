# NAS Repository Map

> Source of truth: GitHub `hunghvt-cyber/ai-cli-lab`, default branch.
> NAS must synchronize this file with `git pull --ff-only` before using it as the current repo map.
> This file records repository locations only; it is not a security boundary.

## FnNAS

| Repository | NAS path | Purpose |
|---|---|---|
| Ai-guard | `/vol1/Docker/Ai-guard` | AI execution security boundary |
| ai-cli-lab | `/vol1/Docker/ai-cli-lab` | AI CLI / worker workflows |
| tapo-nas-lab | `/vol1/Docker/tapo-nas-lab` | Tapo camera project |

## Operating rule

When the user names a project, resolve it through this map first. The resolved path is then supplied explicitly to the Clay/AI Guard command.

Do not infer a different path from the current shell directory.

## Synchronization rule

GitHub is the canonical copy of this map.

On FnNAS, from the `ai-cli-lab` checkout:

```sh
cd /vol1/Docker/ai-cli-lab
git pull --ff-only
```

If the pull reports local divergence or local modifications, stop and report; do not overwrite them automatically.

## Verification

The paths above were the known FnNAS repository paths at the time this map was created. Filesystem existence and Git checkout state should be verified on the real host when operational work begins.
