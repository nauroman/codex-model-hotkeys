# Astra development validation — 2026-09-05

Existing development report relocated from [Development](../DEVELOPMENT.md). These are the recorded results of the parallel 1.0.7 implementation task, not tests rerun during the documentation review. The [picker owner](../product-spec/picker.md) describes the source contract.

## Recorded evidence

- Installed Codex package: `26.901.5280.0`; local app resources contain the
  `gpt-6-astra` identifier and GPT-6 Astra announcement.
- `Build.ps1 -Clean` passed for 1.0.7, including runtime/model-selector,
  installer, uninstaller-path, and cross-path singleton validation.
- The live [picker regression matrix](../DEVELOPMENT.md) had not yet been run for 1.0.7.
  Build-time validation does not establish live UI compatibility. No public
  release or replacement of the installed Store package was performed.

## 1.0.8 repair and installed-runtime verification

The real accessible Button is `GPT-6 Astra <effort>`. Version 1.0.7 omitted
`GPT-` from its Button selector and logged `model picker was not found` even
with the picker closed. Version 1.0.8 accepts the prefix and normalizes it for
exact comparison. Keyboard selection and final Button verification are retained.

The user selected F16/F17/F18/F19 = Astra Light/Medium/High/Max. The active
direct-install INI was explicitly updated for that request; this is separate
from the installer's preservation policy. New defaults match that selection.

Clean build and built-in checks passed. On Codex `26.901.5280.0`, the installed
1.0.8 runtime produced these results in the current Codex task:

| Hotkey | Expected canonical Button label | Verified selected log (local time) |
|---|---|---|
| F16 | 6 Astra Light | 19:10:59 |
| F17 | 6 Astra Medium | 19:11:12 |
| F18 | 6 Astra High | 19:11:23 |
| F19 | 6 Astra Max | 19:11:52 |

Each transition logged `option-select=GPT-6 Astra`, `modern-selected`, then
`selected` after the runtime read the actual Button and normalized its prefix.

The 1.0.8 installer was launched through the existing desktop Explorer shell
to match a normal user launch. It replaced active PID 94068 (1.0.7) with PID
102740 (1.0.8); only one ReasonKey runtime remained. At 19:03:06 both runtime
startup and installer completion confirmed 1.0.8/PID 102740. The installed EXE
hash matched dist/ReasonKey.exe and the explicitly configured INI's SHA-256
was unchanged across installation.

Setup SHA-256: `527f598d5b3368c4f2cc9dfc16a31ee98abf3e2933afdeab515a2e96893709b4`.

Diagnostics used the actual direct-install files through localhost's existing
administrative share because normal AppData reads from the Codex package were
redirected to an older LocalCache copy. No permissions or shares were changed.

Already-open picker, legacy picker, ChatGPT, Store update and uninstall gates
were not rerun. User input interrupted further UI testing; no public release
was performed. This is focused Codex selection and direct-upgrade evidence.

## 1.0.9 final installed build

Clean build and built-in runtime, installer, uninstaller-path and singleton
checks passed. Final setup SHA-256:
`e1e130589a509fcca2b55c7e3a8bf746be574e38ff6910cc02a0549e886d2000`.

On the same Codex package, ordinary Chat exposes its own stable
`Select ChatGPT model` Button and Instant/Medium/High/Pro scale. It requires
separate model-radio and effort verification. A Work composer remains Codex
even when the sidebar mode says ChatGPT.

Final installed runtime PID 16956 started at 19:41:08 after replacing PID
106212. Installed runtime hash matched dist/ReasonKey.exe; only one runtime
remained; the explicitly configured INI hash remained unchanged. Earlier
same-version reinstalls also confirmed replacement/startup. The installer now
handles a process exiting before ProcessWaitClose begins by checking existence
after waiting, rather than treating a zero wait return as failure.

All times below are local on 2026-09-05. These are actual `selected` records
after the runtime verified the resulting accessible state on the final build:

| Surface | Hotkey | Verified result | Time |
|---|---|---|---|
| Codex | F16 | 6 Astra Light | 19:41:26 |
| Codex | F17 | 6 Astra Medium | 19:41:30 |
| Codex | F19 | 6 Astra Max | 19:41:35 |
| Codex | F18 | 6 Astra High | 19:41:39 |
| Ordinary Chat | F16 | 5.6 Sol Instant | 19:44:35 |
| Ordinary Chat | F17 | 5.6 Sol Medium | 19:44:40 |
| Ordinary Chat | F19 | 5.6 Sol Pro | 19:44:44 |
| Ordinary Chat | F18 | 5.6 Sol High | 19:44:49 |
| Codex, compact popup already open | F17 | 6 Astra Medium | 19:45:39 |
| Codex, model radio list already open | F18 | 6 Astra High | 19:46:31 |

The last two checks used the actual Work/Codex composer while the sidebar
still said ChatGPT, confirming composer detection takes priority. Chat tests
used an empty draft and sent no messages. Chat Sol High and Codex Astra High
were restored. Each Chat transition confirmed the selected GPT-5.6 Sol radio
and exact independent effort; Codex verified the normalized actual Button.

Intermediate builds intermittently selected a wrong model or retained the old
effort. Final code verifies keyboard focus before input and bounds recovery
from an already-open popup; those intermediate failures are not passing tests.
Legacy Advanced/compact layouts, full MSIX/Store update, uninstall and the
remaining external release gates were not rerun. No public release was made.

## Final preset correction: Extra High

The user's subsequent correction changes Codex F19 from Max to Extra High.
F16/F17/F18 remain Light/Medium/High; independent Chat presets are unchanged.
The active direct-install INI was explicitly edited for this request, and the
source defaults, reference configuration and current documentation were aligned.

A clean rebuild passed. Updated setup SHA-256:
`44c609c8adeaa73780fb88d3eeea4805616a06cdb094e69204113ceb8ade1935`.
The installer replaced the runtime with PID 93064 at 19:57:56 and preserved
the newly configured INI hash. The installed EXE matched the rebuilt runtime,
and exactly one runtime remained. Real F19 selection verified
`6 Astra Extra High` at 19:58:18. Picker logic and Chat mapping were unchanged;
the affected F19 case was rerun rather than claiming a new full release matrix.
