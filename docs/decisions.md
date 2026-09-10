# Initial plan and decision record

Date: 10 September 2026. Status: approved environment scope; implementation verification in progress.

## Approved

Build a local, portable AI coding harness for a new iOS-only tarot-reading app. Future AI may help users interpret cards in their own context. This task sets up the developer environment only.

Use native Swift/SwiftUI and one technical counter screen to verify the build, launch, interaction, test and evidence loop. Use Apple's tools and existing shell/Python. Check in the Xcode project; avoid project generators and package dependencies. Codex is the only client to verify initially. Firstmate remains optional. A private GitHub repository and feature-branch PR are authorised; merging is not.

Policy is `no-mistakes-prod-only`, yolo off. This change is internal developer tooling and a technical fixture, so delivery is direct PR. The harness must work without no-mistakes, a shared daemon or a supervisor environment. Future product work must reassess its scope and delivery gate.

## Plan

1. Inventory the empty isolated repo and available tools.
2. Add static project, technical shell, meaningful unit/UI tests and local commands.
3. Exercise command contracts and missing-prerequisite failures while Xcode installs.
4. With Xcode/runtime ready, consult installed tool help, build, launch, run a deliberate failing test in a disposable copy, restore and pass the full suite. Export and visually inspect passing-test evidence.
5. Run the bounded independent standalone Codex scenario in a disposable copy. Review the transcript, diff and evidence independently.
6. Record actual results/limitations, commit coherent changes, push the feature branch and open a private PR. Never merge here.

## Consequences

Native tooling avoids maintaining a generator or cross-platform framework. A static project is easy to open and portable between Macs but needs ordinary Xcode project edits when adding files/targets. Per-command `DEVELOPER_DIR` avoids changing other projects' tool selection. Separate run output costs disk space but keeps failures and comparisons auditable. No hosted CI means there is no remote verification gate established by this setup.

## Explicitly excluded and unresolved

Do not implement tarot cards, reading algorithms, accounts, persistence, networking, AI providers, payments, production UI or App Store delivery.

Future human decisions include intended audience and reading experience; card content/licensing; interpretation safety/tone; privacy and retention; local/on-device versus hosted models; provider/model, live data exposure and cost; offline behaviour; semantic evaluation criteria; monetisation; signing/distribution; cloud sync and accessibility/product design. No default provider or paid calls are implied by this harness.
