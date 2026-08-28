# Project instructions

Before changing runtime behavior, read `README.md`, `docs/HOW_IT_WORKS.md`, and
`docs/PROJECT_CONTEXT.md`.

Preserve support for both the compact Power slider and the already-expanded
Advanced picker. Do not replace the verified keyboard-accessible interaction:
use focus + Enter for the view toggle and options, and focus + Right Arrow for
Model/Effort flyout rows. UIA calls that merely return without throwing are not
proof of success; validate the resulting accessible row and final Button label.

Keep installation per-user and non-admin. Preserve an existing installed
`presets.ini` during upgrades. Do not delete or stop unrelated AutoHotkey
scripts. Vendored UIA-v2 is MIT-licensed; keep its license and third-party
notice.

Before release, build with `scripts/Build.ps1 -Clean` and run the regression
matrix in `docs/DEVELOPMENT.md` against a real Codex desktop window.
