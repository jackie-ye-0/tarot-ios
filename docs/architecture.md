# Architecture

`HarnessShell.xcodeproj` is a small, checked-in native Xcode project with a shared scheme. Xcode is the authority for build settings and dependencies; there is no generation step.

- `HarnessShell/`: SwiftUI app entry point, a system Form and a value-type counter. `@State` keeps the counter in the current view and refreshes the displayed number when it changes. State lasts only for that app process.
- `HarnessShellTests/`: XCTest unit tests for initial state and sequential increments. Hosted by the technical app, with no external dependencies.
- `HarnessShellUITests/`: XCTest UI tests for tapping the actual button and process relaunch resetting state. Stable accessibility identifiers identify elements independently of their positions. The interaction test retains its screenshot with `.keepAlways`.
- `scripts/harness`: location-aware shell entry point. `scripts/harness.py` orchestrates Apple executables using argument arrays and captures exit status without a pipeline masking it.
- `tests/`: black-box command-contract tests in disposable paths containing spaces under `.harness/`. Fake tools exercise the wrapper's decisions and failures. Their fake attachment bytes are never real iOS evidence.

The runner uses a distinct `.harness/runs/<timestamp>-<command>-<uuid>/` for every run. It never reuses a result bundle path. `metadata.json` records the selected developer directory, Xcode version, device and runtime; `commands.jsonl` records exact argument vectors. Test counts come from `xcresulttool`, not log-string matching or inferred test source contents. Raw logs and bundles remain available after failure. Test evidence export is attempted even when `xcodebuild` fails, while preserving its original failure code.

A passed `doctor` proves tools and an available device were discovered; only actual builds establish project/toolchain compatibility. A passed `build` proves compilation. A passed `test`/`check` additionally requires test counts and attachment export. Visual inspection and the independent Codex exercise remain human/agent review steps, recorded separately. The runner does not inspect prose to claim an agent followed instructions.

Keep the fixture small. It is not the future tarot domain architecture. Once product work is authorised, decide how domain logic and provider boundaries should be separated based on real requirements. Avoid promoting this counter into product logic or adding speculative service abstractions now.
