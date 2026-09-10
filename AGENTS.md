# Working in this repository

This is an iOS harness setup with a disposable SwiftUI technical shell. Product features are not approved. Read [scope and decisions](docs/decisions.md) before changing scope.

- Start with [README](README.md) for prerequisites and commands, then [architecture](docs/architecture.md) when changing code or tooling.
- Run `./scripts/harness doctor` before iOS work. Use per-command `DEVELOPER_DIR` if needed. Never auto-install tools or change machine settings.
- Run `./scripts/harness check` after changes; inspect `./scripts/harness evidence` and the exported test screenshot. Non-zero, zero-test, skipped-test and missing-evidence runs do not establish verification. Report unavailable prerequisites precisely.
- For command changes, first run `python3 -m unittest discover -s tests -v`. These fake-tool tests do not verify iOS.
- Keep build output in ignored `.harness/`. Use synthetic data only; no credentials, live model calls or new services. No tarot logic, accounts, storage or networking in this setup.
- [Workflow](docs/workflow.md) defines friction capture, verification and decision boundaries. Guidance is advisory; command outcomes and inspected evidence establish what actually ran.
- Git policy: `no-mistakes-prod-only`, yolo off. Internal tooling/technical fixture work uses direct PRs; product work requires reassessing scope and the applicable gate. No no-mistakes installation is needed to run this harness. Obtain approval before pushing or publishing unless the task already authorises it. Never merge without approval.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
