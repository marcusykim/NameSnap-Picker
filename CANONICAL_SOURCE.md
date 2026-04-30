# NameSnap Canonical Source

Canonical local path:

- `/volumes/mracuth/NameSnap`

Canonical remote:

- `git@github.com:marcusykim/NameSnap-Picker.git`

Current doctrine:

- This repository is the single source of truth for NameSnap.
- Do not copy code from older NameSnap folders, backup snapshots, PullUp assets, or artifact directories back into this repo unless explicitly reviewed.
- If another NameSnap source tree appears, compare it against this repo first, then archive or replace it from this canonical source.
- App media/export folders may contain NameSnap videos or screenshots, but they are assets/artifacts, not source trees.

Runtime proof noted 2026-04-29:

- NameSnap was built, installed, and launched from this path in Simulator.
- Iron man verified the long-running inline name input/backspace bug was gone in this build.
- Preserve this implementation as the baseline for future release work.

Resume path:

1. Start from `/volumes/mracuth/NameSnap`.
2. Run `bash scripts/namesnap-build-install-launch.sh`.
3. Verify inline name input/backspace behavior before making input-editor changes.
4. Continue release/submission work from `TODOs.md` and `STOREKIT_LOCAL_TESTING.md`.
