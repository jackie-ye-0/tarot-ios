# Ask foundation (#13)

Scope: the first complete Today → Ask → composer → three-card pick → reading path. Final screenshot inspection and independent comparison are pending; this document is not a verification claim until the final evidence section records a passing run.

## Behaviour and coverage

- Today and Ask have labelled icon tabs. The Today entry opens Ask; UI tests switch tabs and check that tabs are absent during Draw, Reveal, composition, picking and reading. Done and Close return to Today.
- Ask shows Career, Relationship and Social together. UI tests switch through all three sets of suggested questions, check their question marks and uniqueness, and exercise both field-shaped entry and a suggestion opening the composer.
- Composer validation rejects empty/whitespace-only questions. UI tests type a custom question and choose a suggestion; the primary action enables only with content. Engine tests cover whitespace and newlines separately.
- Three taps resolve three cards and orientations in Situation, Action, Outcome order. The engine test records every call to the injected source, checks the shrinking deck bounds, immutable earlier picks and no fourth draw. UI tests use a fixed source to expect The Star upright, The Sun reversed and The Fool upright.
- Composition takes the chosen orientation's position meaning for each section, the selected area's connecting passage and a deterministic reflection from the bundled pool. Unit tests cover all three lenses, exact position text and repeated input. UI tests traverse Relationship, Career and Social readings.
- A completed reading stores its question, area, cards, positions, orientation, text, timestamp and content version in one immutable SwiftData snapshot before showing the reading. A save retry reuses the already composed snapshot. The UI disk-store test relaunches with a different random source and opens the saved reading through a Debug-only entry, checking every displayed text field unchanged.
- Existing daily snapshots remain decodable without the new position meanings; a regression test removes those keys before decoding. The library itself requires complete new content. Six cards remain in their existing order, so daily selection is unchanged.
- All new colour, font and shape roles are in `DesignSystem.swift`. Existing font-family/PostScript assertions and the lexical design-role guard remain intact.

## Scope differences from the references

These are deliberate differences required by the issue boundary, to be confirmed against final captures. They are not exceptions to accessibility or action reachability.

| Screen | Difference and reason |
| --- | --- |
| Today | The existing basic card/interpretation gains the Ask entry and two tabs. Scores, extras, area readings and other fuller Today content belong to #9; Settings is #20 and the reminder is #21. |
| Today and Ask tabs | Two tabs rather than three, explicitly required by #13. History joins in #19. Icons use the platform symbols within the manifest's selected-pill and labelled-tab treatment. The selected pill uses ink fill and a surface-coloured icon after the native accessibility audit rejected the reference tint, including with an ink outline. The label remains ink on surface. |
| Ask | The context panel, recent reading and relationship-status prompt belong to #14. The named-person entry belongs to #18. The remaining content keeps the manifest's hierarchy and leaves open ground below the suggestions. Suggestions are actual questions, as required by #13 and the manifest, unlike the reference's topic phrases. |
| Composer, empty and filled | Character count/limit and the miniature empty-slot preview belong to #14. The explanatory three-card sentence remains above the primary action. The native keyboard Done key dismisses it; no accessory toolbar is added. |
| Three-card pick | Static reuse of the existing fan. Shuffle, pulse and restoration of unfinished picks belong to #15. A quiet instruction replaces the absent shuffle action. Empty slots have an explicit night-ground fill so their gold numerals retain contrast over the disc. The cards show the injected starter draw, rather than the reference's sample spread. |
| Completed pick | The same six-card starter art and original names replace the reference examples. Filled cards use the required gold outline and visible orientation text. |
| Reading | Original starter position meanings and the area lens replace the sample reading. Area-coloured section headings use darker partners (5.7–5.9:1 on plain ground) after the native audit rejected the former near-threshold relationship colour over grain. The saved label says “Saved on this phone” until History exists (#19). Feedback and More belong to #16; Share belongs to #23. Done remains the only primary action. |
| All touched screens | Native status bar and safe-area placement; bundled native font rendering and original deterministic grain can differ slightly from web/JPEG rendering. Larger text wraps and scrolls instead of being reduced to match the reference. |

The largest-text layout keeps three labelled area choices visible in a vertical segmented selector, moves the composer's Back control to its own row, stacks spread cards, and places the action after scroll content. Multiline controls use the surface radius to keep their text clear of the corners. These adaptations and states without reference images are described in `design.md` §11a.

## Keyboard isolation and audit determinism

The keyboard warning was attributed with one bounded, two-variant UI test on 14 October 2026 (local date), under the shared simulator lock. The intended multiline field without its accessory toolbar and a bare single-line field both passed, with zero runtime warnings in `.harness/ask-keyboard-no-toolbar.xcresult`. The comparison used real keyboard focus and typing in both variants. The original toolbar-containing composer emitted “Invalid frame dimension (negative or non-finite)” on focus in the prior full runs. The temporary diagnostic variant has been removed. The intended field now uses the keyboard's native Done key and `onSubmit` to dismiss focus, avoiding the accessory toolbar; full verification of that change is pending below. Diagnostic logs, summary and the two kept images are in the task's external evidence folder.

A fully visible ink heading intermittently failed contrast despite passing on the preceding empty composer and earlier identical-colour runs. Audit fixtures now disable root animations through the existing Debug Reduce Motion switch. Before capture and audit, the shared helper waits for the state-specific expected elements to exist and for their non-empty frames to remain unchanged across two reads. It uses a predicate expectation, with no fixed sleep, and keeps every audit category enabled without issue exceptions.

## Final evidence and independent comparison

Pending. The first dedicated-device run passed all 12 unit/font tests, but exposed UI integration and scrolling-test defects. No passing UI claim is made for that run. The tab-bar accessibility container and the scrolling viewport have been corrected; the next run must establish the result.

The final packet must contain the manifest, reference images, exported screenshots, comparison page, and a handoff identifying all states. Firstmate arranges the required fresh-session image comparison after the final screens are committed. Findings and their dispositions will be recorded here and in the eventual pull request.

## Remaining release limits

Content remains original draft writing requiring editorial review. Unfinished question/pick persistence is #14/#15; crisis handling is #17; History, export and deletion are their own tickets. No account, network, AI service or dependency was introduced. Manual VoiceOver reading order and real-device behaviour are not established by simulator screenshots or XCTest audits.
