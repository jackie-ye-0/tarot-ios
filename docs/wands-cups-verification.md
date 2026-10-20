# Wands and Cups content verification

Issue #25. First draft, 20 October 2026. Jackie's editorial review is required before release to real users.

Current status: the final full check passed on clean `131ba77`, with **132/132 tests passing**, zero failures or skips. The independent comparison is complete: author-inspected captures close its evidence-only P1 and R1 findings under firstmate’s authorised review path; non-blocking P2 is explicitly deferred. This record update changes documentation only.

## Content and wording

The single bundled library, `HarnessShell/Resources/starter-cards.json`, is version 7. It contains the original 22 Major Arcana followed by all fourteen Wands and fourteen Cups, Ace through King, with identifiers and metadata matching the artwork catalogue. Both orientations of each new card contain three keywords, a two-sentence core interpretation, three distinct daily area lines and integer scores, a colour name and six-digit hex, an object, a best hour and all six position meanings.

The new writing is original to this task. Wands explores initiative, direction, collaboration, boundaries, sustained effort and leadership. Cups explores feelings, reciprocity, friendship, disappointment, choice, belonging and care. Reversed meanings invite a different perspective rather than predicting a bad event. Outcome passages ask what to consider; Them passages ask the reader to hear the other person's account rather than claiming to know their thoughts. No new passage gives health, medical, death, financial or lucky-number content. The language is calm, second person and Australian/British English, with no emoji or exclamation marks. Scores and daily extras remain reflection prompts, not probabilities or promises.

All 56 new orientations were reviewed while authoring, including the distinction between each card's daily and position meanings. A separate static check confirms that all 392 new core/position passages are distinct and that the new text contains none of its finite serious-topic, lucky or future-certainty terms. This does not prove editorial quality or semantic safety. The content file continues to require Jackie's editorial review.

The existing Major Arcana, shared area lenses, four Relationship variants, suggested questions, reflection pool and crisis content are unchanged. There were no Wands or Cups placeholder interpretations in the starting library, so the 28 entries are complete additions. The resource filename and original card order are retained. The larger pool changes future unsaved draws; saved daily and question snapshots retain their original content and version.

## Automated coverage

The existing production loader and whole-library mutation tests apply to every card present, now 50 cards and 100 orientations. They check complete fields, keyword and sentence counts, score bounds, distinct area lines, valid named colours, all six position meanings and the existing lexical wording rule. The rule's documented limits are unchanged.

`WandsAndCupsContentTests` checks each complete suit against the artwork catalogue, including ranks 1–14. It composes every new card in both orientations through each question and named-person position and checks the resulting passage. Daily and composed-reading snapshots must survive encoding and decoding unchanged.

The UI tests use the established Debug launch arguments and existing scrolling, settled-screen audit and capture helpers:

- Knight of Wands upright and Queen of Cups reversed on Reveal, Today and Ask at standard and largest text sizes, with exact interpretation, orientation, colour, score and area-line assertions.
- Ace of Wands reversed, Knight of Cups upright and King of Wands upright in completed picks and saved readings, through both question and named-person flows at both text sizes.
- Existing main captures, Reduce Motion states, all audit categories, font-loading tests and the lexical design-system guard remain in place.

The deterministic fixture seeds were recalculated for the 50-card pool to retain the original Star upright reference, Strength on the previous date, Star reversed and High Priestess reversed. The westward-travel engine fixture still deliberately starts with the same unsalted card on adjacent dates so it exercises repeat avoidance. The hash input and engine rules are unchanged.

## Checks before the simulator window

The 34 command-contract tests passed with `python3 -m unittest discover -s tests -v`. A temporary macOS executable compiled the unchanged production `ReadingEngine.swift`, `QuestionReading.swift` and `CardIdentity.swift`, then decoded the complete library, composed and round-tripped 336 Wands/Cups readings and round-tripped 56 daily snapshots. All assertions passed. This exercises production decoding and composition on the host, not the iOS app or its registered test suite.

A separate attempt to typecheck the new Swift Testing suite with the host's default `swiftc` stopped at `no such module 'Testing'`. No toolchain change or workaround was attempted. The subsequent full Xcode harness run compiled and passed the actual suite, including both parameterised suit cases.

## Full check and design evidence

No screen, component, layout, colour, font or motion implementation changes. The manifest therefore remains unchanged. The content adds longer Minor Arcana names and new passages to existing layouts.

`./scripts/harness doctor` passed, then plain `./scripts/harness check` passed on clean `78853e9c83e59ce286f1192bc88f59cba67c3b4e` in `.harness/runs/20261020T101054.798791Z-check-83b5cefb`. It passed all 34 command-contract tests, the unchanged design-role guard and 132/132 logical iOS tests, with zero failures, skips, expected failures or runtime warnings. Xcode 27.0 used the harness's dedicated iPhone 17e on iOS 26.5. The simulator lock was released at 13:02:49 UTC on 20 October. The later capture-only correction is covered separately below; this is not a claim that another full check ran on that commit.

Read `summary.json` and `./scripts/harness evidence` after completion. The run exported 745 images and matched all 15 main reference states. Opened its comparison page through `chrome-devtools-axi` and inspected the Reveal, Today, Ask, completed-pick and reading references against all 135 new full-screen content captures, including overlapping largest-text scroll stops. The complete Today endings show Social, Ask, the midnight caption and tabs. The long Minor Arcana names and passages remain readable without horizontal truncation; actions remain reachable. Existing font-loading checks and settled-screen accessibility audits passed without changing categories or exceptions.

The final-evidence packet in the task folder retains the unchanged manifest, reference images, screenshots, comparison page, summaries, logs and independent report. The original reviewed packet is retained separately from the focused capture supplement.

## Independent comparison and dispositions

The fresh-session reviewer inspected all 135 content full-screen captures, 24 associated text crops, five matching references and 16 ordinary/Reduce Motion context captures on 21 October 2026 (Sydney). Its verdict was **pass after P1 and R1 are supplied and checked**. It found no image-established implementation defect. Firstmate authorised an author-inspected focused capture to close those two evidence-only findings, without another independent review.

| Finding | Disposition |
| --- | --- |
| P1 | Closed by author inspection of the passing focused run. The largest-text question pick now uses the existing navigation-top helper and asserts that Back, progress and the complete question are visible before capturing. |
| R1 | Closed by author inspection of the passing focused run. The standard reading now scrolls to the final feedback choice and requires the complete reflection question/helper, feedback prompt and three choices, Done and disclaimer at the captured stop. |
| P2 | Deferred at firstmate's explicit direction. Knight of Cups wraps to two lines, leaving its orientation and position label lower than the adjacent one-line names in the standard pick. All text is readable and each position remains associated with its card. This ticket writes content; no shared layout change or future-ticket coverage is claimed. |

Every other visible difference is accepted for the reasons below. IDs refer to the retained independent report.

| Findings | Accepted difference and reason |
| --- | --- |
| Shared | Native status bars/safe areas and phone viewports alter vertical positions relative to the long web reference documents. Scroll stops cover the content. Native glyph edges, line breaks, icon strokes and grain differ within the manifest's allowed rendering variation. Darker area labels follow the manifest's contrast correction. |
| V1–V3 | Knight of Wands / Queen of Cups, their keywords and Minor Arcana labels replace the example Star. Staff/pennant and cup/crown/seat art follows the full-deck grammar; the reversed Queen is inverted and explicitly labelled. Longer names remain whole and wrap at largest text. |
| V4–V5 | Native Share/arrow weights, card glow/shadow and minor spacing differences preserve the centred card and single primary action. The 20-point dawn-action inset follows the later footer rule. |
| V6 | Largest-text Share gets its own row and the selection sentence follows it; the multiline action/disclaimer move inline after the content as specified. |
| T1–T2 | The synthetic Sunday date and new card details replace reference values; the gear is specified. Longer names/keywords wrap beside the thumbnail at standard size and stack below it at largest text. |
| T3–T4 | Longer reflective interpretations, different extras/scores and distinct area lines are the intended content. The order remains interpretation, extras, scores, then area readings; every score retains its numeral. |
| T5–T7 | Static area rows deliberately omit chevrons. The shorter “Ask the cards” entry is the current foundation's wording. Dark filled selected tabs support contrast, and tab symbols remain manifest placeholders. |
| T8 | Largest-text extras/scores stack, rows grow and Ask becomes multiline; the complete ending remains readable. |
| A1–A2 | The actual saved daily card name, Relationship line and score replace the reference's second interpretation, as specified. Shorter context reduces the panel height without changing content order or hierarchy. |
| A3–A5 | Suggestions are complete drawable questions; widths follow their wording and the 48-point minimum. Full-width status choices and Skip are specified. These fresh fixtures have no recent reading, so the conditional row is absent. |
| A6–A7 | The named-person row/helper and largest-text selectors, chips and controls wrap or stack with padding. All complete labels and actions are captured; native glyph/tab differences retain the accepted treatments above. |
| P3–P5 | New faces/identities replace the reference examples, with explicit orientation on every card. The question is the selected reflective suggestion; the named variant uses You and Sam and You/Them/The Connection as specified. |
| P6–P7 | Native safe-area and completion spacing differ slightly while preserving the disc, completion message and single cream action. Largest text stacks all three cards and places the message/action after them. |
| R2–R3 | Card-specific passages and question/named-person labels replace reference examples and match the completed pick. Named passages invite asking the other person rather than asserting hidden feelings. |
| R4–R5 | The longer neutral Relationship lens moves reflection down; the named version includes Sam's introduction. Different reflective questions preserve the dark panel and “Something to sit with” helper. |
| R6–R7 | Native control weights and wrapping change spacing. Done/disclaimer are pinned at standard size and inline at largest text. Standard feedback choices have equal widths; largest text stacks them. |
| R8 | A saved note is optional and destructive actions belong in More, so their absence is the specified fresh-reading state. |

The ordinary and Reduce Motion context captures showed coherent final faces, selected/final spread states and reachable actions without an obvious visible regression. Still images do not establish first-frame timing, easing or suppression of all animations; no new motion was added.

## Focused capture follow-up

The first steering message authorised a focused capture for the evidence-only correction after the passing full check. Its follow-up clarified that moved UI-test capture steps require a full committed-head check. That correction arrived after plain `./scripts/harness test` had started, so the focused run is supplementary and will be followed by the required full check.

The temporary scheme selects the affected Wands/Cups reading UI test and retains all engine tests; no audit category is filtered and no product source changes. The original complete scheme was restored byte-for-byte after the run.

Run `.harness/runs/20261020T133117.865244Z-test-4b8a28ed` passed **63/63 selected tests**, with zero failures, skips, expected failures or runtime warnings. This includes both suit cases and the corrected question/named-person flow at both text sizes. It exported 85 images and released the simulator lock at 13:47:39 UTC on 20 October. Its comparison has zero main reference captures because it selects only content variants; it supplements the full run and does not replace it.

Read its summary and `harness evidence`, opened the comparison page, then inspected the four changed opening/ending images directly. The question largest-text opening shows Back, All three drawn and the complete question at the scroll origin. Both standard endings show the entire reflection panel/helper, feedback prompt and three choices above the pinned Done/disclaimer. No layout defect or change was needed. P1/R1 are closed under the authorised author-inspection path; P2 remains deferred. The packet retains this run separately in `final-evidence/focused-capture-follow-up/`. The final full-check result follows below.

## Final committed-head check

After restoring the complete scheme, `harness doctor` passed and plain `./scripts/harness check` ran on clean `131ba77fca310a2100397cb4e4aa9985879919c2`. Run `.harness/runs/20261020T173820.299423Z-check-65ea24d8` passed **132/132 iOS tests**, all 34 command-contract tests and the unchanged design-role guard, with zero failures, skips, expected failures or runtime warnings. Both Wands/Cups UI tests and both suit unit-test cases passed. The harness released its simulator lock at 20:30:25 UTC on 20 October (07:30 Sydney on 21 October), after exporting **742 screenshots** and matching **15/15** main references.

Read the completed summary and `harness evidence`, opened the final comparison page, and directly inspected six final originals: both largest-text completed-pick openings, both standard reading endings, and both Wands/Cups Today endings. P1 shows Back, All three drawn and the complete question; R1 shows the complete reflection panel, feedback prompt/choices, pinned Done and disclaimer. Both Today endings show the complete area text, Ask entry, midnight caption and tabs. There is no newly observed clipping or overlap. This checks the final corrected states; it does not claim manual reinspection of all 742 images. The earlier complete author inspection and independent comparison cover the unchanged content screens.

The complete final-run evidence is retained at `final-evidence/final-full-check/`, alongside the original reviewed packet and focused follow-up. App content and tests are unchanged after this passing full run; the follow-up commit records these results only. No new independent round is needed under firstmate’s evidence-only closure instruction.

The image review does not establish numeric contrast, font loading, touch targets, persistence or animation timing. Automated runtime checks provide their separate evidence. Real-device behaviour, VoiceOver reading order and Jackie's editorial review remain separate release checks.
