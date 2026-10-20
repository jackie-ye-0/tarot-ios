# Wands and Cups content verification

Issue #25. First draft, 20 October 2026. Jackie's editorial review is required before release to real users.

Current status: content and test implementation complete; static and host production-code checks pass. The full iOS check, screenshot inspection and independent comparison are pending the simulator window reserved by firstmate. This is not a verified delivery yet.

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

A separate attempt to typecheck the new Swift Testing suite with the host's default `swiftc` stopped at `no such module 'Testing'`. No toolchain change or workaround was attempted. The suite still needs compilation and execution through the Xcode harness after the simulator hold clears.

## Design check and remaining evidence

No screen, component, layout, colour, font or motion implementation changes. The manifest therefore remains unchanged. The content adds longer Minor Arcana names and new passages to existing layouts.

Before handoff, record the final committed-head `harness doctor` and full `harness check` results, inspect `harness evidence`, open the comparison page and inspect the new reading-text captures, including their actual endings and overlapping largest-text scroll stops. Compare content order, primary action, colours, type, card shape, spacing and wording in the manifest's order. Record every accepted difference and the independent comparison's findings and dispositions here.

The static content check is not an iOS build or runtime test. Real-device behaviour, VoiceOver reading order and Jackie's editorial review remain separate release checks.
