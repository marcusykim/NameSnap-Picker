# NameSnap Automation Loop

Goal: give Jarvis a repeatable loop for **edit -> build -> install -> launch -> inspect -> test -> verify -> report fixed**.

## Current stack

- Local simulator automation skill: `/volumes/mracuth/skills/ios-simulator`
- GUI fallback: `/volumes/mracuth/skills/ios-simulator/scripts/sim-host-ui.mjs`
- GUI state confirmation skill: `macos-navigation-app-control`
- Build-recovery skill: `xcode-swiftpm-build-recovery`
- Symbol/reference safety: `swiftfindrefs`
- Optional perf profiling: `instruments-profiling`

## Scripts added

- `scripts/namesnap-env.sh`
- `scripts/namesnap-sim-health.sh`
- `scripts/namesnap-build-install-launch.sh`
- `scripts/namesnap-capture-state.sh`
- `scripts/namesnap-bug-loop.sh`

## Intended loop

1. Run `scripts/namesnap-sim-health.sh`
2. Run `scripts/namesnap-build-install-launch.sh`
3. Capture current UI/log state with `scripts/namesnap-capture-state.sh before-test`
4. Drive the bug path with `ios-sim.mjs ui ...` if semantic automation works
5. Fall back to `sim-host-ui.mjs` + screenshots when semantic automation does not work
6. Capture after-state with `scripts/namesnap-capture-state.sh after-test`
7. Compare artifacts before/after
8. Report PASS/FAIL with artifact paths

## Notes

- Artifact runs live under `artifacts/runs/`
- `artifacts/latest` points to the latest run dir
- `scripts/namesnap-idb-env.sh` now wires the working local `idb` CLI path at `$HOME/Library/Python/3.9/bin/idb`
- Proven NameSnap inline-editor keycodes via `idb`:
  - Return/new row = `40`
  - Backspace/delete = `42`
- `scripts/namesnap-inline-editor-repro.sh` is the new repeatable repro path: relaunches NameSnap, focuses the inline text field, seeds five names row-by-row, then captures a screenshot + accessibility dump after each backspace step
- The current blocking bug is the NameSnap backspace row-collapse behavior in the inline editor
