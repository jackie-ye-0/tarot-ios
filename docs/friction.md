# Observed harness friction

Capture scenario, expected/actual behaviour, evidence, knowledge/tool/check classification, smallest fix and replay. These initial entries are resolved; the detailed run paths are in `verification.md`.

- **Missing full Xcode/platforms (tool diagnostic):** Command Line Tools could not build iOS, and a later generic build lacked the downloading platform. The runner retains the failure status/log and explains manual setup and per-command `DEVELOPER_DIR`. After the machine owner completed installation, doctor/build/launch and all four native tests passed. No installation automation was added.
- **Uncontrolled error-result location (tool/evidence):** an exploratory raw build without a result path made Xcode select a temporary error bundle. The harness explicitly specifies `Build.xcresult` for builds/launches and `Tests.xcresult` for tests. Actual build/test replay retained those bundles locally.
- **Startup capture mistaken for rendered UI (knowledge):** `simctl launch` returned before SwiftUI finished rendering. README now calls its immediate image a diagnostic. The screenshot after successful UI-test taps was exported and visually checked. No arbitrary sleep or image-existence claim was added.
- **Combined accessibility label (check knowledge):** SwiftUI exposed `Count, 0`, while initial UI assertions expected only `0`. Unit tests passed and the UI observed `Count, 1` after a tap, identifying label grouping rather than a state defect. Exact semantic-label assertions fixed the mismatch; the four-test suite passed. App behaviour and check thresholds were unchanged.

The independent Codex exercise then reproduced a separate deliberate increment-by-two defect, discovered the repository commands, repaired one expression and passed the full checks. A separate clean-commit rerun passed too. Obsolete pending-installation guidance was pruned after these replays.
