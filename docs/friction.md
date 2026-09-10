# Observed harness friction

Use one short entry per observed issue: scenario; expected/actual; evidence; knowledge/tool/check classification; smallest fix; replay result; obsolete guidance removed.

- Initial setup: Command Line Tools are selected and full Xcode is not yet available. Classification: prerequisite/tool diagnostic. The runner retains `xcode-version.log` and explains manual Xcode/runtime setup and per-command `DEVELOPER_DIR`. Fake-tool tests exercise that exit status/message; a real prerequisite run is recorded in the verification report. Real iOS replay remains pending installation. No installation automation was added.

- Real generic build before platform readiness: Xcode rejected the destination and selected a temporary error-result path when no result path was supplied. Classification: tool/evidence. The harness now specifies `Build.xcresult` for builds and launches as well as `Tests.xcresult` for tests. Command-contract replay covers the argument path and build failure; real build replay is pending platform installation. No additional wrapper or dependency was added.

- First real launch captured the startup screen because `simctl launch` returns before SwiftUI necessarily finishes rendering. Classification: knowledge/evidence interpretation. README now identifies the immediate launch image as a diagnostic; visual verification uses the UI test screenshot after element discovery and successful taps. This avoids adding an arbitrary sleep or treating image existence as proof of readiness. Passing-test screenshot inspection is recorded in the verification report.

- First real UI tests failed because SwiftUI `LabeledContent` exposes a combined accessibility label (`Count, 0`), while the assertions expected only the number. Both unit tests passed and the UI observed `Count, 1` after a tap, distinguishing label grouping from a counter-state defect. Classification: check knowledge. Corrected the UI assertions to the full semantic label, preserving exact count/interaction/reset checks. The existing UI suite is the regression check; no app behaviour or check threshold changed.
