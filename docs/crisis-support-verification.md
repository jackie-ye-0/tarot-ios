# Crisis support verification

Issue #17 checks submitted question text before the three-card pick and routes matching phrases to support. It uses the existing reading engine, on-device store and design components. No service, dependency or networking is added.

## Behaviour and tests

- `CrisisRulesTests.syntheticDistressStopsReading` covers 16 synthetic self-harm, abuse and acute-distress phrases, including case, punctuation, whitespace and curly-apostrophe variants. Each is detected and rejected by reading composition even if three picks are supplied.
- `ordinaryQuestionsPass` covers 12 ordinary/empty inputs, including whole-word boundary near misses. `suggestionsPassAndIncompleteSafetyContentIsRejected` checks all bundled suggestions, placeholder marking, and rejection of empty or punctuation-only pattern lists.
- `testCrisisSupportClearsDraftWithoutDrawingOrSavingAndSurvivesRelaunch` submits through the real composer, verifies support without pick/reading controls or tabs, checks the exposed resource labels, returns to an empty composer, and verifies that the next ordinary spread still starts with the first injected random pair. A second match after editing that spread is followed by an immediate relaunch from support. The existing saved-reading test entry finds no reading; every Ask area has no saved reading.
- `testCrisisAfterEditingPickedSpreadKeepsSupportDuringRemovalFailureAndRetriesOnRelaunch` submits matching text after returning from a completed pick. It exercises rollback after failed draft deletion, visible support with a disabled return action, recovery on relaunch, and a fresh spread with no retained picks or reading.
- `testCrisisSupportLargestTextAndRemovalRetry` captures every resource at the largest text size, proves the removal retry and Back to Today remain reachable, and returns to Today after retry.

The submit guard runs before trimming/persisting a spread, consuming randomness or composing a reading. Matching text clears the in-memory question, picks and pending snapshot with draft persistence disabled, then removes both draft types transactionally. If the store cannot remove them, the support page explains the failure honestly and offers retry. A matching draft found during relaunch also opens support and retries removal; it cannot restore into the pick. Local-day changes update the daily destination without dismissing support. Previously saved daily cards and readings are retained.

The app adds no logging. Question text is never interpolated into diagnostics; UI test events contain only their synthetic fixture text. The engine returns a Boolean and composition throws a generic invalid-value error without including the question.

## Content boundary

`starter-cards.json` version 4 contains the phrase list, title, introduction, all resource text, provisional region, return action and removal-error wording. Its `crisis.editorialStatus` explicitly marks them **PLACEHOLDER**, requiring Jackie's sign-off on patterns, wording and region before real-user release.

The current placeholder region is Australia. Contact details were checked on 16 October 2026 against [Lifeline crisis support](https://www.lifeline.org.au/get-help/national-services/lifeline-crisis-support) and [1800RESPECT](https://1800respect.org.au/). The screen clearly labels Australia and directs people elsewhere to their local emergency number or crisis service. Resource details are readable text; the app initiates no call or network request.

Whole-phrase matching is intentionally bounded. It normalises case, diacritics, apostrophes, punctuation and whitespace, but does not interpret meaning. It can miss unlisted distress or match benign/negated contexts. Automated cases establish the specified rule, not clinical effectiveness or readiness for real people.

## Design evidence

Support has no separate canvas reference. The same change describes its hierarchy, roles, layout, return action and failure state in `design.md` §11d. It reuses dawn ground/grain, title/section/body/metadata roles, hairlines, `ReadingScreenLayout`, `PrimaryAction` and `QuietAction`. The existing design guard is unchanged.

Kept capture names are `12-support`, `12-support--bottom`, `12-support--removal-failure`, and `12-support--largest-text` with overlapping resource, retry and bottom variants. Standard support and removal failure use the existing strict audit on settled elements. Largest-text captures assert full visibility of each resource and both actions. Existing full-suite composer captures retain the `06-composer` and `06-composer-question-entered` reference names, default and largest-text variants. Existing Draw, Reveal and pick tests retain their Reduce Motion evidence. The composer itself has no visual change.

Initial check `20261016T110521.811824Z-check-1ad9844a` passed the crisis engine cases, direct support UI/audit, and largest-text/removal-retry case. The edited-spread fixture inserted its phrase before existing text, producing “safeWhere”; its support assertion correctly failed because the whole-phrase match did not include that concatenated word. The retained hierarchy was inspected, and the fixture now ends its synthetic sentence with punctuation and verifies the entered text before submitting. The remaining run was deliberately interrupted after these three crisis tests; its failure result is not verification. The new support top and largest-text removal message were visually inspected without finding a layout defect.

Complete check `20261016T113758.878741Z-check-49a497b2` passed 79 of 80 logical tests (108 of 109 parameter-expanded cases), with no skips or runtime warnings. The corrected edited-spread/relaunch case passed. The sole failure was `testCrisisSupportLargestTextAndRemovalRetry`: its long removal paragraph did not settle fully inside the viewport. The retained recording shows the helper alternating between the paragraph's top and bottom, while the earlier run had fitted it. The placeholder copy was shortened to preserve the removal failure and recovery instruction in a more scannable paragraph. The visibility assertion, shared scrolling helper and all audit categories remain unchanged. This is the first correction for this separate largest-text failure.

## Final local result

`./scripts/harness check` passed in `20261016T130156.586584Z-check-0a43c91c`: all **80 logical iOS tests / 109 parameter-expanded cases** passed, with zero failures, skips, expected failures or runtime warnings. All **34 command-contract tests**, the unchanged design-role guard, and `testBundledTypefacesDoNotFallBack` passed. The device was the worktree's iPhone 17e simulator on iOS 26.5. The run records base `67129d5` plus the working-tree changes; app and test sources were unchanged after this run, with only verification documentation completed afterwards.

`./scripts/harness evidence` and the final `design-comparison.html` were inspected. The comparison page was opened through `chrome-devtools-axi`. Every final `12-support` capture was viewed: normal top/bottom, removal failure, largest-text opening, each resource/title/contact/detail, outside-region guidance, shorter removal paragraph, retry and final Back to Today. The shorter paragraph and retry fit together, and the final action remains fully reachable. The two standard composer captures were compared with their references, with its largest-text opening and both enabled/disabled action captures also inspected. No new visual defect was found.

The full run includes 11 of 15 referenced screen states. Missing `04-today-first-day`, `07-about-someone`, `10-history` and `11-settings` belong to other assigned work; none is added or visually changed here. Support intentionally has no reference image and is reviewed against §11d. Existing Draw, Reveal and pick Reduce Motion captures remain present and passing.

## Author comparison and accepted differences

| Screen/state | Observation and disposition |
| --- | --- |
| Support, normal | No canvas reference. Dawn roles, page guide, title/body hierarchy, hairline-separated resource sections and one pinned primary action match §11d. The outside-region paragraph crosses the initial scroll boundary; the bottom capture shows it fully. Accepted as ordinary scrolling under §§4 and 11. |
| Support, removal failure | The short explanation and quiet retry appear after the resources; Back to Today uses the disabled role until removal succeeds, as §11d specifies. The question and cards are absent. No deviation found. |
| Support, largest text | Type grows and wraps naturally; content spans overlapping scroll captures. Contact digits remain complete, and retry and Back to Today are fully visible in their named captures. The action moves inline with the shared layout, as §§9 and 11d require. Cropped adjacent content at viewport edges is accepted because each target is separately captured fully visible. |
| Composer, both standard states | Native status area, larger back glyph, narrower/right-shifted selector and header/field spacing differ from the web references. Accepted unchanged foundation choices under §4's safe areas/real targets and §11a's composer layout; content order and complete labels remain. |
| Composer, type and grain | The title wraps after “ask”, glyph weights/leading differ, and native grain is denser. Accepted under §12's native text rendering allowance and §2's texture rule; bundled fonts pass their identity check. |
| Composer, preview and action | Suggestions sit closer to the pinned preview, dashed slots are darker/more widely spaced, the helper wraps differently, and the enabled arrow is heavier/more separated. The action sits slightly higher than the reference. Accepted unchanged §§5 and 11–11b components, side guides and footer clearance. |
| Composer, largest text | The selector stacks, text and actions wrap, preview sits above its helper, and actions move inline with surface-style corners. Accepted explicitly required §§11–11b adaptations. The enabled and disabled primary actions fit completely. |

These composer differences are the existing choices detailed in [Ask/composer verification](ask-composer-verification.md); this ticket changes submission routing, not composer styling.

## Independent comparison

Pending firstmate's required fresh-session review of the committed final evidence. Its verdict and each finding's disposition must be recorded before the first completion handoff and in the eventual pull request.

Real-device behaviour and manual VoiceOver reading order remain outside this simulator evidence.
