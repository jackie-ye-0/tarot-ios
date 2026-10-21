# Swords and Pentacles content verification

Issue #26. First draft, 21 October 2026. Jackie's editorial review is required before release to real users.

Current status: the full check passed on clean `8e14dba` with 137/137 logical iOS tests passing, zero failures or skips. The author has inspected the new content captures; the independent image comparison is pending. This update records evidence only.

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

The specifically requested question-pick largest-text opening shows Back, All three drawn, the complete question and the first card. The standard question-reading ending shows the whole reflection panel/helper, all three feedback choices, pinned Done and disclaimer. Both Today endings show the final Social text, Ask, midnight caption and tabs. The named-person reading ending also shows all labels, but its feedback pills appear to have their lower edges partly occluded by the pinned footer. This is retained for independent assessment rather than claimed as a clean visual result.

The following reference differences are accounted for by the existing manifest or the intended content; independent comparison may identify further findings:

| Screen | Difference and reason |
| --- | --- |
| Reveal | Swords/Pentacles faces, names, orientations and keywords replace the reference Star. Long names wrap. Native status/safe areas, Share glyph, grain, face geometry and vertical spacing differ; the existing shape, colour and type roles and one primary action remain. At largest text Share gets a separate row and the action/disclaimer follow the content. |
| Today | The fixed Sunday date, new daily prose/extras/scores and Minor faces replace example values. The gear, dark selected tabs, static area rows without chevrons and shorter Ask entry are existing manifest choices. Content scrolls within the phone viewport; largest text stacks the thumbnail, extras and scores. |
| Ask | The context uses the actual daily card name, area line and score. Suggestions remain full reflective questions; the status options and Skip are full-width. There is no latest-reading row before a reading exists. Larger text stacks the selector and grows the controls while preserving their complete labels. |
| Completed pick | New identities and explicit orientations replace the example cards. The neutral question and You and Sam variant use the specified position types. Longer names cause unequal label baselines across standard-size columns, as in the already recorded Wands/Cups difference; all names and roles remain readable. Largest text stacks the cards and places the final action inline. |
| Reading | Original position text, the longer shared Relationship lens and the named-person introduction replace illustrative reference prose. This requires more scrolling. Headings use the existing darker accessible role; Done/disclaimer stay pinned at standard size and move inline at largest text. A fresh reading has no note. The named-person feedback-pill edge observation above remains open for review. |

The final evidence packet includes the unchanged manifest, reference images, all exported screenshots, comparison page, run summaries and logs. No new independent round has been claimed yet. Still images do not establish motion timing, numeric contrast or persistence; the passing automated checks provide their separate evidence.

Real-device behaviour, VoiceOver reading order and Jackie's editorial review remain separate release checks.
