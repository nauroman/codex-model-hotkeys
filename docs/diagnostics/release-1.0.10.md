# ReasonKey 1.0.10 release evidence

Validated on 2026-09-08/09 (America/Vancouver), against installed
`OpenAI.Codex_26.903.8094.0_x64__2p2nqsd0c76g0`. Tests used the final compiled
runtime, built from the 1.0.10 working tree based on `de8ee9c`; release commit
and remote outcomes are recorded below after publication.

## Build and artifacts

- `scripts/Build.ps1 -Clean` passed, including compiled runtime/installer
  validation, uninstaller path guards and the isolated copied-path singleton.
- Final setup SHA-256:
  `9bd2081d16667af9a745233983821977692ca776910304e5976febb8347ec482`.
- Direct runtime SHA-256:
  `c6d6fbb433b53cf00d2751925396eae4ddabb53557488e81c687793fff9759b8`.
- Store package `ReasonKey_1.0.10.0_x64.msix` built and unpacked successfully.
  Metadata confirms Microsoft Store submission, unsigned, x64, and version
  1.0.10.0. Package SHA-256:
  `cf888c2d20643eaaa6b91a58b83f088dc75a307117466eb106c667f169a59264`.
- The manifest-adjusted packaged runtime passed `--validate` with exit 0.
  Its SHA-256 is
  `afd8b9110838ccf9c5d8d8c4196c0ecdc2e0a4b93f00fc94ed5ec95bef11e667`.
- Native Store helper build/self-test passed. Its SHA-256 is
  `1f3463fa82df893bc8e263a7b936f013cb789b02f4ce27dc3febcb46d21bdf4d`.

## Actual picker results

Times below are local on September 8. A `selected` record follows the runtime's
read of the final accessible Button; snapshots also confirmed the final UI.
No diagnostic messages were submitted to Codex or ChatGPT.

| Surface / starting state | Verified results |
|---|---|
| ChatGPT Work, picker closed | F16 Astra Light 23:43:52; F17 Medium 23:44:04; F18 High 23:44:21; F19 Extra High 23:44:37 |
| Work, compact picker already open | F17 Astra Medium 23:46:00; trigger was the new `Select effort` Button |
| Work, model radio list already open | F19 Astra Extra High 23:50:32 |
| Codex, picker closed | F16 Astra Light 23:51:34; F18 High 23:51:52; F19 Extra High 23:51:58; F17 Medium 23:52:04 |
| Ordinary Chat, picker closed | F16 Sol Instant 23:53:55; F17 Medium 23:54:11; F18 High 23:54:18; F19 Pro 23:54:25 |
| Ordinary Chat, compact picker already open | F18 Sol High 23:54:51 |
| Temporary additional presets | Astra Max 23:56:24; switch back to Sol Medium 23:57:15; restore Astra Extra High 23:57:57 |

The ordinary Chat model radio list exposed Latest, GPT-5.6 Sol and GPT-5.5,
without Astra. Work correctly used the Codex path despite the ChatGPT sidebar.
Ordinary Chat's accessible trigger is `Select ChatGPT model`; its visible
descendant labels and selected model radio state were verified by the runtime.

Additional boundary tests requested Astra Ultra and Luna Ultra. Both remained
at their model's Max value and logged `failed`, with no false `selected` success
for Ultra. Thus Ultra selection is **not verified** on this client. The four
requested Astra levels all passed. An invalid temporary hotkey logged
`invalid-hotkey=InvalidKeyName error=Invalid key name.` The temporary INI was
restored byte-for-byte afterward.

F16 in File Explorer caused no picker action or new runtime log entry (the log
remained 38,664 bytes). The original current task was restored to Codex with
`GPT-6 Astra Medium`; the empty Work draft was returned to Extra High.

## Installation, configuration and screenshot

The user's active Store INI still contained older Luna/Sol presets. For this
explicit update request, the first four local presets were changed to Astra
Light/Medium/High/Extra High, preserving F16-F19 and the ordinary Chat mapping.
This deliberate user configuration change is separate from installer policy:
upgrades continue to preserve existing INIs.

Codex's MSIX redirects terminal-launched direct installation into its
`LocalCache/Local/ReasonKey` directory. Final setup was tested there, with
the active INI's SHA-256 unchanged and new 1.0.10 startup/PID evidence.
The real direct-install executable and reference were also refreshed through
the existing localhost administrative share; no permissions or shares changed.
Both real and redirected direct EXEs matched the final runtime hash. This
does not establish a new unredirected Explorer-installer test.

Actual cross-channel launches were checked in both orders using the installed
public Store 1.0.9.0 and final direct 1.0.10 runtime. Exactly one runtime remained
in each order. A public Store launch recorded its real package LocalState path
and `store-update result=no-update`; that is not an actual delivered upgrade.
The final direct 1.0.10 runtime was restored. Unrelated `arrowkeys.ahk`
remained running throughout.

The real 1.0.10 Store-preview Quick Start was captured and visually inspected;
all text and buttons fit. The 1600x900 listing screenshot SHA-256 is
`73ee8a5401e82cb21b62783e70f76c5fa2e4c5bbfd27c09474b13d13bb24b85f`.

## Unverified gates

- Legacy desktop picker: an older client was not available.
- Local WACK and trusted development-package installation: the session is
  non-elevated and the required certificate/WACK flow requires elevation.
- Fresh-profile installation, destructive uninstall/removal, Store 1.0.10
  first launch/startup and actual delivered update/restart remain unverified.
- Upload validation, GitHub CI and source checks do not establish those gates.

## Remote publication

Partner Center accepted the final package as **Validated** in Submission 5
(`1152921505701842633`). Updated listing text, release notes and the replacement
1.0.10 screenshot/caption were saved. Final publication/submission outcomes
will be recorded separately after dispatch.
