# Local iOS coding harness

A native Swift/SwiftUI technical shell and local feedback loop for a future iOS tarot app. The screen increments an in-memory count; it has no tarot or AI features. Codex is the initial client under verification. Firstmate is optional and not needed by any repository command.

**Status:** native build/launch, 16 command-contract tests, four real XCTest tests and passing-test screenshot inspection are verified. Independent standalone Codex acceptance is pending. See [verification report](docs/verification.md) for actual evidence rather than inferring readiness from this scaffold.

## Setup

Use macOS with full Xcode, completed first-launch setup, the iOS SDK, an available iPhone simulator/runtime, Git and Python 3. No package manager, project generator, cloud account, paid service or additional SDK is required. Command Line Tools alone cannot build iOS apps. This is source-portable between appropriately equipped Macs, not a bundled toolchain or a Linux/Windows iOS build environment.

Open `HarnessShell.xcodeproj` in Xcode if you prefer its interface. The shared scheme is `HarnessShell`. The fixture targets iPhone with iOS 17 or newer; actual validated toolchain/runtime versions are recorded in the verification report. Simulator verification does not need signing or an Apple Developer subscription.

If Xcode is not the machine-wide selection, prefix each command with your installed developer directory, for example:

```sh
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" ./scripts/harness doctor
```

This selects tools for that process only. Finish installation, licences and runtime setup yourself using Xcode if diagnostics identify a missing prerequisite. Commands do not install software or change global settings.

## Commands

Run from the repository root. Checkout paths containing spaces are supported.

| Command | Purpose |
| --- | --- |
| `./scripts/harness doctor` | Probe Xcode/tools/SDKs; discover and record an available iPhone simulator |
| `./scripts/harness build` | Build the technical app for that simulator |
| `./scripts/harness launch` | Build, boot if needed, install, launch and capture a simulator image |
| `./scripts/harness test` | Run unit and UI tests; export result summary and retained attachments |
| `./scripts/harness check` | Run command-contract tests, then the full iOS test/evidence loop |
| `./scripts/harness evidence` | Print the latest run summary, including failed runs |
| `python3 -m unittest discover -s tests -v` | Run command-contract tests without Xcode |

Use `--device <UDID>` on doctor/build/launch/test/check to choose an available iPhone explicitly. Otherwise the runner prefers a booted iPhone, then sorts available devices by runtime/name/UDID. This is deterministic selection, not a claim to select the newest SDK. See a doctor's `devices.log` for choices. Xcode reports incompatible destinations in the retained build/test log; select a compatible one explicitly.

Use `./scripts/harness evidence --run ".harness/runs/<run-id>"` for a particular run. Every invocation has a distinct timestamp/UUID directory containing `summary.txt`, `summary.json`, raw logs, command arguments, toolchain/device metadata once prerequisites succeed, and Git head/dirty-state information. Build output lives in that run's `DerivedData/` with `Build.xcresult` for builds/launches; tests retain `Tests.xcresult` and exported `attachments/`. A successful test requires at least four executed tests, all passing with no skips, plus an exported image. Inspect the image visually; its existence does not prove layout quality. Launch images are immediate diagnostics and may capture the startup screen before rendering completes. Use the UI test attachment taken after successful interaction for visual verification.

The launch command uses `simctl`; open the Simulator app yourself to watch the device. It installs only the technical fixture in the selected simulator and leaves that device running. Run directories can be large: delete obsolete directories under `.harness/runs/` when finished, retaining evidence you still need. Nothing is automatically uploaded or cleaned. Copy a complete run directory to preserve/share its evidence; review local paths and logs before sharing. Results are ignored by Git, so a fresh clone contains code/docs, not another Mac's results.

## Structure and limitations

- [Architecture](docs/architecture.md): targets, commands and evidence boundary.
- [Decisions and scope](docs/decisions.md): approved setup and unresolved product choices.
- [Workflow](docs/workflow.md): daily loop, harness evolution and future synthetic AI tests.
- [Standalone acceptance](docs/standalone-acceptance.md): bounded independent Codex exercise.
- [Learning notes](LEARNING.md): concepts introduced here.
- [Verification](docs/verification.md): observed checks and pending gates.

No app icon, production interface, persistence/export of app data, AI/provider integration, CI, remote enforcement, device signing or App Store delivery is implemented. The shell deliberately has no valuable personal data. Real-device behaviour and accessibility beyond this fixture need later validation. The optional `CLAUDE.md` pointer shares guidance only; Claude and other clients are not verified by this setup. Prose instructions cannot enforce compliance or guarantee future agent behaviour.
