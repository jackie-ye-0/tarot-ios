# Swords and Pentacles content verification

Issue #26. First draft, 21 October 2026. Jackie's editorial review is required before release to real users.

Current status: implementation complete; full committed-head harness check and independent image comparison pending. The host checks below do not establish iOS verification.

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

No screen, layout, type, colour, card-art or motion implementation changes; the design manifest remains unchanged. New long Minor Arcana names and original passages use the existing layouts. The full run must supply the comparison page and final captures before visual findings can be recorded. Independent comparison is required before the completion handoff.

Real-device behaviour, VoiceOver reading order and Jackie's editorial review remain separate release checks.
