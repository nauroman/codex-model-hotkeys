# How it works

Runtime overview and compatibility router. Exact engineering contracts live in
the [product specification](product-spec.md); source locations live in
[project context](PROJECT_CONTEXT.md).

## Selection flow

A configured hotkey starts a guarded selection in the active desktop composer.
ReasonKey detects Codex versus ChatGPT, finds the accessible picker, selects the
model and effort, closes the menu and verifies the resulting accessible label
before logging success.

The unified picker opens a model radio view and a keyboard-controlled Power row.
Older compact/Advanced views use the retained flyout path. ReasonKey follows
focus when the popup is outside the main window tree. Generic UIA calls can
return without changing React state, so the keyboard path and observed result
are essential; see [picker interaction and verification](product-spec/picker.md).

## Runtime services

| Concern | Exact owner |
|---|---|
| Defaults, aliases, independent Chat values and invalid configuration | [Configuration](product-spec/configuration.md) |
| Direct/Store writable data, preserving presets, singleton, startup and Quick Start | [Installation](product-spec/installation.md) |
| Packaged update checks, identity gate and restart | [Store updates](product-spec/store-updates.md) |
| Local data, network and third-party service boundaries | [Privacy](../PRIVACY.md) |

The runtime does not use an OpenAI API key or modify Codex/ChatGPT files.
The direct runtime is offline; the public Store package asks Windows Store
services for ReasonKey updates. Download/build tooling has a separate network
role, documented in [Development](DEVELOPMENT.md).

## Compatibility and evidence

English accessible labels are version-sensitive implementation details.
Source inspection establishes available code paths; a clean build or --validate
does not prove that the current desktop picker works.

Use the [regression matrix](DEVELOPMENT.md) for fresh real-window evidence and
[Troubleshooting](TROUBLESHOOTING.md) for user diagnostics. Historical UI results
are linked from the picker owner and are not mandatory task context.
