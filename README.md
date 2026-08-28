# Codex Model Hotkeys

Fast, configurable keyboard shortcuts for selecting both the **model** and the
**reasoning effort** in the Codex Windows desktop app.

> Unofficial community utility. It is not made, endorsed, or supported by
> OpenAI. The official Windows app is documented in the
> [OpenAI documentation](https://learn.chatgpt.com/docs/windows/windows-app).

## Install in one click

[**Download CodexModelHotkeys-Setup.exe**](https://github.com/nauroman/codex-model-hotkeys/releases/latest/download/CodexModelHotkeys-Setup.exe)

Run the downloaded installer. It installs for the current Windows user, starts
immediately, and starts automatically when you sign in. AutoHotkey is bundled
in the compiled release and does not need to be installed separately.

Because the executable is currently unsigned, Windows SmartScreen may show a
warning. Use **More info → Run anyway** only if the publisher URL and checksum
match this repository. Every release includes a SHA-256 checksum.

If you downloaded the source ZIP or cloned the repository, double-click
[`Install.cmd`](Install.cmd). It verifies the published checksum before running
the latest installer.

## Default shortcuts

| Shortcut | Model | Reasoning effort |
|---|---|---|
| `F16` | GPT-5.6 Luna | High |
| `F17` | GPT-5.6 Sol | Light |
| `F18` | GPT-5.6 Sol | Extra High (`xhigh`) |
| `F19` | GPT-5.6 Sol | Max |
| `Ctrl+Alt+Wheel Up/Down` | Cycles through the same four presets | Included in each preset |

The shortcuts are active only while a Codex window is active. They do not
capture these keys globally in other applications.

## Customize presets

Right-click the **Codex Model Hotkeys** tray icon and choose
**Open presets.ini**. Change any hotkey, model, or effort, save, then choose
**Reload** from the tray menu.

Supported model names are `Luna`, `Terra`, and `Sol`. Supported effort names
are `Light`, `Medium`, `High`, `Extra High`, `Max`, and `Ultra`, subject to what
the selected model and your Codex account expose.

AutoHotkey hotkey syntax is used. For example:

```ini
[Preset1]
Hotkey=^!1
Name=Luna High
Model=Luna
Effort=High
```

`^!1` means `Ctrl+Alt+1`.

## How it works

Codex can show either the compact Power slider or the expanded Advanced picker.
The utility detects both states. When necessary, it enters Advanced mode, opens
the Model and Effort flyout menus through their keyboard-accessible UI
Automation controls, selects both values, and verifies the final picker button.
It does not edit Codex files or send API requests.

See [How it works](docs/HOW_IT_WORKS.md) for the state machine and selector
details.

## Requirements and compatibility

- Windows 10 or Windows 11
- Codex/ChatGPT Windows desktop app
- English UI labels in the current release

Version 1.0.0 was validated against desktop package
`OpenAI.Codex_26.825.4187.0_x64__2p2nqsd0c76g0`. UI Automation labels are not a
public compatibility contract, so future Codex updates can require selector
updates.

## Logs and troubleshooting

Right-click the tray icon and choose **Open log**. The log is stored at:

```text
%LOCALAPPDATA%\CodexModelHotkeys\CodexModelHotkeys.log
```

See [Troubleshooting](docs/TROUBLESHOOTING.md) before opening an issue.

## Uninstall

Open **Windows Settings → Apps → Installed apps**, find
**Codex Model Hotkeys**, and choose **Uninstall**.

## Development

The source is AutoHotkey v2 and uses the MIT-licensed UIA-v2 library. See
[Development](docs/DEVELOPMENT.md) for layout, build, validation, and release
instructions.

## License

MIT. See [LICENSE](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md).
