# Crisis support verification

Issue #17 checks submitted question text before the three-card pick and routes matching phrases to support. It uses the existing reading engine, on-device store and design components. No service, dependency or networking is added.

## Behaviour and tests

- `CrisisRulesTests.syntheticDistressStopsReading` covers 16 synthetic self-harm, abuse and acute-distress phrases, including case, punctuation, whitespace and curly-apostrophe variants. Each is detected and rejected by reading composition even if three picks are supplied.
- `ordinaryQuestionsPass` covers 12 ordinary/empty inputs, including whole-word boundary near misses. `suggestionsPassAndIncompleteSafetyContentIsRejected` checks all bundled suggestions, approved editorial status, and rejection of empty or punctuation-only pattern lists.
- `testCrisisSupportClearsDraftWithoutDrawingOrSavingAndSurvivesRelaunch` submits through the real composer, verifies support without pick/reading controls or tabs, checks the exposed resource labels, returns to an empty composer, and verifies that the next ordinary spread still starts with the first injected random pair. A second match after editing that spread is followed by an immediate relaunch from support. The existing saved-reading test entry finds no reading; every Ask area has no saved reading.
- `testCrisisAfterEditingPickedSpreadKeepsSupportDuringRemovalFailureAndRetriesOnRelaunch` submits matching text after returning from a completed pick. It exercises rollback after failed draft deletion, visible support with a disabled return action, recovery on relaunch, and a fresh spread with no retained picks or reading.
- `testCrisisSupportLargestTextAndRemovalRetry` captures every resource at the largest text size, proves the removal retry and Back to Today remain reachable, and returns to Today after retry.

The submit guard runs before trimming/persisting a spread, consuming randomness or composing a reading. Matching text clears the in-memory question, picks and pending snapshot with draft persistence disabled, then removes both draft types transactionally. If the store cannot remove them, the support page explains the failure honestly and offers retry. A matching draft found during relaunch also opens support and retries removal; it cannot restore into the pick. Local-day changes update the daily destination without dismissing support. Previously saved daily cards and readings are retained.

The app adds no logging. Question text is never interpolated into diagnostics; UI test events contain only their synthetic fixture text. The engine returns a Boolean and composition throws a generic invalid-value error without including the question.

## Content boundary

`starter-cards.json` contains the phrase list, title, introduction, all resource text, Australian region, return action and removal-error wording. Its `crisis.editorialStatus` records Jackie's approval of the patterns, wording and Australian service region on 19 October 2026.

The approved service region is Australia. Contact details were checked on 16 October 2026 against [Lifeline crisis support](https://www.lifeline.org.au/get-help/national-services/lifeline-crisis-support) and [1800RESPECT](https://1800respect.org.au/). The screen clearly labels Australia and directs people elsewhere to their local emergency number or crisis service. Resource details are readable text; the app initiates no call or network request.

Whole-phrase matching is intentionally bounded. It normalises case, diacritics, apostrophes, punctuation and whitespace, but does not interpret meaning. It can miss unlisted distress or match benign/negated contexts. Automated cases establish the specified rule, not clinical effectiveness or readiness for real people.

## Design evidence

Support has no separate canvas reference. The same change describes its hierarchy, roles, layout, return action and failure state in `design.md` §11d. It reuses dawn ground/grain, title/section/body/metadata roles, hairlines, `ReadingScreenLayout`, `PrimaryAction` and `QuietAction`. The existing design guard is unchanged.

Kept capture names are `12-support`, `12-support--bottom`, `12-support--removal-failure`, and `12-support--largest-text` with overlapping resource, retry and bottom variants. Standard support and removal failure use the existing strict audit on settled elements. Largest-text captures assert full visibility of each resource, the retry action, and Back to Today after recovery. The disabled Back to Today in the largest-text failure state is not captured; independent finding F03 below records that limitation. Existing full-suite composer captures retain the `06-composer` and `06-composer-question-entered` reference names, default and largest-text variants. Existing Draw, Reveal and pick tests retain their Reduce Motion evidence. The composer itself has no visual change.

Initial check `20261016T110521.811824Z-check-1ad9844a` passed the crisis engine cases, direct support UI/audit, and largest-text/removal-retry case. The edited-spread fixture inserted its phrase before existing text, producing “safeWhere”; its support assertion correctly failed because the whole-phrase match did not include that concatenated word. The retained hierarchy was inspected, and the fixture now ends its synthetic sentence with punctuation and verifies the entered text before submitting. The remaining run was deliberately interrupted after these three crisis tests; its failure result is not verification. The new support top and largest-text removal message were visually inspected without finding a layout defect.

Complete check `20261016T113758.878741Z-check-49a497b2` passed 79 of 80 logical tests (108 of 109 parameter-expanded cases), with no skips or runtime warnings. The corrected edited-spread/relaunch case passed. The sole failure was `testCrisisSupportLargestTextAndRemovalRetry`: its long removal paragraph did not settle fully inside the viewport. The retained recording shows the helper alternating between the paragraph's top and bottom, while the earlier run had fitted it. The support copy was shortened to preserve the removal failure and recovery instruction in a more scannable paragraph. The visibility assertion, shared scrolling helper and all audit categories remain unchanged. This is the first correction for this separate largest-text failure.

## Final local result

`./scripts/harness check` passed in `20261016T130156.586584Z-check-0a43c91c`: all **80 logical iOS tests / 109 parameter-expanded cases** passed, with zero failures, skips, expected failures or runtime warnings. All **34 command-contract tests**, the unchanged design-role guard, and `testBundledTypefacesDoNotFallBack` passed. The device was the worktree's iPhone 17e simulator on iOS 26.5. The run records base `67129d5` plus the working-tree changes; app and test sources were unchanged after this run, with only verification documentation completed afterwards.

`./scripts/harness evidence` and the final `design-comparison.html` were inspected. The comparison page was opened through `chrome-devtools-axi`. Every final `12-support` capture was viewed: normal top/bottom, removal failure, largest-text opening, each resource/title/contact/detail, outside-region guidance, shorter removal paragraph, retry and final Back to Today. The shorter paragraph and retry fit together, and the final action remains fully reachable. The two standard composer captures were compared with their references, with its largest-text opening and both enabled/disabled action captures also inspected. No new visual defect was found.

The full run includes 11 of 15 referenced screen states. Missing `04-today-first-day`, `07-about-someone`, `10-history` and `11-settings` belong to other assigned work; none is added or visually changed here. Support intentionally has no reference image and is reviewed against §11d. Existing Draw, Reveal and pick Reduce Motion captures remain present and passing.

## Author comparison and accepted differences

| Screen/state | Observation and disposition |
| --- | --- |
| Support, normal | No canvas reference. Dawn roles, page guide, title/body hierarchy, hairline-separated resource sections and one pinned primary action match §11d. The outside-region paragraph crosses the initial scroll boundary; the bottom capture shows it fully. Accepted as ordinary scrolling under §§4 and 11. |
| Support, removal failure | The short explanation and quiet retry appear after the resources; Back to Today uses the disabled role until removal succeeds, as §11d specifies. The question and cards are absent. No deviation found. |
| Support, largest text | Type grows and wraps naturally; content spans overlapping scroll captures. Contact digits remain complete; retry and the recovered Back to Today are fully visible in their named captures. The disabled primary in the failure state was not visually inspected at this size (F03). The action moves inline with the shared layout, as §§9 and 11d require. Cropped adjacent content at viewport edges is accepted because each resource is separately captured fully visible. |
| Composer, both standard states | Native status area, larger back glyph and narrower/right-shifted selector differ from the web references. Accepted under §4's native safe areas/real targets and §11a's composer layout; content order and complete labels remain. Header/field spacing is separately recorded as optional follow-up C04/Q01 below. |
| Composer, type and grain | The title wraps after “ask”, glyph weights/leading differ, and native grain is denser. Accepted under §12's native text rendering allowance and §2's texture rule; bundled fonts pass their identity check. |
| Composer, preview and action | Dashed slots are darker/more widely spaced, the helper wraps differently, and the enabled arrow is heavier/more separated. The action sits slightly higher than the reference. Accepted under §§5 and 11–11b components, side guides and native footer clearance. The shorter suggestions-to-preview gap is part of optional follow-up C04/Q01. |
| Composer, largest text | The selector stacks, text and actions wrap, preview sits above its helper, and actions move inline with surface-style corners. Accepted explicitly required §§11–11b adaptations. The enabled and disabled primary actions fit completely. |

These composer differences are the existing choices detailed in [Ask/composer verification](ask-composer-verification.md); this ticket changes submission routing, not composer styling.

## Independent comparison

A fresh reviewer inspected the final evidence on **17 October 2026** and returned **PASS, with no must-fix visual defect**. The reviewer read only the handoff, manifest and images, without implementation code, tests, logs or prior review conclusions. All 46 composer/support screenshots (including element crops), both composer references and seven supplementary Reduce Motion captures were opened individually: **55 images** in total. The reviewed implementation is commit `29a6883678bc5bd4f798da29f801fcc937823fb1`; this record update changes no app, test or manifest source.

The full report is retained in the task evidence as `final-evidence/independent-design-review.md`. The following dispositions must also accompany the eventual pull request. Firstmate accepted the two should-fix items as optional follow-ups and instructed that neither change code in this issue; neither is claimed as fixed or assigned to an unrelated later ticket.

| Finding | Disposition and reason |
| --- | --- |
| S01 | Accepted. Reassurance, introduction, subordinate region label, emergency help, Lifeline, 1800RESPECT and outside-region guidance follow §11d's hierarchy. |
| S02 | Accepted. Dawn grain, dark title/contact text, softer body text, hairlines and common side guides use the shared roles without extra panels. Exact font identity and numerical contrast are established by the separate tests, not this image review. |
| S03 | Accepted. One full-width Back to Today stays pinned at ordinary size; the bottom capture shows all outside-region guidance above it. No question, cards, tabs, ritual disc or extra primary action is visible. |
| S04 | Accepted. The outside-region paragraph crosses the initial scroll boundary but is complete in the bottom capture, with footer clearance. This is ordinary scrolling under §§11–12, not permanent clipping. |
| S05 | Accepted. Uppercase 1800RESPECT is the service's supplied proper name, not an arbitrary all-caps interface label. Jackie approved the content and Australian service region on 19 October 2026. |
| F01 | Accepted. Failure wording truthfully reports that removal failed and provides a recovery instruction; support resources remain available. |
| F02 | Accepted. Retry uses a quiet action and the ordinary-size return action uses the disabled role. The complete explanation and both retry-label lines fit at largest text. |
| **F03, optional evidence follow-up** | **Not changed.** Add a largest-text bottom capture before retry succeeds, showing the disabled Back to Today in full, ideally with retry above it. Current captures establish the reachable recovery action and the primary label after recovery, but do not show the disabled largest-text footer. The reviewer found no observed layout failure, so this evidence improvement is non-blocking. |
| C01 | Accepted. Native status icons/time and greater bottom clearance preserve real system chrome and safe areas; §4 prohibits a fake status bar. The action remains full width and reachable. |
| C02 | Accepted. The larger/heavier, farther-right back glyph and narrower/right-shifted selector allocate space for a native back control; all three labels remain visible. This is compatible with the 44-point target rule, whose actual bounds are outside the image review. |
| C03 | Accepted. The title wraps after “ask” rather than “to”, with small glyph weight/metric differences in headings, input and action. Native rendering retains the two-line display/body hierarchy under §12. |
| **C04/Q01, optional spacing follow-up** | **Not changed.** In both composer states the title begins about 15 points lower, field 25–30 points lower and suggestions 35–40 points lower than the references, compressing the final gap before the preview. Review selector-to-title, guidance-to-field and count-to-suggestions gaps together against the shared 24–28-point rhythm while preserving native safe areas. This shares the spacing concern identified as Settings' C2. All content remains present and usable; the reviewer and firstmate accepted it as a non-blocking refinement. |
| C05 | Accepted. The native grain looks more mottled/coarse and slightly different in warmth, while surface, ink, secondary-copy and disabled-fill roles remain consistent. §§2 and 12 permit native texture differences rather than a pixel match to the web/JPEG reference. |
| C06 | Accepted. Placeholder placement/weight and chip border/width vary slightly with native metrics; the field's tall rounded outline and readable, padded chip labels retain the required shape and hierarchy. |
| C07 | Accepted. Slot outlines are darker, their dashes shorter/thinner, their dimensions/spacing slightly different and corners less visibly round. They retain three small empty tall slots with card proportions. Helper wrapping changes without losing words, order or meaning, as §11b permits. |
| C08 | Accepted. The disabled primary sits slightly higher with narrower/lighter-looking lettering. Its full-width pill, muted role, exact wording and native footer clearance remain appropriate. |
| C09 | Accepted. Guidance, placeholder, count, three suggestions, preview, helper and disabled action are complete and in reference order across the top/bottom captures. |
| Q02 | Accepted for the same concrete reasons as C01–C03 and C05–C07. Native chrome/control allocation, type, texture, field/chips and preview differences recur in the populated state. |
| Q03 | Accepted. The enabled arrow is heavier/larger and farther from the slightly narrower label. The group remains centred with ample padding and the correct dark pill/surface-text roles. |
| Q04 | Accepted. The question, `20 / 300`, suggestions and helper match; replacing the placeholder enables the primary as required. |
| Q05 | Accepted. The populated bottom capture partly scrolls the selector out and shows a taller field. The question, count, suggestions and footer remain readable across the pair; §11a permits scrolling/reflow without fixing the field to the reference height. The cause of the height difference is not established by images. |

Largest-text composer captures pass: the selector reflows, labels and suggestions remain whole, preview moves above its helper, and enabled/disabled actions remain fully readable inline. The populated primary wraps to three lines with padding, which is accepted instead of shrinking text. Keyboard captures show the focused question above the keyboard and the complete action after dismissal. Different synthetic question/count values are intentional fixtures. The limit capture contains the long question and uses the words “Limit reached” as well as the error colour; no largest-text limit-specific capture was supplied or certified.

Largest-text support captures show every heading, number and paragraph in full somewhere in the overlapping sequence. The longer contact number wraps between number groups without losing digits. Failure explanation/retry pass, subject to F03; the recovered primary fits with clear margins. Viewport-edge fragments are accepted where another capture shows the whole component.

All seven supplementary Reduce Motion captures depict coherent settled Welcome, Draw, Reveal and pick states, with no visible regression. Still images do not prove animation timing, first-paint behaviour or interruption, and the evidence packet contains no motion filmstrip. Support/composer have no new ritual motion and are outside §12's named ritual-capture requirement.

This independent pass is visual only: it does not establish crisis matching, persistence, logging, network/call behaviour, actual accessibility labels/targets, numerical contrast or font identities. The earlier functional tests, audits and font check supply their own evidence. Approval of the pattern list, copy and Australian service region was given separately by Jackie on 19 October 2026.

Real-device behaviour and manual VoiceOver reading order remain outside this simulator evidence.
