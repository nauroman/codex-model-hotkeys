# Privacy policy

Effective date: August 29, 2026

ReasonKey does not collect, transmit, sell, or share personal data.
The runtime does not include telemetry, advertising, analytics, an account
system, or network communication.

## Local data

The application stores only the files needed to operate on the current Windows
account:

- `presets.ini`, containing the user's shortcut configuration;
- `presets-reference.ini`, containing the configuration guide;
- `ReasonKey.log`, containing local diagnostic events such as requested
  and selected model preset labels.

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
