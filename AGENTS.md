# ReasonKey project instructions

Before work that can affect behavior, installation or release, read in order:

1. [README.md](README.md) and [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md) for the user surface and runtime overview.
2. [docs/product-spec.md](docs/product-spec.md), the concise product core and routing table, then only the affected canonical owners. A router is not a request to load every child; cross-system work reads every affected owner.
3. [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) for source and validation entry points.
4. Relevant live code, configuration, tests and logs.
5. [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) and affected packaging guides for build, installation, security or release work.

The latest explicit user decision overrides older text. Confirmed core/owner rules describe intent; code and tests describe what is actually implemented. Report conflicts rather than silently turning current behavior into a product rule. Read [open decisions](docs/product-spec/open-decisions.md) only when introducing intent, touching an unresolved question or finding a contradiction.

Each exact rule has one canonical owner. Update that owner in the same task when a confirmed rule, UI contract, priority, prohibition, terminology or important open question changes. Other engineering documents link to it and state local consequences. Keep public README/configuration/Store copy consistent. An implementation-only fix updates the owner's concise implementation snapshot only if status materially changes.

Preserve the keyboard-accessible interaction and all picker starting states according to the [picker owner](docs/product-spec/picker.md). UIA calls returning without throwing are not proof; verify the resulting accessible row and final Button label.

Preserve per-user, non-admin installation, existing installed presets.ini and unrelated AutoHotkey scripts according to the [installation owner](docs/product-spec/installation.md). Keep the vendored UIA-v2 MIT license and [third-party notice](THIRD_PARTY_NOTICES.md).

Treat engineering documentation as retrieval context, not a work log. Keep rules, current implementation, open questions and historical evidence separate. Git/CHANGELOG and docs/diagnostics own chronology. Maintain concise routing and split coherent ownership domains proactively when a document requires loading substantial unrelated context. Update routes, links and owner declarations together; do not discard current rules or resolve product decisions as part of restructuring.

Preserve unrelated dirty work. Run validation proportional to the change. After documentation changes run scripts/Test-Documentation.ps1 and git diff --check; this is not runtime proof. Before release, build with scripts/Build.ps1 -Clean and run the real Codex/ChatGPT regression matrix in docs/DEVELOPMENT.md. Record unavailable legacy or external gates as unverified, never as passed. Do not mark implemented/verified without evidence matching the claim.
