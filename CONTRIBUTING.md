# Contributing

Issues and pull requests are welcome. Start with [AGENTS.md](AGENTS.md), the
[product core](docs/product-spec.md), affected canonical owners and the
[source map](docs/PROJECT_CONTEXT.md).

For picker failures, include the app/Windows version, display language, starting
picker view, expected and actual selection, relevant reviewed log lines and a
screenshot of the open picker. Exclude private task content, tokens, account
identifiers and other sensitive data.

Update the affected owner and user-facing views when a confirmed contract
changes. Keep historical observations separate from current implementation;
report contradictions through the [decision register](docs/product-spec/open-decisions.md).

Run validation proportional to the change as described in
[Development](docs/DEVELOPMENT.md). Documentation changes use
scripts/Test-Documentation.ps1 and git diff --check. Runtime/selector changes
require the affected real-window matrix; every release requires the clean build
and complete applicable release gates. State what was not tested.
