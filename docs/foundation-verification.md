# Daily-card foundation (#7)

Scope: Draw, Reveal and basic Today only. Independent image review completed on 13 October 2026. Its required evidence correction and shared visual refinements are recorded below, with behavioural checks and the limits of image-only review.

## Behaviour and test coverage

- Five labelled buttons have separate tap regions. UI tests choose every position and change a choice before turning; the reading is identical and the chosen position is reported on Reveal.
- Reveal contains name, orientation, arcana and keywords, no interpretation. A UI test checks it stays on screen until the meaning action is tapped.
- A reversed-Star UI case checks its orientation label, distinct meaning and kept Reveal/Today images.
- Today shows the card, metadata and original draft core interpretation. A disk-store UI test terminates during Reveal and confirms the next launch goes directly to Today with the saved result.
- The disk test changes the supplied creation seed after relaunch, then tests a new date against an independent empty store with the original seed. This exercises seed persistence as well as draw persistence.
- Engine tests check a known SHA-256 vector, repeated inputs, all positions, variation across dates/seeds, local midnight in different time zones, six complete cards in both orientations and snapshot round trips.
- Font tests require both UIFont family and PostScript names. A command-contract test rejects raw colour/font/radius primitives outside the design system.
- Debug arguments are contained in `#if DEBUG`; normal and Release launches ignore them. The project explicitly defines DEBUG only in its Debug configuration.
- The app contains no network client, external SDK or package dependency. SwiftData CloudKit integration is disabled.

## Independent review and dispositions

A fresh reviewer compared only the four reference states, all 19 original captures and the manifest on 13 October 2026. Verdict: **pass after the must-fix evidence item V-T4**. The reviewer found no other image-proven clipping, overlap or unreachable primary action. The following author corrections address that condition and the fidelity recommendations; this is one independent round, followed by author verification of the changed captures.

| Finding | Disposition and reason |
| --- | --- |
| D1 | Accepted: real system status indicators, as required by the prohibition on a fake status bar. |
| D2 | Accepted: Sunday is correct for the injected 11 October 2026; History is outside this foundation slice. |
| D3 | Fixed: shared header moved down and the default title measure now wraps after “that”. No forced line breaks or accessibility text cap; accessibility sizes use the full column. Accepted: the subtitle baseline remains a few points lower because of native font metrics. |
| D4 | Fixed: the fan uses larger cards, a lower centre and a deeper spread. Five separate tap lanes remain. Accepted: the final composition is roughly eight points lower than the web reference to retain the shared spacing/minimum header needed by native font metrics. |
| D5 | Fixed: larger disc and a stable anchor shared with the chosen state. The small remaining vertical offset is accepted for the same shared-layout reason as D4. |
| D6 | Fixed: five rising rays, the horizon and two tapering lower strokes follow the reference motif. Accepted: minor ray/stroke length and rasterisation differences from the original code drawing; every back uses this same artwork. |
| D7 | Fixed: dense, fine deterministic grain replaces isolated speckles and covers the disc. Accepted: the generated grain pattern differs from the web/JPEG texture; the specified fine scale and blend strengths are retained. |
| D8 | Accepted: “Choose a card to begin” is the manifest's explicit foundation substitute for the future shuffle action/helper. |
| D9 | Accepted: the single-line foundation footer uses native safe-area spacing. No filler is added to imitate the absent shuffle helper. |
| C1 | Accepted: native status bar, correct weekday and omitted History, for the same reasons as D1–D2. |
| C2 | Fixed: both Draw states use the corrected shared header spacing. Minor native subtitle metrics are accepted as in D3. |
| C3 | Fixed: the chosen card is enlarged to 124 points wide and raised inside the stable composition. Accepted: the small remaining vertical offset follows D4; width/height follow the manifest’s approximate 5:8 ratio. |
| C4 | Fixed: selection preserves the disc and fan anchor; the dimmed cards sit lower. A UI assertion checks the hit-lane frame remains unchanged. |
| C5 | Accepted: the chosen card stays in front of its dimmed neighbours so its identity is unobscured; all five targets remain usable. |
| C6 | Fixed: shared motif and grain corrections apply in both states, with the minor shared drawing/texture differences accepted in D6–D7. |
| C7 | Accepted: default actions remain near the native bottom safe area; accessibility-size actions follow the content. Labels and the one-primary-action hierarchy match. |
| C8 | Accepted: small native glyph/rasterisation differences are allowed by the manifest; bundled-font tests reject fallback. |
| R1 | Accepted: native status bar; Share is outside #7's flow and is omitted. |
| R2 | Accepted with refinement: header spacing now follows the shared rhythm. The card retains the manifest's 214 × 342.4 (5:8) shape rather than the slightly taller web drawing. |
| R3 | Fixed: the shared card face casts a subtle ink shadow. |
| R4 | Fixed for the prominent differences: ink horizon, cream opening and square lower art edge restored. Accepted: small differences in star/core, dots, hills and wave contours, since this is original code-drawn art in the specified shape grammar, not a raster reproduction. #12 explicitly owns distinct faces for the complete 78-card library; this slice retains its six-card starter. |
| R5 | Fixed: fine dawn grain. Accepted: small apparent art-colour differences from JPEG grain and native rendering; code uses the manifest's named colours. |
| R6 | Fixed: 44-point name, 16-point semibold orientation/arcana, 16-point keywords and tighter group spacing restore the relative hierarchy. All roles still scale. |
| R7 | Accepted: native safe-area footer and native arrow glyph; the full action and disclaimer remain visible. |
| R8 | Accepted: small native text-rendering differences. Neither the reference nor this Reveal has tabs/back navigation. |
| T1 | Accepted: native status bar, correct weekday and small native-safe-area placement difference. |
| T2 | Accepted: Settings, expansion control, scores, extras, area readings, Ask entry, arrival helper and tabs exceed the basic Today enumerated by #7. The ordinary Today reference has no reminder, and no reminder was added. |
| T3 | Accepted: manifest 20-point gutter and 5:8 thumbnail produce a slightly more compact row; the basic structure remains unboxed. |
| T4 | Fixed: 40-point card name, 16-point semibold orientation/arcana and tighter metadata spacing strengthen the hierarchy. |
| T5 | Fixed/accepted consistently with R3–R4: shared shadow, horizon, cream opening and square art edge; small original shape contours remain. |
| T6 | Accepted: original reflective starter writing, rather than copying the mock paragraph. Content is marked as requiring editorial review before release. |
| T7 | Fixed: standard interpretation leading is about 26 points for 17-point type. Accepted: different line endings follow the original wording and native font metrics. Large text remains uncapped and scrollable. |
| T8 | Fixed: shared dawn grain. Accepted: empty space after the paragraph because the fuller Today is deliberately outside this slice. |
| V-T4 | Fixed: a separate largest-text opening capture places the interpretation start fully inside the viewport, overlapping its preceding content; the bottom capture remains. Duplicate name/details attachments were removed while their geometric assertions remain. |

The unchanged largest-text layout adaptations remain accepted: card/details stack on Today, ritual footers become inline, and text/control height grows without a cap. Reduce Motion captures show final static states; this issue implements no ritual animation.

## Limits of images and corresponding checks

- Reduce Motion configuration and motion cannot be established by still images. UI tests launch the Debug override and capture the settled state. The root transaction also reads the system setting; no animation is implemented in #7. A simulator system-settings change or real-device motion test is not claimed.
- Touch regions, semantics and selection are checked by UI tests: all five positions, minimum 44-point frames, changing selection, and labelled cards. Unfiltered XCTest audits cover contrast, hit regions, clipped text and scaling. Manual VoiceOver focus/reading-order testing is still a release limitation.
- Scrolling, reachable content/actions and the meaning transition are exercised by real-app UI tests. Geometry assertions check full required text/control frames; long Today interpretation captures overlap its beginning and end. Standard pinned versus accessibility inline footers are defined in the shared layout and manifest.
- Fonts and token use are established by UIFont family/PostScript assertions and the source style guard. Named palette values and blend strengths live only in the design system. Audits cover rendered contrast; JPEG sampling is not used to redefine colours. The largest Dynamic Type setting is exercised; every intermediate size/device has not been independently captured.
- Reversed orientation now has additional Reveal and Today captures and a UI test checking its label and separate meaning. Engine tests validate six complete, distinct identities and both orientations. Rendering every identity/size and smaller/real devices are not claimed; full-deck rendering is #12. Dark dawn is undesigned in the manifest and the app deliberately presents dawn in light appearance.
- Debug test mode deterministically injects a failure on the first storage-opening attempt. A UI test runs an unfiltered accessibility audit on the error screen, retains standard and largest-text captures (including the retry control), and verifies that retry reaches Draw.
- The standard captures contain all #7 content. The long Today reference's additional sections are explicitly excluded by scope, not hidden further down the built screen.

## Final validation evidence

`./scripts/harness check` passed in `.harness/runs/20261013T111925.637520Z-check-4ac3c37a/`: 30 Python command/design checks and 13 iOS tests, zero failures, skips or expected failures, on iPhone 17e / iOS 26.5. All 17 kept screenshots were individually opened and inspected against the four reference states; the generated comparison page was opened through chrome-devtools-axi, including a side-by-side chosen-state comparison. The Today opening and bottom captures now show the complete interpretation with overlap. Missing main screenshots in the summary are the out-of-scope later screens; strict all-screen coverage was not requested.

The previous large-text Reveal defect was reproduced with a geometric assertion: the keywords extended below the 844-point window even while `isHittable` passed. `ReadingScreenLayout` now moves footers inline for accessibility sizes while keeping standard-size actions pinned. The strengthened regression passes; text is neither capped nor shrunk. During the visual refinement, an unfiltered contrast audit also caught the enlarged disc painting over the Draw subtitle. The heading now paints above that decorative overflow.

The complete independent report, original and final screenshot packets, comparison page, result bundle, logs and Release checks live in the task evidence folder, outside Git. Content remains draft pending editorial review; the manual/real-device limitations above are not claimed as completed checks.
