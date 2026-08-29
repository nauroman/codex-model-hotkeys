# Security policy

Report security issues privately through GitHub's **Report a vulnerability**
feature rather than a public issue.

The runtime uses local Windows UI Automation only for the visible model/effort
picker in Codex and ChatGPT Chat. It does not use an OpenAI API key, read task
or conversation messages, or send telemetry. The release downloader contacts GitHub
and verifies the setup executable against the release SHA-256 file.

See [PRIVACY.md](PRIVACY.md) for the complete local-data and network behavior
statement used by the Microsoft Store listing.

Do not publish logs that contain private filesystem paths or other sensitive
environment details without reviewing them first.
