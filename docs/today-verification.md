# Today in full (#9)

14 October 2026 (Sydney). Local verification passed. The independent comparison returned “pass after the listed must-fix items”; both required fixes are implemented and their affected captures have been inspected.

## Final local run

`lockf /tmp/tarot-ios-harness.lock ./scripts/harness check --device C72D8E04-B2B4-4658-900A-77040AD8206F` passed in `.harness/runs/20261013T182958.770640Z-check-2c76c8e9`: **21/21 iOS tests** (9 engine/font and 12 UI), zero failures, skips or expected failures, **32 command tests**, and the unchanged design-role guard. Xcode 27.0 (27A266a), iOS 26.5, iPhone 17e Tarot 2, 390 × 844 points.

`./scripts/harness evidence --run .harness/runs/20261013T182958.770640Z-check-2c76c8e9` was read. The latest run exported **43 kept screenshots**. After the review fixes, the upright/reversed/earlier-snapshot thumbnails, both affected largest-text thumbnail states, the new reversed bottom and the Today reference pair were inspected. All 42 screenshots from the preceding run `20261013T175245.672261Z-check-f87f554b`, including Today/Reveal reference pairs, had already been inspected by the author and the independent reviewer. The main screenshots are `02-draw`, `02-draw-card-chosen`, `03-reveal` and `04-today`; missing references belong to later issues. The task evidence packet is kept outside the repository under `tarot-9-today-full/post-review-evidence/`; the original independently reviewed packet remains in `final-evidence/`.

A separate Release build also passed in `.harness/release-marker-1791906819/Build.xcresult`; the test viewport identifier was absent from the entire Release app bundle, with the Debug binary as a positive control. The viewport regression additionally verifies the marker is absent from an ordinary Debug launch.

Implementation: colour name/swatch, object and best hour above a three-area score strip; one distinct daily sentence per area; card opens full-size Reveal with Back to Today and the existing primary return action. Both orientations of all six starter cards contain the new fields. Content version 2 is snapshotted inside the existing immutable daily draw; the SwiftData schema is unchanged. Earlier snapshots keep their original reading and explicitly report absent extras instead of being backfilled.

## Acceptance evidence

- UI: reference Star has Sage, Something glass, After 3 pm; Career 72, Relationship 81, Social 64; exact VoiceOver labels and distinct daily sentences asserted. Extras precede the aligned score row; source inspection and screenshots confirm each bar uses its area accent on the neutral control track.
- UI: 390 × 844 viewport asserted; card, interpretation and every extra are fully visible before scrolling.
- UI: thumbnail opens the same card/orientation; back and primary action return to Today.
- UI: process relaunch using a deliberately revised bundled-library fixture preserves old name, orientation, interpretation, colour, object, hour, scores and lines. Advancing the date proves the revised fixture is active for a new draw.
- Engine: all twelve starter orientations complete; integer scores 0–100; distinct non-empty lines; named six-digit hex colours; invalid/missing content rejected; original snapshot survives a revised library; earlier missing daily fields remain absent.
- Design: main 04-today plus bottom, including a complete reversed-area bottom capture; normal/reversed/earlier-snapshot; all largest-text sections; main 03-reveal plus reopened, largest and Reduce Motion variants. The largest reopened Reveal test asserts enlarged metadata and a reachable primary action/disclaimer.
- Fonts: both bundled UIFont names/families loaded and passed their registration checks. Design-role source guard unchanged. All-category accessibility audits on initial Reveal, full Today top/bottom, reopened Reveal and earlier-snapshot Today. The shared helper defers only contrast issues on elements not fully inside the real viewport, whether partly clipped or wholly offscreen, and fails naming each element never audited fully visible at another stop. Its regression covers partial, wholly offscreen, fully visible and never-covered cases, plus marker absence in a normal Debug launch.

## Author fixes found during verification

- Thumbnail button trait explicitly restored for VoiceOver and XCTest.
- Today has no phantom empty footer. Its ScrollView clips to the safe viewport, so scrolled text does not paint under system indicators. A Debug/test-mode-only empty UIKit marker reports the window safe area to all UI geometry checks, avoiding guessed insets and XCTest’s oversized scroll-view frame.
- Modal receives the current Dynamic Type size explicitly; a geometry assertion prevents a standard-size image from being mislabelled as largest text.
- Decorative expansion and back symbols keep their designed dimensions at large text; the button targets stay accessible.
- Area labels use the manifest's existing darker text partners after unfiltered native contrast audits exposed insufficient margin over grain. Accent fills remain unchanged.
- The shared accessibility audit records deferred and covered elements in the test log. Every category stays enabled and strict. Following Firstmate instructions 006–007, fully visible plain-text contrast flags are measured from their own screenshot and dismissed only at 4.5:1 or above, with identifier, label, image and ratio kept as attachments. The shared measurement and synthetic self-checks come verbatim from the supplied f3d895e patch; no Ask code or palette changes were imported. Audit fixtures disable animations; captures wait for the ritual signal and two identical accessibility-frame reads, then pause 0.3 seconds for the compositor after colour-scheme changes.
- Image inspection added an overlapping reading-opening capture for the earlier-snapshot largest-text state and made the largest-text bottom capture reach the surface group’s rounded bottom edge.
- Modal metadata query is scoped to Reveal's existing scroll view so XCTest cannot match Today behind it.

## Accepted reference differences to include in the PR

Today: actual system status indicators and the correct Sunday for 11 October 2026; original reflective draft reading/area copy and literal colour name (Sage); native font metrics and the existing original code-drawn art/grain. Darker existing area text colours are required for audited contrast over grain. The score strip has larger gaps between its labels, numerals and bars: it uses the existing 8-point within-group spacing role in the manifest. The section headings use the existing 22-point section role, within the manifest’s 20–24-point range. The thumbnail uses the manifest’s 120 × 192 dimensions and the existing 20-point page spacing between it and its text, so the card row sits slightly higher and its text slightly farther left than the web rendering. Card, extras, score strip and area group otherwise follow the reference hierarchy.

Today scope: Settings icon belongs to #20; Today Ask entry and Today/Ask tabs belong to #13; History tab belongs to #19. Area sentences may wrap at normal size because the original draft copy uses the existing 17-point body role; §11 explicitly permits wrapping instead of truncation. Area rows have no inert chevrons because this ticket provides readings, not area navigation. Midnight arrival helper is omitted while live rollover is still #11. The ordinary Today reference has no first-day reminder; #21 owns that state.

Reveal: reopening adds a real Back to Today control in the top-left 44-point target. It makes the header taller than the initial Reveal reference; the same card and metadata remain visible at default text, and large text scrolls with the primary action inline. Share remains #23. Existing native safe-area, font metrics, art contours and grain variations follow the accepted #7 foundation differences.

Largest text: thumbnail/details, extras and scores stack; sentences wrap and all content scrolls without text caps. Earlier snapshot: quiet missing-content caption follows manifest §11; no matching historic-content reference exists.

## Independent comparison

A fresh session that did not write or inspect the implementation compared all 42 pre-fix screenshots with the manifest and applicable references on 14 October 2026. Its verdict was **“pass after the listed must-fix items”**: T01 and V02. The following dispositions incorporate Firstmate's instruction 009. The author inspected the corrected/new images from the passing post-review run recorded above; no must-fix item remains. One independent round is sufficient under that instruction.

| Finding | Disposition and reason |
| --- | --- |
| T01 | Fixed: replaced the inward pair with outward diagonal arrows. Keep the 14-point decorative symbol, circle, placement and accessibility treatment. Upright, reversed, earlier-snapshot and largest-text thumbnails were recaptured and inspected; a magnified before/after comparison confirms the circle and placement are unchanged. |
| T02 | Accepted: correct Sunday date and native system indicators preserve the date role and native layout. |
| T03 | Accepted: Settings, Ask and tabs are later slices (#20, #13, #19); no inactive controls are added. |
| T04 | Accepted: slight native thumbnail/detail positioning, card proportions, art contours and shadow preserve the manifest's approximate 5:8 card and original illustration grammar. |
| T05 | Accepted: cooler apparent grain and small text-rendering differences retain the dawn/ink hierarchy; textured ground is required. Font registration and token checks pass separately. |
| T06 | Accepted: original interpretation wording remains calm, reflective, second person, unboxed and readable. |
| T07 | Accepted: literal “Sage” replaces “Wear some sage”; all extras retain the ordered three-column band and readable values despite small height differences. |
| T08 | Accepted: darker area labels follow the manifest's textured-screen text partners; spacing differences retain clear labels, numerals and neutral-track bars. |
| T09 | Accepted: original distinct area sentences wrap rather than truncate; the single surface group and separators remain, with no inert navigation chevrons. |
| T10 | Deferred to #11 by Firstmate: “Your next card arrives at midnight” promises the local-midnight rollover delivered there. Do not add that promise in #9. This deferral is now explicit in manifest §11. |
| T11 | Accepted: Today has the thumbnail action and no competing filled primary button; the reference Ask entry is deferred. T01 corrects its affordance. |
| V01 | Accepted: rotated art, explicit Reversed label and different saved copy/extras/scores are valid orientation-specific content; wrapping preserves readability. |
| V02 | Fixed evidence: added `04-today--reversed-bottom.png`, asserting that every reversed area heading and complete sentence is fully visible; the author inspected the final group and bottom: all three complete sentences and the rounded bottom are visible without clipping, overlap or truncation. No intermediate stop was needed. |
| V03 | Common Today dispositions apply; T01 is corrected in the reversed thumbnail too. |
| E01 | Accepted: earlier snapshots omit invented extras and show the exact quiet missing-content caption required by §11. |
| E02 | Common Today dispositions apply; T01 is corrected in the earlier-snapshot thumbnail too, including largest text. |
| R01 | Accepted: Back to Today and the shifted header are required for reopened Reveal; the decorative chevron remains fixed-size. |
| R02 | Accepted: Share belongs to #23 and tabs are absent on ritual screens. |
| R03 | Accepted: the added back-control header moves the card/details lower while retaining a clear standard-size primary action. |
| R04 | Accepted: slight card/art/margin/shadow differences preserve the rounded 5:8 shape and illustration identity. |
| R05 | Accepted: native grain and text-rendering differences retain the dominant centred card name, bold metadata and secondary keywords. |
| R06 | Accepted: native safe-area placement moves the footer slightly higher and changes arrow size/gap; the complete action and disclaimer stay unobstructed. |
| R07 | Accepted: largest text uses a tall multiline action and inline disclaimer under the manifest's accessibility exception; no type is shrunk. |

The reviewer found no other internal text-box clipping, overlap or ellipsis. Screenshot assessment does not prove navigation, accessible labels, font loading, contrast, storage or motion timing; the recorded UI/engine checks supply the applicable runtime evidence, and real-device VoiceOver order remains a manual limit.

## Text-detection exposure check

Instruction 008 required source and runtime evidence for native text-detection findings at scroll edges. Source inspection found no hidden or drawn reading text without an equivalent spoken label. The focused `testTodayScrolledTextIsExposed` passed in `.harness/today-exposure-1791913613.xcresult`; both its screenshots and complete accessibility hierarchies were inspected. Every fully visible string from the failed Today stop appears in an exposed label: metadata, keywords, core reading, the three extras, section headings, all area names/scores, and Career/Relationship sentences. Social is also checked while fully visible at the bottom. The same test passed again in the final suite, retaining fresh screenshots and both hierarchies.

Native element-detection findings are strict at every audit stop; the exposed-label check above is supplementary evidence, not an exception. The final run recorded **zero** unattributed text-detection cases. Its initial Today audit deferred only the partly clipped `area-label-career` and wholly offscreen `line-career` contrast findings; both subsequently passed fully visible, as recorded in the test log. The earlier failing run identified an unattributed text-detection issue and failed as intended.

## Contrast evidence

The archived fully visible core-reading failure from check 12 measures 9.062926109939994:1 with the shared function (background luminance 0.7186824644654574; text 0.03481614603724787). Source inspection found no dimming on the reading. The final passing run had **zero measured contrast dismissals**. For completeness, these are every dismissal retained in the earlier diagnostic run `20261013T170850.579277Z-check-69451d55`, which subsequently failed on the separate text-detection finding; its log and element images remain in the task's `text-detection-evidence/` packet:

| Identifier or unique exposed-label key | Ratio |
| --- | ---: |
| `core-interpretation` | 9.062926109939994:1 |
| `line-relationship` | 11.370023044106969:1 |
| empty identifier, `48:label:Sage` | 9.072308523293536:1 |
| empty identifier, `48:label:After 3 pm` | 9.05828150967682:1 |
| `score-label-career` | 5.373034934775932:1 |

All five were fully inside the true safe-area viewport and above the 4.5:1 manifest floor. No colour was changed to handle those native flags.

## Limits

Draft content still needs editorial sign-off. Simulator tests and accessibility labels/audits do not establish real-device VoiceOver reading order. No accounts, networking, paid services, new dependencies or unrelated product features were added. The independent comparison is complete with the dispositions above. The post-fix captures were checked by the author as instructed; they were not sent for a second independent round.
