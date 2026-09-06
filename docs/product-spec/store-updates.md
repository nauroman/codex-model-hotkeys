# Microsoft Store updates

Canonical owner of helper activation, identity gating, update policy and restart.
[Installation](installation.md) owns singleton/storage;
[MSIX packaging](../../packaging/msix/README.md) owns construction/signing;
[Privacy](../../PRIVACY.md) owns the public data/network statement.

## Rules

- Build/package the native helper only with MSIX; the direct EXE does not contain
  or launch it.
- Only the public ReasonKey Store identity may query its associated updates
  through Windows.Services.Store. No OpenAI client or separate update server.
- Check on each active Store launch. Request silent download/install only when
  Windows permits; respect Store auto-update, network, battery and service
  policy. Do not override policy; retry on a later launch.
- Register an application restart before checking. Enable update replacement
  restart; disable crash, hang and reboot restarts.
- Retain a bounded activation fallback after successful update completion and
  preserve the cross-channel singleton during relaunch.
- Record local outcomes. An unavailable update, denied silent installation or
  helper error must not be reported as a completed update.

## Current implementation

Source inspection: 2026-09-05, working-tree AppVersion 1.0.7; the update mechanism
was introduced in 1.0.6.

[ReasonKey.ahk](../../src/ReasonKey.ahk): StartStoreUpdateCheck registers Restart
Manager, copies a watcher to writable package data, starts the helper hidden,
and observes its process. CheckStoreUpdateProcess handles outcomes and fallback
activation.

The AHK IsMicrosoftStoreRuntime gate accepts public and .Dev ReasonKey package
families, so development launches can start the helper. The native
[ReasonKey.StoreUpdater.cpp](../../src/StoreUpdater/ReasonKey.StoreUpdater.cpp)
CheckForStoreUpdate/IsStorePackageFamily gate rejects .Dev and non-Store identity
before contacting Windows Store services. Do not equate helper launch with a
network request.

The native --self-test exercises the identity predicate. --package-probe confirms
only that a package identity exists; it does not query the Store or prove update
installation. A public result=no-update demonstrates a completed check only.
A real replacement/restart needs observed old/new package versions, process
replacement and exactly one returned tray runtime.

## Evidence and release boundary

[Development](../DEVELOPMENT.md) defines the required update checks.
[Historical Store evidence](../diagnostics/store-release-history.md) records the
1.0.6 no-update response and fallback activation separately. Neither proves a
real public package upgrade after certification. Complete fresh
[submission/post-certification gates](../../packaging/store/SubmissionChecklist.md)
for the exact release.
