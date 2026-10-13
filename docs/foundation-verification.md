# Daily-card foundation (#7)

Scope: Draw, Reveal and basic Today only. Local behaviour checks and author screenshot inspection passed on 13 October 2026. Independent visual review is pending; this is not a claim that the design check is complete.

## Behaviour and test coverage

- Five labelled buttons have separate tap regions. UI tests choose every position and change a choice before turning; the reading is identical and the chosen position is reported on Reveal.
- Reveal contains name, orientation, arcana and keywords, no interpretation. A UI test checks it stays on screen until the meaning action is tapped.
- Today shows the card, metadata and original draft core interpretation. A disk-store UI test terminates during Reveal and confirms the next launch goes directly to Today with the saved result.
- The disk test changes the supplied creation seed after relaunch, then tests a new date against an independent empty store with the original seed. This exercises seed persistence as well as draw persistence.
- Engine tests check a known SHA-256 vector, repeated inputs, all positions, variation across dates/seeds, local midnight in different time zones, six complete cards in both orientations and snapshot round trips.
- Font tests require both UIFont family and PostScript names. A command-contract test rejects raw colour/font/radius primitives outside the design system.
- Debug arguments are contained in `#if DEBUG`; normal and Release launches ignore them. The project explicitly defines DEBUG only in its Debug configuration.
- The app contains no network client, external SDK or package dependency. SwiftData CloudKit integration is disabled.

## Reference differences to review

These differences follow #7's explicit scope and are recorded in the manifest (§11):

| Screen | Difference from the reference | Reason |
| --- | --- | --- |
| Draw, unselected | No History or Shuffle again; a quiet instruction occupies the footer | History and ritual shuffle belong to later issues. An inert control would suggest functionality that does not exist. |
| Draw, selected | No History; the native status bar remains visible | History is later scope. The reference has no real system status bar; the manifest prohibits a fake one. |
| Draw | Title wraps after "pulls"; selected fan/disc sits higher and uses a slightly smaller card than the web reference | Native type/layout follows the manifest roles and reflows with text; the static fan keeps five distinct tap lanes. These geometry differences are submitted for independent review. |
| Reveal | No Share | Sharing is a later issue. |
| Card art | Rounded lower art corners, curved horizon, slightly different star/hills and no cast shadow | The starter uses the original geometric grammar required by the build spec. The same card component and palette are used at all sizes. |
| Today | Card, metadata and core interpretation only; no Settings, extras, scores, area readings, Ask entry or tab bar | The ticket explicitly requests a basic Today; those destinations and features are later slices. |
| All | The actual injected date uses the correct weekday; original draft interpretation differs from the mock | Reference dates and readings are invented examples. The seed/date fixture reproduces The Star upright, and original writing is required by the spec. |
| All | Code-drawn grain and art; native text rendering and safe-area spacing | The spec requires original geometric art, native typography and system-safe areas rather than web-rendered pixel duplication. |
| Large text | Content scrolls, controls grow, Today stacks vertically and actions follow the content at accessibility sizes | One shared ReadingScreenLayout keeps default-size actions pinned but moves them inline at accessibility sizes, preserving uncapped text and a usable scroll area. |
| Reduce Motion | The debug capture flag disables animations via the root transaction | SwiftUI's real Reduce Motion value is read-only; normal launches honour it. This slice has no animated states. These captures establish the final static layout, not a simulator system-settings change. |

## Evidence and remaining review

`./scripts/harness check` passed in `.harness/runs/20261013T103002.584900Z-check-e65293f2/`: 30 Python command/design checks and 12 real iOS tests, with zero failures, skips or expected failures. The device was iPhone 17e on iOS 26.5. All 19 exported screenshots were opened and inspected; the run's `design-comparison.html` was opened through chrome-devtools-axi and compared against the four touched reference states. Missing references belong to later slices, so `--require-all-screenshots` was not used.

The UI suite performs unfiltered XCTest accessibility audits on Draw, selected Draw, Reveal and Today at standard text size. At accessibility size 5 it checks non-empty element frames inside the visible window, scrolls to each required Reveal field, and captures the action and disclaimer together. It also verifies the Today header and metadata and that the final line of its long interpretation can be reached. Captures use the full display with a short compositor-settling interval after UI operations.

The previous large-text Reveal defect was reproduced with a geometric assertion: the keywords extended below the 844-point window even while `isHittable` passed. `ReadingScreenLayout` now moves footers inline for accessibility sizes, while keeping standard-size actions pinned. The strengthened regression passes, and the retained images show the required content. Text is neither capped nor shrunk.

The final app source also passed a separate Release compilation. An inspection of the compiled Release executable found none of the Debug launch switches. Release logs and portable final evidence are kept in the task's external evidence folder; they are not committed build products.

A fresh reviewer must receive only the image pairs and `docs/design.md`, then report findings before the design check is complete. Content editorial review and real-device/VoiceOver checks remain release limitations. Reduce Motion captures use the app's Debug override rather than changing simulator settings; no motion exists in this slice.
