# Local iOS coding harness

A local-first native Swift/SwiftUI tarot app. First open shows Welcome with its entertainment-and-reflection disclaimer and one “Draw my first card” button. Completing Welcome is saved on-device; later launches skip it. The daily-card flow (#7, #9) opens on five face-down cards, reveals the selected daily card, then shows Today with its core interpretation, colour, object, best hour, three area scores and distinct area readings. Tapping its thumbnail reopens Reveal with a way back to Today. The card and orientation are fixed by the installation seed and local date, and saved on-device with SwiftData. Reopening on the same date goes straight to Today once the card is drawn. Today and Ask have labelled tabs. Ask lets you choose an area, write or pick a question, draw three cards and read a saved, on-device interpretation.

The starter reading library contains six cards in both orientations with original draft writing, question-position meanings, three area lenses, suggestions and reflection questions. The separate artwork catalogue contains all 78 named card identities and distinct code-drawn faces, ready for the remaining interpretations in #24–#26. No account, network, AI, analytics or paid service is used. Content needs editorial review before release to real users. Draw shuffles into a fan and Reveal turns the card as the screen warms to dawn; both remain interruptible and honour Reduce Motion. Local-day changes route to Draw, or restore Today when that date already has a saved card. Recent card identities trigger up to three salted retries, then the last result is accepted. This bounded rule cannot guarantee fourteen repeat-free days with the six-card starter. Later issues add the full interpretation library, fuller Ask features and History.

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
| `./scripts/harness doctor` | Probe Xcode/tools/SDKs; create or reuse and record this checkout's iPhone simulator |
| `./scripts/harness build` | Build the app for that simulator |
| `./scripts/harness launch` | Build, boot if needed, install, launch and capture a simulator image |
| `./scripts/harness test` | Run unit and UI tests; export result summary and retained attachments |
| `./scripts/harness check` | Run command-contract tests, then the full iOS test/evidence loop |
| `./scripts/harness evidence` | Print the latest run summary, including failed runs |
| `python3 -m unittest discover -s tests -v` | Run command-contract tests without Xcode |

Use `--device <UDID>` on doctor/build/launch/test/check to choose an available iPhone explicitly. Otherwise the runner creates and reuses `iPhone Tarot Harness <checkout-path hash>`, dedicated to this checkout's resolved path. On first use it takes the model/runtime of an available iPhone sorted by runtime/name/UDID, creating an empty device without copying its data. It never selects an arbitrary booted device. Moving a checkout gives it a new simulator; old devices are left in place. See a doctor's `devices.log` for choices. Xcode reports incompatible destinations in the retained build/test log; select a compatible one explicitly.

Device creation and the build/launch/test phase queue across checkouts on `/tmp/tarot-ios-harness-simulator.lock`, using Python's standard-library file locking. No caller flags or outer lock are needed, including for automated review. The lock path differs from the legacy `/tmp/tarot-ios-harness.lock`, so existing `lockf` wrappers can remain during migration. Command-contract tests run before the lock and use isolated fake locks. `summary.json` records lock request/acquire/release times. The harness never deletes, erases or shuts down simulators; leave the shared lock file in place while commands may be running.

Use `./scripts/harness evidence --run ".harness/runs/<run-id>"` for a particular run. Every invocation has a distinct timestamp/UUID directory containing `summary.txt`, `summary.json`, raw logs, command arguments, toolchain/device metadata once prerequisites succeed, and Git head/dirty-state information. Build output lives in that run's `DerivedData/` with `Build.xcresult` for builds/launches; tests retain `Tests.xcresult` and exported `attachments/`. A successful test requires at least four executed tests, all passing with no skips, plus an exported image. Inspect the image visually; its existence does not prove layout quality. Launch images are immediate diagnostics and may capture the startup screen before rendering completes. Use the UI test attachment taken after successful interaction for visual verification.

The repository-root `.no-mistakes.yaml` declares `no_ci: true`; once on the trusted default branch, this lets no-mistakes treat a PR with no registered remote checks as ready while local harness verification remains required.

The launch command uses `simctl`; open the Simulator app yourself to watch the device. It installs only the app in the selected simulator and leaves that device running. Run directories can be large: delete obsolete directories under `.harness/runs/` when finished, retaining evidence you still need. Nothing is automatically uploaded or cleaned. Copy a complete run directory to preserve/share its evidence; review local paths and logs before sharing. Results are ignored by Git, so a fresh clone contains code/docs, not another Mac's results.

### Screenshot names and design comparison

After `test` or `check`, open `<run>/design-comparison.html` in a browser. `./scripts/harness evidence` prints its full path, each matched or missing reference, and captures without a reference. The page places the design reference on the left and the built screen on the right, with both filenames visible. Missing main captures remain visible beside their references. References are copied into the run, so the page also works when the complete run folder is moved.

Set each UI test's kept `XCTAttachment.name` to the reference's filename without its extension, such as `04-today` or `02-draw-card-chosen`. The harness reads Xcode's attachment manifest and exports `screenshots/04-today.png`, preserving spaces and the original image format. Raw exports and their manifest remain in `attachments/`. A repeated screenshot name anywhere in a run fails verification and names the duplicate; case-only differences also fail to avoid overwriting files on macOS.

Reserve `--` for capture variants: `04-today--largest-text`, `02-draw--reduce-motion`, or `09-reading--bottom`. Variants appear under their screen and never satisfy its main screenshot requirement. For scrolling screens, use the unsuffixed name for the top and `--bottom` for the bottom. Reference states such as `04-today-first-day` are separate main screenshots, because each has its own reference image. The `00-flow-map.png` diagram is linked as context and excluded from screen coverage.

Missing screens are reported without failing an ordinary run, so the current app can pass while later product screens are unbuilt. For the final full-screen pass, run:

```sh
./scripts/harness check --require-all-screenshots
```

This option also works with `test` and fails if any screen reference is missing its main capture, or if no screen references are available. It does not weaken the existing test-count, failure, skip or screenshot requirements. Coverage proves a named capture exists; follow the [design check](docs/design.md#12-design-check) to assess its contents and accessibility. The Welcome tests capture `01-welcome`, plus large-text, Reduce Motion and save-failure variants. The daily-card tests capture `02-draw`, `02-draw-card-chosen`, `03-reveal` and `04-today`, plus large-text and Reduce Motion variants. Full Today adds bottom-of-scroll and reopened-Reveal captures. Issue #13 also captures `05-ask`, both `06-composer` states, both `08-three-card-pick` states and `09-reading`, with largest-text and pick Reduce Motion variants. The reference viewport assertions use the 390 × 844 point iPhone 17e simulator. The remaining screen references belong to later issues.

## Structure and limitations

- [Project documents](docs/README.md): research, PRDs and harness guidance in one place.
- [Architecture](docs/architecture.md): targets, commands and evidence boundary.
- [Decisions and scope](docs/decisions.md): approved setup and unresolved product choices.
- [Workflow](docs/workflow.md): daily loop, harness evolution and future synthetic AI tests.
- [Standalone acceptance](docs/standalone-acceptance.md): bounded independent Codex exercise.
- [Learning notes](LEARNING.md): concepts introduced here.
- [Verification](docs/verification.md): observed checks and pending gates.

No app icon, AI/provider integration, hosted CI, device signing or App Store delivery is implemented. Completed questions and readings are saved on this phone; unfinished questions and picks currently stay only in memory. Export and deletion arrive with their assigned later tickets. This development slice is not ready for valuable personal data. Real-device behaviour and VoiceOver reading order still need a manual pass.

## Debug test configuration

Only Debug builds, with `--test-mode`, read these launch arguments. This mode also exposes the scroll layout’s actual safe-area viewport as accessibility test metadata; ordinary launches retain their normal accessibility values:

- `--test-date <ISO-8601 instant>` and `--test-time-zone <IANA zone>` fix the clock and date key.
- `--test-seed <string>` supplies the seed when the store has no installation identity.
- `--test-memory-store` starts with an empty temporary SwiftData store on each launch.
- `--test-welcome-completed` preloads a completed Welcome for tests of later screens. Omit it to test first open; completion otherwise persists through the real welcome action in an isolated disk store.
- `--test-welcome-save-failure` fails the first attempt to save Welcome completion, then lets the retry succeed.
- `--test-store-id <UUID>` uses an isolated on-device test store that survives process relaunch. UI tests use a new UUID per test; synthetic stores remain in the simulator app container until it is removed.
- `--test-largest-text` sets the largest SwiftUI Dynamic Type size. `--test-reduce-motion` removes all animations and shows the final ritual states on first paint, without changing simulator settings. The app also honours the real system Reduce Motion setting.
- `--test-disable-animations` independently switches animations off for deterministic UI checks. Motion-specific tests leave it off.
- `--test-hold-shuffle` holds the first wash phase for a deterministic interruption test. Tapping any card still resolves it immediately; Reduce Motion and animation-off bypass the hold entirely. This avoids racing XCTest’s automatic animation-idle wait.
- `--test-earlier-snapshot` preloads a synthetic version 1 draw without the new daily fields, for compatibility evidence.
- `--test-revised-content` supplies a different synthetic library to prove that a saved day survives an app content update.
- `--test-random-indices <comma-separated non-negative integers>` fixes the spread source. Values cycle and are reduced into each requested range; each pick consumes a card index from the remaining deck, then an orientation (0 upright, 1 reversed).
- `--test-open-saved-reading` opens the latest persisted reading for the relaunch test, without composing it again; this is a test-only entry until History is built.
- `--test-storage-open-failure` makes the first store-opening attempt fail so UI tests can verify the error and retry path.
- `--test-card-faces` opens a Debug-only proof gallery of all 78 faces in upright/reversed pairs. `--test-card-sizes` opens representative Major and suit faces at Reveal (214), Today (120), spread (84) and thumbnail (36) point widths. Neither changes the reading library or saves a draw.
- `--test-controls` adds a Debug-only test menu for advancing the configured clock to the next local midnight, arming a date advance while backgrounded, and switching Sydney/Honolulu. Clock changes emit the same notifications the app observes in production; background advancement waits for the real foreground lifecycle to refresh. Ordinary design captures omit this menu. No simulator setting is changed.

In Debug test mode, the Draw title and Reveal card also expose a `settled` accessibility value after SwiftUI reports that their animations have been removed. UI audits and captures wait on this value; it does not add visible test controls.

Release builds ignore all these arguments. Normal launches always use the saved installation seed and on-device store. Storage failures surface a retry, never a silent reset or temporary substitute.

Debug test mode also exposes an empty, non-interactive `test-safe-viewport` container sized from the window's actual safe area. It is not a VoiceOver content element. UI geometry checks and the overlapping accessibility audit use its frame instead of guessed screen insets; a missing marker fails the test. The marker is absent from normal Debug runs and compiled out of Release.

`./scripts/harness check` also runs the design-role source guard from `scripts/design_rules.py`. Outside `DesignSystem.swift`, this lexical check rejects the raw colour, font, font-modifier, rounded-shape and corner-radius vocabulary, plus unqualified system colour and text-style values. It does not parse Swift, follow aliases or inspect code inside string interpolation, and cannot catch contextual forms such as `.environment(\.font, .system(size: 17))` or Canvas `.color(.init(red: 1, green: 0, blue: 0))`, so XCTest accessibility audits and visual comparison remain required.

Bundled font provenance and licences are in [Fonts](HarnessShell/Resources/Fonts/README.md). See [foundation verification](docs/foundation-verification.md) for the #7 evidence and accepted reference differences, [Today verification](docs/today-verification.md) for #9 and [Ask verification](docs/ask-verification.md) for #13.
