# Observed harness friction

Capture scenario, expected/actual behaviour, evidence, knowledge/tool/check classification, smallest fix and replay. These initial entries are resolved; the detailed run paths are in `verification.md`.

- **Missing full Xcode/platforms (tool diagnostic):** Command Line Tools could not build iOS, and a later generic build lacked the downloading platform. The runner retains the failure status/log and explains manual setup and per-command `DEVELOPER_DIR`. After the machine owner completed installation, doctor/build/launch and all four native tests passed. No installation automation was added.
- **Uncontrolled error-result location (tool/evidence):** an exploratory raw build without a result path made Xcode select a temporary error bundle. The harness explicitly specifies `Build.xcresult` for builds/launches and `Tests.xcresult` for tests. Actual build/test replay retained those bundles locally.
- **Startup capture mistaken for rendered UI (knowledge):** `simctl launch` returned before SwiftUI finished rendering. README now calls its immediate image a diagnostic. The screenshot after successful UI-test taps was exported and visually checked. No arbitrary sleep or image-existence claim was added.
- **Combined accessibility label (check knowledge):** SwiftUI exposed `Count, 0`, while initial UI assertions expected only `0`. Unit tests passed and the UI observed `Count, 1` after a tap, identifying label grouping rather than a state defect. Exact semantic-label assertions fixed the mismatch; the four-test suite passed. App behaviour and check thresholds were unchanged.

The independent Codex exercise then reproduced a separate deliberate increment-by-two defect, discovered the repository commands, repaired one expression and passed the full checks. A separate clean-commit rerun passed too. Obsolete pending-installation guidance was pruned after these replays.

## Named screenshot evidence, 13 October 2026

Issue #29 exposed a tooling gap: `harness test` passed but exported the kept screenshot as a UUID, with no screen coverage or comparison page. Reproduced in `.harness/runs/20261013T044729.833913Z-test-3cf4a3c6/`. The real Xcode export manifest retains the assigned name with an appended index/UUID. The runner now recovers that name, rejects duplicates, reports missing reference captures and produces a portable side-by-side page. Contract tests cover the naming and optional full-coverage gate; the native replay and browser inspection are recorded in [verification](verification.md#named-screenshot-export-13-october-2026).

## Large-text screenshot visibility, 13 October 2026

Issue #7 exposed a check gap: `isHittable` passed for Reveal keywords below the visible window, and full-frame swipe gestures landed on its enlarged pinned footer. A geometric regression failed with the keyword frame ending at y=923 on an 844-point window. The shared reading layout now moves footers inline at accessibility text sizes. UI tests scroll within the visible area and check non-empty, contained frames before retaining evidence. Full-display captures allow the compositor to settle after colour-scheme changes. The final replay, 12 passing iOS tests and inspected captures are recorded in [foundation verification](foundation-verification.md).
