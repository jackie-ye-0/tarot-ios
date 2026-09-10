# Verification report

10 September 2026. **Native build, launch and passing-test evidence verified; independent standalone Codex acceptance is pending.**

Branch: `fm/ios-tarot-harness-setup`. Verified code/test baseline: `4ddff9918660bfc597b886e21ea4e0735e093692`. Documentation-only commits may follow; `.harness/handoff.json` records the exact local handoff head. Evidence is local and gitignored, so these run folders are not present in a fresh clone.

## Toolchain and device

- macOS 26.6.2, Apple silicon.
- Xcode 26.6, build 17F113, selected per command with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- iPhone 17, iOS 26.5 (23F77), runtime `com.apple.CoreSimulator.SimRuntime.iOS-26-5`.
- Device UDID: `032425A0-021B-4E46-BA9E-9FBD868237C1`.

The machine owner installed Xcode/platforms and completed licence/administrator setup. This task changed no machine settings or installed software. Installed `xcodebuild`, `simctl launch` and `xcresulttool` help/schema were inspected; the project targets/shared scheme were confirmed by real `xcodebuild -list`.

## Observed verification

All paths below are relative to the repository root.

| Check | Observed result | Retained evidence |
| --- | --- | --- |
| Command contracts | 16 passed; fake tools test wrapper behaviour, including paths with spaces and failures | Passing check's `command-tests.log` below |
| Prerequisites | Passed after platform installation | `.harness/runs/20260910T041617.014318Z-doctor-1a10bc3e/` |
| Build, boot, install, launch | Exit 0; native app build succeeded | `.harness/runs/20260910T041631.516963Z-launch-7c495e1d/` |
| Full `harness check` baseline | Exit 0; 4 XCTest tests passed, 0 failed/skipped/expected failures | `.harness/runs/20260910T042042.245465Z-check-c5b02d08/` |
| Project syntax | `plutil` and shared-scheme XML parse passed | Also superseded by real Xcode build |
| Whitespace | `git diff --check` passed | Local command output |

The full passing check includes two counter unit tests and two UI tests: real button taps, exact displayed counts, and reset on app relaunch. `Tests.xcresult`, `test-summary.log`, `metadata.json`, raw logs, command arguments and summaries are retained in its run directory.

Passing-test screenshot: `.harness/runs/20260910T042042.245465Z-check-c5b02d08/attachments/E98B0630-222E-407B-A138-C55E3BDBFA25.png`. It was opened and visually inspected: the title, explanatory text, count **2** and increment button are readable without clipping/overlap on iPhone 17. The screenshot was exported from the successful interaction test's `.keepAlways` attachment. The separate immediate launch capture shows startup and is not used as UI verification.

## Real failures and corrections

- Before installation, `harness check` propagated exit 1 after its command tests because full Xcode was unavailable: `.harness/runs/20260910T040825.990277Z-check-039b1269/`.
- During platform download, the generic simulator build stopped before compilation with exit 70. Installed help/schema and logs are under `.harness/preruntime-20260910T0420/`. The harness explicitly selects a repo-local build/test result bundle; the exploratory raw build had omitted that option and Xcode selected a temporary error bundle.
- First real baseline: exit 65, two unit passes and two UI assertion failures, because SwiftUI exposed `Count, 0` while the tests expected `0`. Evidence: `.harness/runs/20260910T041807.474988Z-check-54267f85/`. The exact semantic-label assertions were corrected without changing app behaviour or reducing checks; the subsequent four-test baseline passed. See `friction.md` for the replay and guidance changes.

## Standalone acceptance handoff

Protocol: `standalone-acceptance.md`. A tracked-files-only disposable repository is at `.harness/acceptance/standalone codex/`; it has its own Git history and no supervisor brief or conversation copied into it. Its only source difference from the verified baseline is the deliberate `count += 2` defect.

- Source baseline: `4ddff9918660bfc597b886e21ea4e0735e093692`.
- Prepared defect head: `161986ab8cb95dcc04a7c87947ab816b449f36fe`.
- Preparation metadata: `.harness/acceptance/preparation.json`.
- Real deliberate-defect invocation: exit **65**, four tests executed, **1 passed / 3 failed**, no skips or expected failures. Evidence: `.harness/acceptance/standalone codex/.harness/runs/20260910T042229.113276Z-test-46119a17/`. The result summary reports `2` versus expected `1` and `4` versus `2` in the unit test, plus `Count, 2` versus `Count, 1` in both UI tests. These are assertion failures, not prerequisite or compilation failures. Simulator use paused for the independent session immediately after this run.

A fresh standalone Codex repair session and a separate reviewer rerun are still pending. They must be observed before claiming independent-client acceptance. No fake-tool results or instruction files establish client compliance.

## Limits

No CI/branch-protection enforcement, other client acceptance, physical iPhone testing, broad accessibility audit or App Store delivery is claimed. Only the iPhone 17/iOS 26.5 environment above has been verified. Product features, personal data, live AI calls and provider quality evaluation remain outside scope. Apple tools may use their normal system simulator/cache locations; harness-controlled build output, bundles and logs are kept under `.harness/`.
