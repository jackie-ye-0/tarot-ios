# Verification report

As of 10 September 2026: **partial verification; the iOS environment is not yet established as usable**.

Branch: `fm/ios-tarot-harness-setup`. Source baseline before implementation: `139e0e85f686442ba8ffccd7943107944aef3aaa`. Implementation checkpoint: `a5498a409089f4ca7d8a05d942694faa4e660b19`. Later documentation-only commits may follow this source checkpoint; the local `.harness/handoff.json` records the exact current handoff head. Evidence folders are local and ignored; they are not included in a clone or this PR.

## Observed

- Isolation: physical working directory equals Git top level in the assigned disposable worktree. Started with no tracked project files.
- Initial tool inventory: selected developer directory is `/Library/Developer/CommandLineTools`; full Xcode and `simctl` were unavailable. The machine owner is installing official Xcode; this task changed no machine settings or software installation.
- `python3 -m unittest discover -s tests -v`: 15 command-contract tests passed on the final scaffold rerun (initial run: 14). Final raw output is `.harness/command-contract-validation.log`. They run actual wrapper processes against fake tools, including paths with spaces, simulator selection, original exit status 65, missing Xcode, missing devices, zero/skipped tests, malformed result JSON and missing/export-failed attachments. These are not iOS test results.
- `./scripts/harness check`: command-contract suite passed; then the real prerequisite probe failed with exit 1 because full Xcode was unavailable. Retained run: `.harness/runs/20260910T040825.990277Z-check-039b1269/`. Inspect `command-tests.log`, `xcode-version.log`, `summary.json` and `summary.txt` there. The non-zero status propagated through the shell wrapper. `./scripts/harness evidence` accurately reported the failed run.
- `plutil -lint HarnessShell.xcodeproj/project.pbxproj`: passed. Shared scheme XML parsed with Python's XML parser. These are syntax checks, not Xcode compilation.
- `git diff --check`: passed at the initial scaffold checkpoint.

## Pending real verification

1. Completed: installed `xcodebuild`, `simctl launch` and `xcresulttool` summary/export help review. Remaining items below are still pending.
2. Successful prerequisite discovery, native build and simulator install/launch.
3. Four real XCTest tests, including visible counter interaction and reset on relaunch.
4. Deliberate assertion failure in a disposable validation copy, non-zero wrapper status, then a restored passing run.
5. Retained `.xcresult`, actual test counts, toolchain/device metadata, exported passing-test screenshot and visual inspection.
6. An actual independent standalone Codex session plus separate reviewer rerun, as specified in `standalone-acceptance.md`.

No screenshots, iOS test results or independent client compliance are claimed from the fake-tool tests. No CI, branch protection or remote gate has been established or verified. Other clients, physical iPhone testing and App Store delivery are outside this setup.

## Prepared acceptance fixture

A tracked-files-only disposable repository was prepared at `.harness/acceptance/standalone codex/` from implementation checkpoint `a5498a409089f4ca7d8a05d942694faa4e660b19`. Baseline fixture head: `afbd33dfdb7e0d28593d9d78e8c71bb08348729f`; deliberate counter-defect head: `888ff05393d55fd8018f34b8af8c25018ec44a07`. Only the disposable counter changes to increment by two; normal tests/code remain intact. Preparation metadata is `.harness/acceptance/preparation.json`. No real failing iOS invocation or independent session has run yet.

## Xcode available, platform download pending

Using per-command `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, Xcode reports **26.6 (17F113)**. Real `xcodebuild -list` returned zero and recognised the app, unit-test and UI-test targets plus the shared scheme. Installed command help and the test-summary JSON schema were inspected; they confirm the runner command forms and count fields. Logs are retained in `.harness/preruntime-20260910T0420/`.

A generic iOS Simulator build returned **70 before compilation**: Xcode reported that the iOS 26.5 platform was not installed. The machine owner has started the platform downloads. No build, simulator or independent-client pass is claimed. The exploratory raw build omitted a result-bundle path, so Xcode reported a temporary error bundle; the wrapper now explicitly selects a repo-local result bundle for build/launch as well as tests. Subsequent replay remains pending platform availability.

After those tooling changes, **16 command-contract tests passed**; retained log: `.harness/preruntime-20260910T0420/command-tests.log`. This supersedes the earlier 15-test scaffold run.
