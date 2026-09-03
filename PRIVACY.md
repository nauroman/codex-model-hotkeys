# Privacy policy

Effective date: September 2, 2026

ReasonKey does not collect, transmit, sell, or share personal data.
The runtime does not include telemetry, advertising, analytics, an account
system, or an OpenAI network client.

## Microsoft Store update requests

The Microsoft Store package asks the Windows Microsoft Store service whether a
newer ReasonKey package is available whenever the app starts. If Windows
permits silent app updates, it may download and install that package through
the Store. Microsoft processes the normal device, account, network, and Store
service information required for Microsoft Store updates under Microsoft's own
terms and privacy statement; ReasonKey does not receive or store that account
or device information.

The direct EXE version does not perform this Store update check. Neither
version sends telemetry, configuration, logs, shortcuts, Codex/ChatGPT content,
or personal data to Rotorlash Labs.

## Local data

The application stores only the files needed to operate on the current Windows
account:

- `presets.ini`, containing the user's shortcut configuration;
- `presets-reference.ini`, containing the configuration guide;
- `ReasonKey.log`, containing local diagnostic events such as requested
  and selected model preset labels and Store update outcomes.

The Microsoft Store package stores these files in its per-user package
`LocalState` directory. The direct installer stores them under
`%LOCALAPPDATA%\ReasonKey`. These files are not sent anywhere by the
application.

## Interaction with Codex and ChatGPT

The application uses Windows UI Automation only while the Codex/ChatGPT desktop
app window is active and only to locate and operate the model and effort picker
in its Codex or ChatGPT Chat composer. It does not read task messages, account
credentials, API keys, or conversation content. It does not modify Codex or ChatGPT files
or make OpenAI API requests.

## User control

Users can inspect or delete the local configuration and log files at any time.
Uninstalling the Microsoft Store package removes its package-owned local data.
The direct installer provides an uninstaller in Windows Installed Apps.

## Contact

Questions or privacy concerns can be reported through the repository's
[security policy](SECURITY.md) or issue tracker:

https://github.com/nauroman/codex-model-hotkeys

ReasonKey is an unofficial community utility. It is not made,
endorsed, or supported by OpenAI.
