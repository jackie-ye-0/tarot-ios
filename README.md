# Local iOS coding harness

A local-first native Swift/SwiftUI tarot app. The foundation slice (#7) opens on five face-down cards, reveals the selected daily card, then shows a basic Today with its core interpretation. The card and orientation are fixed by the installation seed and local date, and saved on-device with SwiftData. Reopening on the same date goes straight to Today.

The starter library contains six cards in both orientations with original draft writing. No account, network, AI, analytics or paid service is used. Content needs editorial review before release to real users. Later issues add Welcome, the full library, ritual motion, richer Today, day rollover, Ask and History.

## Setup

Use macOS with full Xcode, completed first-launch setup, the iOS SDK, an available iPhone simulator/runtime, Git and Python 3. No package manager, project generator, cloud account, paid service or additional SDK is required. Command Line Tools alone cannot build iOS apps. This is source-portable between appropriately equipped Macs, not a bundled toolchain or a Linux/Windows iOS build environment.

Open `HarnessShell.xcodeproj` in Xcode if you prefer its interface. The shared scheme is `HarnessShell`. The app targets iPhone with iOS 17 or newer; actual validated toolchain/runtime versions are recorded in the verification report. Simulator verification does not need signing or an Apple Developer subscription.

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
| `./scripts/harness build` | Build the app for that simulator |
| `./scripts/harness launch` | Build, boot if needed, install, launch and capture a simulator image |
| `./scripts/harness test` | Run unit and UI tests; export result summary and retained attachments |
| `./scripts/harness check` | Run command-contract tests, then the full iOS test/evidence loop |
| `./scripts/harness evidence` | Print the latest run summary, including failed runs |
| `python3 -m unittest discover -s tests -v` | Run command-contract tests without Xcode |

Use `--device <UDID>` on doctor/build/launch/test/check to choose an available iPhone explicitly. Otherwise the runner prefers a booted iPhone, then sorts available devices by runtime/name/UDID. This is deterministic selection, not a claim to select the newest SDK. See a doctor's `devices.log` for choices. Xcode reports incompatible destinations in the retained build/test log; select a compatible one explicitly.

Use `./scripts/harness evidence --run ".harness/runs/<run-id>"` for a particular run. Every invocation has a distinct timestamp/UUID directory containing `summary.txt`, `summary.json`, raw logs, command arguments, toolchain/device metadata once prerequisites succeed, and Git head/dirty-state information. Build output lives in that run's `DerivedData/` with `Build.xcresult` for builds/launches; tests retain `Tests.xcresult` and exported `attachments/`. A successful test requires at least four executed tests, all passing with no skips, plus an exported image. Inspect the image visually; its existence does not prove layout quality. Launch images are immediate diagnostics and may capture the startup screen before rendering completes. Use the UI test attachment taken after successful interaction for visual verification.

The launch command uses `simctl`; open the Simulator app yourself to watch the device. It installs only the app in the selected simulator and leaves that device running. Run directories can be large: delete obsolete directories under `.harness/runs/` when finished, retaining evidence you still need. Nothing is automatically uploaded or cleaned. Copy a complete run directory to preserve/share its evidence; review local paths and logs before sharing. Results are ignored by Git, so a fresh clone contains code/docs, not another Mac's results.

### Screenshot names and design comparison

After `test` or `check`, open `<run>/design-comparison.html` in a browser. `./scripts/harness evidence` prints its full path, each matched or missing reference, and captures without a reference. The page places the design reference on the left and the built screen on the right, with both filenames visible. Missing main captures remain visible beside their references. References are copied into the run, so the page also works when the complete run folder is moved.

Set each UI test's kept `XCTAttachment.name` to the reference's filename without its extension, such as `04-today` or `02-draw-card-chosen`. The harness reads Xcode's attachment manifest and exports `screenshots/04-today.png`, preserving spaces and the original image format. Raw exports and their manifest remain in `attachments/`. A repeated screenshot name anywhere in a run fails verification and names the duplicate; case-only differences also fail to avoid overwriting files on macOS.

Reserve `--` for capture variants: `04-today--largest-text`, `02-draw--reduce-motion`, or `09-reading--bottom`. Variants appear under their screen and never satisfy its main screenshot requirement. For scrolling screens, use the unsuffixed name for the top and `--bottom` for the bottom. Reference states such as `04-today-first-day` are separate main screenshots, because each has its own reference image. The `00-flow-map.png` diagram is linked as context and excluded from screen coverage.

Missing screens are reported without failing an ordinary run, so the current technical shell can pass while product screens are unbuilt. For the final full-screen pass, run:

```sh
./scripts/harness check --require-all-screenshots
```

This option also works with `test` and fails if any screen reference is missing its main capture, or if no screen references are available. It does not weaken the existing test-count, failure, skip or screenshot requirements. Coverage proves a named capture exists; follow the [design check](docs/design.md#12-design-check) to assess its contents and accessibility. Issue #7 captures `02-draw`, `02-draw-card-chosen`, `03-reveal` and `04-today`, plus large-text and Reduce Motion variants. The remaining screen references belong to later issues.

## Structure and limitations

- [Project documents](docs/README.md): research, PRDs and harness guidance in one place.
- [Architecture](docs/architecture.md): targets, commands and evidence boundary.
- [Decisions and scope](docs/decisions.md): approved setup and unresolved product choices.
- [Workflow](docs/workflow.md): daily loop, harness evolution and future synthetic AI tests.
- [Standalone acceptance](docs/standalone-acceptance.md): bounded independent Codex exercise.
- [Learning notes](LEARNING.md): concepts introduced here.
- [Verification](docs/verification.md): observed checks and pending gates.

No app icon, AI/provider integration, hosted CI, device signing or App Store delivery is implemented. Valuable free-text data is not collected in this foundation slice; export and deletion arrive with Settings. Real-device behaviour and VoiceOver reading order still need a manual pass.

## Debug test configuration

Only Debug builds, with `--test-mode`, read these launch arguments:

- `--test-date <ISO-8601 instant>` and `--test-time-zone <IANA zone>` fix the clock and date key.
- `--test-seed <string>` supplies the seed when the store has no installation identity.
- `--test-memory-store` starts with an empty temporary SwiftData store on each launch.
- `--test-store-id <UUID>` uses an isolated on-device test store that survives process relaunch. UI tests use a new UUID per test; synthetic stores remain in the simulator app container until it is removed.
- `--test-largest-text` and `--test-reduce-motion` set the largest SwiftUI Dynamic Type size and disable animations in the root transaction, without changing simulator settings. The app also honours the real system Reduce Motion setting.
- `--test-storage-open-failure` makes the first store-opening attempt fail so UI tests can verify the error and retry path.

Release builds ignore all these arguments. Normal launches always use the saved installation seed and on-device store. Storage failures surface a retry, never a silent reset or temporary substitute.

`./scripts/harness check` also runs the design-role source guard from `scripts/design_rules.py`. Outside `DesignSystem.swift`, this lexical check rejects the raw colour, font, rounded-shape and corner-radius vocabulary, plus unqualified system colour and text-style values. It does not parse Swift, follow aliases or inspect code inside string interpolation, so XCTest accessibility audits and visual comparison remain required.

Bundled font provenance and licences are in [Fonts](HarnessShell/Resources/Fonts/README.md). See [foundation verification](docs/foundation-verification.md) for the #7 evidence and accepted reference differences.
