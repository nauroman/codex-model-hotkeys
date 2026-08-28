# Security policy

Report security issues privately through GitHub's **Report a vulnerability**
feature rather than a public issue.

The runtime uses local Windows UI Automation and does not use an OpenAI API key,
read task messages, or send telemetry. The release downloader contacts GitHub
and verifies the setup executable against the release SHA-256 file.

Do not publish logs that contain private filesystem paths or other sensitive
environment details without reviewing them first.
