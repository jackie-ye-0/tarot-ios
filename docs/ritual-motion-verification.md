# Draw and Reveal ritual motion (#10)

Scope: Draw (washing, unselected and chosen states) and Reveal. Today remains the foundation screen; its captures verify the existing navigation and saved reading. No reading rule, store format, dependency or service changes.

## Behaviour and evidence

- `Design.Motion` sets two 0.45-second washes and a 0.8-second fan opening, a 1.1-second flip, a 1.6-second dawn transition and 0.65-second text rises staggered by 80ms. The manifest describes the intermediate states without references.
- The five fixed buttons sit above the decorative cards. An early pick cancels the shuffle task and replaces its presentation with the chosen state immediately. Selection, undo and repeated shuffles cannot change the engine's seed, date or daily result.
- `testShuffleInterruptionReplayUndoAndSameDailyCard` holds a real wash phase through Debug configuration, audits it, picks during it, undoes, replays twice and compares the revealed card/orientation against an unshuffled launch at another position. The existing engine tests cover deterministic results and all five positions.
- `testDrawRevealTodayAndDesignEvidence` exercises normal animation, verifies the chosen state before naming its capture, audits Draw, chosen Draw and Reveal, checks the final metadata, and follows the meaning action to Today.
- `testAnimationOffSkipsEvenHeldShuffle` and `testLargestTextAndReduceMotion` verify that animation-off and Reduce Motion independently bypass the hold, expose all five targets, and present the complete Reveal immediately. The Debug settled value is already set in these states; no animation task gates the controls.
- Audits and captures wait for a Debug-only accessibility value driven by SwiftUI's animation completion, rather than a fixed animation delay. Old completions cannot mark a newer shuffle settled. Every audit category remains enabled; the issue callback retains diagnostic text and returns false so every issue still fails.
- The existing largest-text layout moves ritual actions inline, with scroll and visibility assertions for the fan, shuffle helper, chosen action and Reveal metadata/disclaimer. Font-loading tests and the unchanged lexical design guard remain part of the full check.

## Corrections found during verification

The first contrast failure identified the newly inserted chosen-state footer. We removed its global animation and added a completion wait. A separate failure persisted on the settled underlined link, reporting a generic SwiftUI node with no exposed element. Drawing the gold underline separately from the text eliminated that failure without changing the palette or suppressing issues. Both focused tests then passed. The fixed tap layer also explicitly paints above the decorative cards, and screenshot tests now assert successful selection before naming a chosen-state attachment.

## Reference comparison

The author inspected all 23 final exported screenshots and opened the generated comparison page beside the Draw, chosen Draw and Reveal references. The following visible differences are retained with their reasons. Independent comparison is pending; these are author dispositions, not an independent verdict.

| State | Retained difference and reason |
| --- | --- |
| All ritual screens | Real system status indicators replace the mock's empty status area. The manifest prohibits a fake status bar. Small glyph, grain and rasterisation differences follow native rendering; bundled-font assertions verify the named typefaces. |
| Draw and chosen Draw | Sunday is correct for the injected 11 October 2026. History is absent because navigation beyond the daily ritual is outside #10; this is the existing foundation scope in §11. |
| Draw and chosen Draw | The subtitle is slightly larger/lower and the disc/fan anchor remains roughly eight points lower than the web reference. These retain the foundation's shared spacing and native font metrics, so selection does not shift the composition. Minor back-art ray/stroke and texture differences preserve the original shared drawing, as accepted in the foundation comparison. |
| Draw | The helper uses the manifest's 13-point caption role; the web helper appears larger. The gold underline is a separate decorative rule to retain the reference appearance while allowing the unfiltered contrast audit to assess the text. Native safe-area spacing places the footer slightly higher. The action and explanatory wording now match the reference. |
| Chosen Draw | The selected card stays in front of dimmed neighbours so its identity remains unobscured. Scaling the whole card slightly scales its strokes while preserving its 5:8 shape. Its final size, raised position and the footer's native safe-area placement retain the foundation's accepted composition. |
| Reveal | Share remains absent because it is outside #10's motion criteria and the existing foundation scope. The card follows the manifest's 214 × 342.4-point, 5:8 shape rather than the slightly taller web drawing, with a corresponding small difference in name spacing. |
| Reveal | Small star/core, dot, hill and wave-contour differences retain the foundation's original procedural art rather than reproducing the reference raster. Named palette roles are unchanged. The subtle ochre halo is the requested rising sun glow, now described in §7. The arrow glyph and footer placement use native rendering and safe-area spacing. |
| Accessibility variants | Larger uncapped text, inline footers and scrolling intentionally replace the standard composition according to §11. The overlapping captures show all required content and reachable actions without clipped text. Reduce Motion captures show the complete resting states. |

Washing and the intermediate flip, warming, glow and text-rise states have no separate reference and are described in §7. Today and storage-error screenshots are unchanged regression coverage; their existing scope and dispositions remain in [foundation verification](foundation-verification.md).

## Full validation

`./scripts/harness check --device 8A7A396B-8076-4459-A1E5-C057F7908D92` passed under the shared simulator lock in `.harness/runs/20261013T151828.857730Z-check-33bf6d6a/`: **32 Python command/design checks and 16 iOS tests**, with zero failures, skips or expected failures. The device was iPhone 17e Tarot 3 on iOS 26.5, using Xcode 27.0. The iOS tests include engine rules, bundled-font loading, real-app interactions and unfiltered accessibility audits. The lexical design-system guard is unchanged.

`./scripts/harness evidence` was inspected. All 23 kept screenshots were exported and visually inspected, including standard, largest-text and Reduce Motion captures for the touched ritual states. The reference-named main captures are `02-draw`, `02-draw-card-chosen` and `03-reveal`; variants retain that prefix. The comparison page was opened through chrome-devtools-axi. Missing main screenshots in the run summary belong to other screens outside #10; strict all-screen coverage was not requested.

Simulator recordings were also inspected frame by frame: the entry wash settles into the fan and changes its caption, the card switches faces while edge-on without mirroring the front, the ground warms and the name, orientation and keywords follow in short rises. The primary action stays present. Recordings supplement the deterministic interruption and animation-off tests; they do not replace them. The final evidence packet retains the manifest, reference images, exported captures, comparison page and run metadata outside Git for the independent review.

## Limits

The held phase makes interruption deterministic despite XCTest's automatic idle wait; ordinary animation is exercised separately. Still images cannot prove motion or first-paint timing: those claims also rely on the launch paths, completion signals and simulator recording. System Reduce Motion is read by the same root policy as the Debug override; simulator-wide settings were not changed. Real-device feel and a manual VoiceOver pass remain release checks, as in the foundation slice.
