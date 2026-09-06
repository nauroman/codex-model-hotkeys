# ReasonKey product specification

Canonical router for product intent. Read this core, then only the owners relevant
to the task. Updated: 2026-09-05.

## Product and priorities

ReasonKey is an unofficial Windows tray utility from Rotorlash Labs for selecting
a complete model/reasoning preset in the Codex or ChatGPT Chat composer.

Priorities: verified selection, preservation of user configuration, keyboard
accessibility, compatibility across supported picker layouts, and simple per-user
installation. Current product/artifact names use ReasonKey; CodexModelHotkeys
names are retained only where migration or repository identity requires them.

## Authority and status

1. Latest explicit user decision.
2. Confirmed rules in this core and the routed canonical owner.
3. Live code/config/tests/logs as evidence of implementation.
4. Historical snapshots and prior behavior.

**Rule** means confirmed intent. **Current implementation** describes the inspected
source, not proof of a live run. **Open** means an unresolved decision or conflict.
**Future** is an intention, not a promise of shipped behavior. Report conflicts;
never turn accidental behavior into a product rule.

Each exact contract has one owner. Other engineering documents link to it and
state only local consequences. README, configuration examples, public privacy
statements and Store copy remain user-facing views; synchronize affected wording
when the owner changes without treating them as competing specifications.

## Routing

| Task | Canonical owner |
|---|---|
| Presets, defaults, parsing, aliases, independent Chat effort | [Configuration](product-spec/configuration.md) |
| Active-window scope, mode detection, UIA selectors, Power/Advanced interaction, final verification | [Picker](product-spec/picker.md) |
| Writable paths, migration, preservation, singleton, startup, Quick Start, uninstall | [Installation and lifecycle](product-spec/installation.md) |
| Store helper, identity gate, update policy and restart | [Store updates](product-spec/store-updates.md) |
| New intent, unresolved decision or contradiction | [Open decisions](product-spec/open-decisions.md) and affected owner |
| Build, test matrix, release evidence requirements | [Development](DEVELOPMENT.md) |
| MSIX toolchain, signing, package construction | [MSIX packaging](../packaging/msix/README.md) |
| Store submission gates and release-specific evidence | [Submission checklist](../packaging/store/SubmissionChecklist.md) |
| Data/network privacy; vulnerability reporting | [Privacy](../PRIVACY.md); [Security](../SECURITY.md) |
| Dependency provenance and redistribution notices | [Third-party notices](../THIRD_PARTY_NOTICES.md) |

Cross-system work reads every affected owner. For example, a new Chat preset
needs configuration and picker; an update restart change needs Store updates,
installation and the relevant Development/MSIX gates. A router is not a request
to load all its children.

## Global boundaries

- Keep the utility unofficial; do not imply OpenAI endorsement.
- Preserve compact Power, already-open model view and legacy Advanced support.
- Do not claim success without the resulting accessible state.
- Keep customer installation per-user and non-admin.
- Preserve existing active configuration during upgrades.
- Never stop or delete unrelated AutoHotkey scripts.
- Keep UIA-v2's license and third-party notice.
- No OpenAI API client, task-content collection or editing Codex/ChatGPT files;
  network/data details belong to the privacy owner.

## Documentation maintenance

Update the exact owner in the same task when a confirmed contract changes.
Update this core only for global intent, priorities, terminology or routing.
Implementation catching up with an existing rule changes only its concise
implementation snapshot when materially necessary.

Split by coherent responsibility when a task otherwise needs substantial
unrelated context. Update routes, owner declarations and affected links together;
do not lose rules or give them multiple owners. Put unresolved intent in the
decision register. Keep chronology in Git, CHANGELOG and diagnostics, not in
mandatory context.

Run `scripts/Test-Documentation.ps1` after documentation changes. Its size warning
prompts an ownership review, not deletion of current rules. Static validation is
not runtime, UI, installation or release proof.
