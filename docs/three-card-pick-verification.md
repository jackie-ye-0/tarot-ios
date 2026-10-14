# Three-card pick in full (#15)

15 October 2026. Independent design comparison completed with one required correction, P06. The glyph correction is implemented; its full check and four replacement opening captures are pending. No push or delivery pipeline has run yet.

## Verified run

`./scripts/harness check` passed on clean `f0dec7889f4d0652a908c8e61a55a31aa7552979` in `.harness/runs/20261014T185235.975661Z-check-c0437277`: **34 command tests, the design-role guard and 63/63 iOS tests** (29 unit, 34 UI), with zero failures, skips, expected failures or runtime warnings. The toolchain was Xcode 27.0, build 27A266a, on this checkout's iPhone 17e simulator running iOS 26.5. This was the first full check of this change; there were no failed iOS runs to exclude.

The doctor and check used the harness's shared simulator queue without a device override or outer lock. The check acquired the lock at 19:48 UTC and released it at 20:26 UTC on 14 October. Queue time is not test execution time.

The author inspected `harness evidence`, opened the run's `design-comparison.html`, and visually inspected both main pick captures, all 17 pick variants, both composer reference pairs and all 12 largest-text composer captures. The unchanged composer is included because Back and draft restoration use it. Inspection does not claim a new review of every unrelated screen captured by the full suite.

## Acceptance evidence

| Requirement | Evidence |
| --- | --- |
| Five face-down cards, daily shuffle motion each round | `testSpreadShuffleSettlesEachRound` waits for each of three fans to settle. The pick uses the existing `CardFan`, the same two 0.45-second washes and 0.8-second fan opening, and five fixed, live tap lanes. |
| Quiet Shuffle before every pick, no pick consumed | `testSpreadShuffleNeverConsumesPickAndCanBeInterrupted` shuffles twice in every round, checks all five targets, unchanged slots and progress, and the exact helper “Shuffling never uses up a pick.” The injected draw remains Star upright, Sun reversed, Fool upright. |
| Position prompt and Card n of 3 | The same UI test checks all three progress values and Situation, Action and Outcome prompts. The design/audit test captures zero, one, two and three picked states. |
| Gold active outline, slow pulse, locked filled slots | `EmptySpreadSlot` pulses only its gold outline over a two-second half-cycle; its numeral stays still. Filled cards are not controls. UI tests tap each filled slot and assert the same card and progress. Engine tests prove earlier picks remain unchanged, no replacement and no fourth pick. |
| Interruption and relaunch restore question and picks | `testSpreadDraftSurvivesBackgroundRelaunchAndClearsAtReadingOrAsk` backgrounds and relaunches an isolated disk store at every stage from zero to three picks. Returning through Ask restores the question and exact saved slots while preserving the approved daily launch route. |
| Clear draft on reading creation or Back to Ask | The same UI test verifies both exits after relaunch. `testDraftSaveRetryKeepsPickAndReadingSaveClearsDraft` verifies the saved reading and absent draft. The store saves the reading and removes the draft in one transaction. |
| Back retains the question | The relaunch UI test returns to the composer at every stage and continues with the same locked picks. The unit test also edits the question and area after Back and restores both. |
| Reduce Motion has no shuffle and immediate targets | The interruption test runs with animations enabled and the hold-shuffle fixture, both with and without Reduce Motion. The reduced fan reports settled and exposes five tappable cards in every round. Both pick references also have `--reduce-motion` captures. |
| Recoverable storage failure | The UI save-failure test captures the native alert, retries, then completes the reading. Unit tests verify a failed pick save keeps that exact pick, retry saves it without another draw, and failed draft discard retains the composer until retry succeeds. |

The pure-engine tests also round-trip a draft, continue without repeating a saved card, and reject invalid position order, duplicate cards, too many picks and a blank question in the picking state. Draft reads fail through the existing recoverable storage-open screen rather than silently deleting a corrupt draft.

## Design check and accepted reference differences

The main kept attachments are `08-three-card-pick` and `08-three-card-pick-complete`. Variants cover one/two picks, a naturally settled shuffle, a draft-save alert, both Reduce Motion states, and overlapping largest-text scroll stops through the slots, fan, Shuffle and Read my spread. Composer captures retain their established `06-composer` names. The native accessibility audit ran every category on settled screens: all four pick-state audit records are empty arrays, with no findings or measurement overrides. Composer audits and bundled-font registration checks passed. The lexical design-role guard passed unchanged.

The largest-text images show whole labels and reachable actions. Items cut by the viewport at an intermediate scroll stop are fully visible at an adjacent retained stop. The composer field stays above the keyboard, and Done exposes the inline primary action. Static captures establish layout, while the motion tests exercise sequence completion, interruption and Reduce Motion.

| Screen | Visible difference retained and reason |
| --- | --- |
| Picking | The existing native status bar, 44-point Back control, 24-point ritual side guides, bundled-font metrics and deterministic grain differ from the web/JPEG reference. They preserve the manifest's native safe area, touch targets and visual roles. The compact fan uses the established narrower offsets and card-back drawing; the larger disc remains shared across picking and completion. Empty slots retain their explicit night-ground fill so numerals keep consistent contrast over the disc. These inherited #13 treatments remain unchanged. |
| Picking | Shuffle now replaces the temporary “Each pick fills the next position” footer and matches the reference's quiet underlined action. The helper adds a final full stop, following the app's sentence punctuation. The active gold dashed outline now pulses as required by #15; the still Reduce Motion state retains the reference treatment. |
| Completed pick | The synthetic test source draws Star upright, Sun reversed and Fool upright instead of the example Two of Cups, Temperance and Sun. Artwork follows the landed #12 face grammar. Both Upright and Reversed appear explicitly, adding a line to upright cards and keeping position labels on a common row. The existing footer uses the manifest's type and spacing roles and stays pinned at standard size; it moves inline and wraps at accessibility sizes. These inherited differences keep real draw identity, orientation and action reachability clear. |
| Composer, empty and filled | No new visual change. Native font metrics wrap the title after “ask”, with the established safe-area placement and section spacing. The reference's character counter/limit and miniature slot preview remain assigned to #14, whose acceptance text explicitly covers both. The explanatory three-card sentence and primary action remain visible. |
| Largest text and error state | Stacked slots, multiline controls, inline footers and a system save-error alert have no separate reference images. Their rules and the new draft navigation/error states are documented in `design.md` §11a. |

The comparison page also reports missing Today-first-day, About Someone, History and Settings main captures. Those screens belong to other tickets and are not claimed by this verification.

## Independent comparison and limits

A fresh session reviewed the four references and all 35 relevant built images using only the images, manifest and state list. Its verdict was **pass after P06, the fixed-size Back glyph correction**. Firstmate authorised fixing only P06, retaining the other differences below, and an author inspection of four replacement largest-text opening captures without another independent round. The complete original report is retained in the task's final evidence as `independent-review.md`.

| Review IDs | Disposition and manifest reason |
| --- | --- |
| P06, C06, E06/Q06 glyph portion | Fixed once inside the glyph-only `NavigationAction`: `.dynamicTypeSize(.large)` keeps the symbol at its standard size while the existing frame retains a minimum 44 × 44-point target. No text label is constrained. This implements §11's fixed decorative-icon rule and keeps the composer's separate Back row. Four opening captures require inspection after the clean-commit full check. |
| P02, C01 spacing portion | Retained the modest ordinary-size vertical-rhythm difference at firstmate's direction. The native safe area, existing section-spacing roles and compact fan remain consistent with §§4/11a, leaving clear space for the prompt and five separate tap lanes. No forced reference-pixel offsets or shared-layout compression were introduced. Fan overlap and motif proportions remain acceptable under §11a's compact-offset treatment. |
| E02, Q01 spacing/wrapping portion | Retained the existing selector-to-title and guidance-to-field spacing roles and natural title wrapping. §§4/12 permit native type metrics and scalable layout; matching the web wrap with forced breaks or tighter fixed gaps would weaken that consistency. This is an accepted fidelity difference, not deferred work in another ticket. |
| P01, E01, C01 native-chrome portion | Accepted native status chrome, normal-size symbol weight, reserved Back target and 24-point night/20-point dawn guides under §§4/6. The large-glyph exception is fixed by P06. |
| P03, E04, Q01 texture/control-metric portion | Accepted original deterministic grain, decorative disc extent, slightly different field/chip metrics and solid night slot fill under §§2/5/12. The fill stabilises numeral contrast; the disc has no prescribed exact diameter. |
| P04 | Accepted minor outline/type weight, shuffle-footer clearance and the helper's final full stop. Named roles and hierarchy remain intact; §§11a/12 specify the copy and allow native rendering differences. |
| P05 | Accepted extra name/orientation rows and differing filled/empty position baselines in intermediate states. §11a requires explicit names, orientations and sequential slots; all positions and the next-pick instruction remain visible. |
| P07 | Accepted the native save-error alert and its system font/colours, explicitly described by §11a. The normal-size alert fits; no largest-text error-state visual claim is made. |
| C02, C03 | Accepted actual fixture cards, full-deck face grammar, equal slot/front footprints and explicit Upright/Reversed text. §§5/11a govern these identities and labels; reference cards are examples. |
| C04, E05, Q03 | Accepted native footer wrapping, symbol weight and bottom clearance. Actions remain full width within their night/dawn guides, with one primary action and the correct enabled/disabled wording; §§4/11a preserve the adaptive button shape. |
| C05, E06 reflow portion | Accepted stacked slots/selector, separate composer Back row and multiline inline actions at accessibility sizes under §§11/11a. Only the decorative glyph stops scaling. |
| E03, Q02 | Accepted missing character counter/limit and miniature slot preview because #14 explicitly owns both, as documented in §11a. |
| Q04, Q05 | Accepted editable keyboard-fixture wording, field scrolling to the top and below-viewport suggestions/actions. §11a defines this focus/dismissal behaviour; adjacent and dismissed captures show the complete content. Viewport cropping does not establish a clipped control layout. |

The review did not establish animation duration, first-paint behaviour, target bounds, font identity, contrast or persistence from still images. The functional tests and strict audit above provide that separate evidence. Largest-text partial-spread/error combinations and real-device behaviour were not visually reviewed. The final description must include the verdict, dispositions and `Closes #15`.

No dependencies, services, network calls or simulator settings were added. Questions before their first submission remain in memory until #14. Real-device behaviour and manual VoiceOver order remain unverified; the automated audit is not a substitute for that release check.
