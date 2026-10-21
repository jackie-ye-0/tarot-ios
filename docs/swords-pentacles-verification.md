# Swords and Pentacles content verification

Issue #26. First draft, 21 October 2026. Jackie's editorial review is required before release to real users.

Current status: the full check passed on clean `8e14dba` with 137/137 logical iOS tests passing, zero failures or skips. The author and independent reviewer have inspected the new content captures. The independent verdict is pass, with no must-fix findings. RN4 is closed by the author-inspected focused follow-up, which passed 66/66 selected tests. The final full check on `cc323dd` passed 136/137; its only failure was the unchanged Wands/Cups Reveal-to-Today interaction. The unchanged focused recheck passed 66/66, and firstmate authorised proceeding to no-mistakes. The final run is not claimed as a full pass.

## Content and wording

The bundled `HarnessShell/Resources/starter-cards.json` is version 8 and contains all 78 cards and 156 orientations. The final 28 entries append Swords and Pentacles, Ace through King, without changing the first 50 cards, their order, shared lenses, suggestions, reflections or crisis content. The existing resource filename is retained; no starter placeholder interpretation remains.

Each new orientation has three keywords, a two-sentence daily interpretation, three distinct daily area lines, integer scores, a named six-digit colour, an object, a best hour, and all six question/named-person position meanings. The loader now requires exact identity and metadata agreement with the 78-card artwork catalogue, without reordering the draw pool. Missing, extra, duplicate or misidentified cards are rejected alongside incomplete meanings.

All new text is original writing. Swords explores thinking, communication, conflict, uncertainty and boundaries. Pentacles explores practice, time, practical care, belonging and shared responsibilities. Reversed meanings offer another perspective rather than a prediction of harm. Outcome passages invite reflection; Them passages ask for the other person's account rather than claiming access to hidden thoughts. There is no new health, medical, death, financial or lucky-number content. Words use calm, second-person Australian/British English without emoji or exclamation marks. Scores and daily extras remain reflection prompts, not probabilities or promises.

All 56 new orientations were reviewed while authoring. A separate finite wording scan passed, and all 392 new core/position passages are distinct. The earlier 50 cards and shared text are unchanged. These checks do not establish editorial quality or semantic safety; the file explicitly retains the first-draft review requirement.

Both daily and spread draws use the complete library without a separate deck or filter. Growing the pool changes future unsaved daily draws. Previously saved daily and question readings retain their original content and version. Neither the stable hash input nor the bounded repeat-avoidance rule changes.

## Automated coverage

- Whole-library completeness and mutation tests now run over all 78 cards and 156 orientations, checking required fields, keyword/sentence counts, score bounds, distinct area lines, named colours, six positions and the existing lexical wording rule.
- `MinorArcanaContentTests` includes all four suits. Every card/orientation is composed in all six positions, with daily and question-reading encoding round trips.
- `CompleteDeckContentTests` rejects incomplete/extra/duplicate decks and incorrect identity metadata; reordered valid content retains its supplied order. Fixed synthetic seeds reach all 156 daily outcomes through the production draw function. Injected spread choices reach every card in both orientations and retain three distinct cards.
- UI tests use the existing Debug test seam and settled-screen capture/audit helpers. Queen of Swords upright and Knight of Pentacles reversed cover Reveal, Today and Ask at standard and largest text sizes, with exact content, orientation, colour, score and area-line assertions.
- Ace of Swords reversed, Queen of Pentacles upright and King of Swords upright cover completed picks and saved question/named-person readings at both text sizes, asserting all six position passages. The largest-text pick captures its real scroll origin, including Back and progress. Standard reading endings include the full reflection panel/helper, feedback choices and pinned Done/disclaimer.
- Existing main captures, Reduce Motion coverage, all accessibility audit categories, font-loading checks and the design-role guard remain unchanged. Fixed seeds were recalculated to retain the existing Star, Strength, High Priestess, Wands and Cups reference fixtures in the larger pool. The westward-travel fixture still begins with a deliberate unsalted repeat.

## Checks before the full run

`./scripts/harness doctor` passed on the checkout's dedicated iPhone 17e, iOS 26.5. A temporary host executable compiled the production `ReadingEngine.swift`, `QuestionReading.swift` and `CardIdentity.swift`, decoded the actual resource, reached all 156 daily outcomes, round-tripped 156 daily snapshots, and composed/round-tripped 936 readings covering every card/orientation/position. All assertions passed. This is production-engine evidence on the Mac, not an iOS test result.

## Design check

No screen, layout, type, colour, card-art or motion implementation changes; the design manifest remains unchanged. New long Minor Arcana names and original passages use the existing layouts. Run `.harness/runs/20261020T213558.334179Z-check-4ea0f29a` passed plain `./scripts/harness check` on clean `8e14dba6bdf6bd3a886359505086c0512d4bee9d`. It passed all 34 command-contract tests, the unchanged design-role guard and **137/137 logical iOS tests**, with zero failures, skips, expected failures or runtime warnings. Parameterised cases account for 173 executions. Xcode 27.0 used the dedicated iPhone 17e on iOS 26.5. The simulator lock was released at 01:04:57 UTC on 21 October.

Read the completed `summary.json` and `harness evidence`, opened `design-comparison.html` with `chrome-devtools-axi`, and inspected the five touched references against all 138 new full-screen content captures using contact sheets and direct originals. The run exports 896 images and matches all 15 main reference states. Overlapping largest-text captures show the full new names, passages and actions. No audit categories were filtered.

The specifically requested question-pick largest-text opening shows Back, All three drawn, the complete question and the first card. The standard question-reading ending shows the whole reflection panel/helper, all three feedback choices, pinned Done and disclaimer. Both Today endings show the final Social text, Ask, midnight caption and tabs. The named-person reading ending also shows all labels, but its feedback pills appear to have their lower edges partly occluded by the pinned footer. The independent reviewer confirmed this as RN4, a non-blocking evidence correction. The focused follow-up below checks maximum scroll before changing any layout.

The following reference differences are accounted for by the existing manifest or the intended content; independent comparison may identify further findings:

| Screen | Difference and reason |
| --- | --- |
| Reveal | Swords/Pentacles faces, names, orientations and keywords replace the reference Star. Long names wrap. Native status/safe areas, Share glyph, grain, face geometry and vertical spacing differ; the existing shape, colour and type roles and one primary action remain. At largest text Share gets a separate row and the action/disclaimer follow the content. |
| Today | The fixed Sunday date, new daily prose/extras/scores and Minor faces replace example values. The gear, dark selected tabs, static area rows without chevrons and shorter Ask entry are existing manifest choices. Content scrolls within the phone viewport; largest text stacks the thumbnail, extras and scores. |
| Ask | The context uses the actual daily card name, area line and score. Suggestions remain full reflective questions; the status options and Skip are full-width. There is no latest-reading row before a reading exists. Larger text stacks the selector and grows the controls while preserving their complete labels. |
| Completed pick | New identities and explicit orientations replace the example cards. The neutral question and You and Sam variant use the specified position types. Longer names cause unequal label baselines across standard-size columns, as in the already recorded Wands/Cups difference; all names and roles remain readable. Largest text stacks the cards and places the final action inline. |
| Reading | Original position text, the longer shared Relationship lens and the named-person introduction replace illustrative reference prose. This requires more scrolling. Headings use the existing darker accessible role; Done/disclaimer stay pinned at standard size and move inline at largest text. A fresh reading has no note. The named-person feedback-pill edge observation above is resolved by the focused follow-up below. |

The final evidence packet includes the unchanged manifest, reference images, all exported screenshots, comparison page, run summaries and logs. The independent review is recorded below. Still images do not establish motion timing, numeric contrast or persistence; the passing automated checks provide their separate evidence.

Real-device behaviour, VoiceOver reading order and Jackie's editorial review remain separate release checks.


## Independent comparison and dispositions

Firstmate's fresh-session reviewer inspected 187 supplied images, including all 138 new full-screen content captures, 16 contrast crops, five references, 16 main-screen regression images and all 12 Reduce Motion captures. Verdict: **pass, no must-fix findings**. Largest-text coverage and settled Reduce Motion states passed as image sequences. The report is retained with the task evidence as `independent-design-review.md`; images alone do not establish runtime behaviour, measured contrast, font registration or VoiceOver order.

| Finding IDs | Disposition and reason |
| --- | --- |
| C1–C3 | Accepted: real iOS status/safe areas and scrolling replace long web artboards; native text/icon/grain rendering varies; largest text grows, stacks and moves footers inline as the manifest requires. |
| RS1–RS4, RP1–RP3 | Accepted: the correct suit/rank artwork, explicit reversal, new names/metadata/keywords and long-name wrapping are intended content. Native spacing and heavier Share/arrow glyphs preserve the hierarchy; the separate large-text Share row and inline meaning action are specified. |
| TS1–TS5, TP1–TP3 | Accepted: fixture date, card identity, reflective prose/extras/scores and longer content replace examples. The gear, horizontal extras hairlines, static area rows without chevrons, darker labels, shorter Ask entry, midnight caption and dark selected tabs follow explicit manifest choices; tab symbols remain placeholders. |
| AS1–AS4, AP1–AP2 | Accepted: the actual daily name/area line/score replace the illustrative headline. Complete questions and roomier chips, full-width relationship choices with Skip, no recent-reading section before one exists, wrapping named-person helper and dark selected Ask tab are specified. |
| PQ1–PQ2, PQ4, PN1, PN3 | Accepted: the new spread identities, explicit orientations, neutral question or You and Sam title, named positions, retained disc, native spacing and stacked large-text cards preserve all required elements and the single Read my spread action. |
| PQ3, PN2 | Deferred to #27 at firstmate's explicit direction. Longer names leave standard-size completed-pick position labels on different baselines; this is the shared polish issue already deferred from #25. #27 covers comparing every finished screen to its reference and fixing or recording differences. No layout change in this content ticket. |
| RQ1–RQ4, RN1–RN3 | Accepted: actual question/named-person text, separate orientation lines, dedicated reflective positions and the neutral Relationship lens with Sam's introduction replace example prose. More scrolling, darker headings, native header glyphs and changing reflection height retain the section order. Done/disclaimer are pinned at standard size and inline at largest text; large-text cards/feedback stack and the decorative metadata dot is omitted as specified. |
| RN4 | Closed by author inspection of the focused follow-up, as firstmate authorised. The earlier capture was not at maximum scroll. Both corrected standard endings show complete feedback pills with clear space above Done; only test capture positioning changed. |

No reviewer recheck is required for RN4 after the author inspects its corrected capture, under firstmate's steering instruction. The single independent round is complete; that does not itself establish a pass of the changed test code.


## RN4 focused follow-up

`./scripts/harness doctor` passed. Run `.harness/runs/20261021T021612.229129Z-test-20dbb19b` then passed plain `./scripts/harness test` on `dac14ab`, selecting only the Swords/Pentacles reading UI test and retaining all engine tests. Result: **66/66 logical tests passed**, zero failures, skips, expected failures or runtime warnings; 81 exported images. The scheme selection was the only starting worktree difference and was restored byte-for-byte after the run. No audit categories were filtered. The lock was released at 02:39:32 UTC on 21 October.

The kept `reading-ending-scroll-*` records show both standard fixtures moved the final choice from y=654.67 to y=629.00 points, a further 25.67 points of scroll. A second upward drag left its frame unchanged, establishing the settled maximum. All three choices retain their 48-point height; the test also requires their complete frames and a minimum 12-point gap within the unoccluded scroll viewport. No trailing-space or control-size change was necessary in the app.

Read the completed summary and `harness evidence`, opened the comparison page, and inspected both corrected bottom originals plus the question largest-text completed-pick opening. Both endings now show complete pill outlines, the whole reflection panel/helper, feedback prompt, pinned Done and disclaimer. The largest-text opening still shows Back, progress and the full question. RN4 is closed under firstmate's author-capture path with no second independent round. The focused evidence, including raw frame attachments, is retained separately under `final-evidence/rn4-focused-follow-up/`; the initial independently reviewed images are preserved unchanged.

This focused pass is supplementary. The subsequent full run is recorded below.


## Final full check and isolated navigation failure

Plain `./scripts/harness check` ran on clean `cc323dda94b7289deb21ee38ea926735a3ea7eeb` with the full scheme restored. Run `.harness/runs/20261021T024957.235654Z-check-9bfe806c` passed all 34 command-contract tests and the design-role guard, then recorded **136/137 logical iOS tests passed**, one failure, zero skips or expected failures and no runtime warnings. Both Swords/Pentacles tests passed, including the corrected endings. The run exported 829 screenshots and matched all 15 main references; the lock was released at 06:17:15 UTC on 21 October.

The sole failure is `testWandsAndCupsDailyContentAtBothTextSizes`, line 2128: Today did not appear within five seconds after the first standard Knight of Wands Reveal audit and one meaning-button tap. XCTest's retained event targets (195, 745), the centre of the button's recorded frame. The failure hierarchy remains on the settled Reveal and contains no error alert. The same test and fixture passed in the initial full run; neither its implementation nor app code changed after that pass. Only the Swords/Pentacles ending capture and documentation changed. This supports a transient interaction after the audit, but does not prove its cause. No retry or weaker assertion was added.

Read the completed summary and `harness evidence`, opened the comparison page, and directly inspected both final corrected reading endings and the Pentacles Today ending. All feedback-pill outlines remain complete above Done, and the Today ending retains Social, Ask, midnight caption and tabs. The independent-review verdict and RN4 closure remain valid image findings; they do not make the failed full run green.

Firstmate's steering authorised one unchanged focused recheck of the failed flow. Run `.harness/runs/20261021T063059.536014Z-test-7203c002` passed plain `./scripts/harness test` on `cc323dd`: **66/66 logical tests**, zero failures, skips, expected failures or runtime warnings, with 74 exported images. The temporary scheme selected the Wands/Cups daily UI test while retaining all engine tests; it was restored byte-for-byte afterwards. No app or test implementation changed, and no audit categories were filtered. The simulator lock was released at 06:47:28 UTC on 21 October.

Read the recheck summary and `harness evidence`, opened its comparison page, and inspected the standard Knight of Wands Reveal and both Wands/Cups Today ending originals. The previously failing navigation completed, and the endings show the complete area content, Ask, midnight caption and tabs. Firstmate accepted the earlier failure as a dropped tap and authorised proceeding to no-mistakes. This unchanged pass supports that disposition without establishing the precise cause.

The failed full-run packet is retained separately under `final-evidence/final-full-check/`, including its summary, logs and failure attachments. The passing recheck is retained under `final-evidence/wands-cups-recheck/`. No latest-head full-suite pass is claimed.
