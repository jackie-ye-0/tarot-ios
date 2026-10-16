# Settings verification (#20)

Status: both independent-review capture corrections passed their assertions and were visually inspected. The delivery full check `20261016T063832.756516Z-check-77dbacdc` on clean commit `e755389e2e91ea20d827f8dba0a7eea54f067b28` passed **76/76 iOS tests**, with zero failures, skips or expected failures. All **34 command-contract tests** and the design-role guard passed. The earlier 75/76 post-review run and its passing 1/1 focused rerun remain recorded below as evidence of the known intermittent composer Done interaction.

The previous full check, `20261015T215219.051931Z-check-815ecaaf`, built clean commit `d7b4123963b6cca2278fd046165f863203035daa` and passed **76/76 iOS tests** with zero failures, skips or expected failures. App code and the manifest are unchanged since that pass. The new capture assertions are covered by the post-review run described below.

The run used Xcode 27.0 (27A266a), iOS 26.5 and this checkout's dedicated iPhone 17e simulator. Doctor passed in `20261015T131021.455040Z-doctor-92234b57`. `./scripts/harness evidence --run .harness/runs/20261015T215219.051931Z-check-815ecaaf` was read, the final `design-comparison.html` was opened with `chrome-devtools-axi`, and the exported images described below were inspected.

## Behaviour and evidence

| Requirement | Evidence |
| --- | --- |
| Settings at the top right of Today | `testSettingsVisibilityPersistsWithoutChangingDailyCard`, plus the `04-today` reference capture |
| Hidden areas disappear from Today, Ask and composer | The same UI test hides Relationship and Social, checks the score/line and both selectors, relaunches and restores them |
| At least one area stays visible, with a reason | Parameterised engine test `lastAreaCannotBeHidden` tries each possible last area; UI test checks the disabled switch and explanatory hint |
| Hiding preserves the daily card, all scores and saved readings | `preferencesPreserveSnapshotsAndSurviveReopening` compares full daily and question snapshots through disk reopening; the UI test restores all scores and reopens the original Relationship reading |
| Relationship status can change or clear | `testSettingsStatusInformationAndLargestTextEvidence` exercises all four choices, clear and relaunch; store tests check persistence and the retained answered/skipped flag |
| About and Privacy | UI tests open both pages, check the disclaimer and phone-only copy, run the existing all-category accessibility audit and capture normal and largest text sizes |
| No birth-details or pronoun rows | UI assertions and the Settings source |
| Failed saves are recoverable | `testSettingsSaveFailureRetainsSettingAndCanRetry` and `failedSettingsSaveKeepsPreviousChoiceAndRetryWorks` prove the previous preference remains, and a repeated choice succeeds |

History (#19) is not in this branch's base, so its conditional Settings entry and filter UI cannot be exercised here. No store query is filtered by visibility, and hidden-area saved readings remain retrievable, as the snapshot/reopening tests prove. History's all-area filters must remain independent of `session.visibleAreas`; its header can use `SettingsAction` to set `session.showsSettings`. This ticket does not create History.

## Design evidence

Touched screens: Today, Ask, composer, Settings, relationship-status editor, About these readings and Privacy. The existing standard and largest-text Today/Ask/composer tests remain in the full run. New captures use `11-settings` plus named variants for the three child pages, largest text, last-area hint and save error; hidden-area variants cover Today, Ask and composer. Draw, Reveal and the pick are unchanged; their existing Reduce Motion evidence remains in the full suite.

The Settings child pages, hidden-area variants, last-area hint and save alert have no separate reference. Their layout, wording, selection and error behaviour are specified in design manifest §11c in the same change. The design-role guard is unchanged, and the existing bundled-font test passed for both fonts. All native accessibility audit categories remain enabled in the existing settled-screen helper; this ticket changes neither that helper nor its contrast measurement rules.

The final run's Settings overview/bottom and About audits reported no issues. Three new-screen plain-static-text contrast flags were resolved by the existing measured-image rule, with their element crops, frames, viewport and luminance values retained in the run's audit attachments:

| Capture | Element | Measured contrast |
| --- | --- | --- |
| `11-settings--last-area` | Explanation that one area must remain on | 5.242208:1 |
| `11-settings--relationship` | Optional-status helper | 5.240743:1 |
| `11-settings--privacy` | First phone-only paragraph | 9.061659:1 |

These elements were fully inside the viewport and exceeded the existing 4.5:1 floor. No control or other audit category was dismissed. The full run also passes the inherited Today, Ask and composer audits. Largest-text tests operate all three area switches, assert their labels and minimum 44-point targets, and tap near each target's top edge to prove that the expanded region responds. They retain the child-page bottom captures, relationship choices and clear action, and the existing reachable composer-action checks.

### Author image inspection and accepted differences

The final Settings reference pair, status editor, About, Privacy, last-area hint and save-error images were inspected, together with their largest-text top/bottom variants. The corrected area labels remain whole, switches sit below them without overlap, relationship choices and Clear are reachable, and the complete informational copy is available across the scrolling captures. Text crossing a viewport edge is normal scrolling, with the remainder shown in the bottom captures; no internal truncation was found.

The final Today, Ask and empty/filled composer reference pairs and hidden-area images were also inspected. The largest-text Today header retains the Settings target; Ask status actions and the composer's inline primary action remain reachable. Hidden-area variants show one full-width Career score/line or selector, with the remaining content retaining its existing hierarchy.

These visible differences are accepted by the author and must be included with the independent findings in the pull request:

| Difference | Reason |
| --- | --- |
| Settings omits Morning reminder and Export/Delete | #21 explicitly owns the reminder switch; #22 explicitly owns export/deletion. Manifest §11c omits their rows until functional. |
| Relationship status initially says “Not set” instead of the reference's “In a relationship” | Status is optional, and the capture uses a fresh synthetic store. |
| About and Privacy have chevrons | They open child pages, following the navigable-row rule in manifest §5. |
| Native switches have a wider track and white pill-shaped thumb rather than the reference's round cream thumb; off and disabled states use native rendering | Manifest §11c requires the native switch's semantics with the ink tint. At largest text, the switch moves below its label, inside a full-width 44-point hit area, preserving whole words and a usable target. |
| Settings has real system indicators, a heavier back symbol, slightly taller rows and different title/group spacing, text metrics and grain | Native safe areas and shared 44-point navigation are required by §4. The existing type/spacing/surface roles and side guides remain consistent; §12 permits small native-rendering differences. The reference is a long artboard, whereas captures show a real scrolling viewport. |
| Today uses a gear instead of the reference's sliders-style settings glyph | A familiar SF Symbol supplies the requested Settings action, with the explicit label and 44-point target specified in §11c. |
| Today retains the correct Sunday date for 11 October 2026, original card art/reading copy, literal “Sage”, darker area text and native spacing; area rows have no chevrons | The retained differences follow the snapshot content, contrast roles and non-navigable area rows documented in [Today verification](today-verification.md). The Ask entry uses the already accepted “Ask the cards” wording. |
| Ask uses the saved card name/line, question-form suggestions and stacked status choices; no-history states have no recent-reading row | Manifest §11b requires actual saved context, optional status and these conditional states. The native selected tab uses an ink pill for contrast. |
| Ask and Today have two tabs, and Ask has no named-person entry | History and named-person entry remain the separate #19 and #18 tickets, as specified in §11a. |
| Composer has native header/field spacing and text wrapping, darker dashed preview slots, and a pinned standard-size or inline largest-text action | These retained differences follow safe areas, contrast roles and the explicit large-text layout. Detailed reasons for the unchanged empty/filled, keyboard and limit variants remain in [Ask/composer verification](ask-composer-verification.md). |
| Hidden areas leave wider remaining scores/segments; largest text stacks the settings labels/value and selectors | These are the explicit visibility and accessibility behaviours in §§11–11c. The tests establish that card and scores are unchanged. |

The comparison page matches all in-scope main references. Its missing `04-today-first-day`, `07-about-someone` and `10-history` main captures belong to #21, #18 and #19, outside this ticket.

## Corrections during validation

The initial check, `20261015T131900.614113Z-check-1625bdf2`, passed 76/76. Image inspection then found the largest-text Relationship label splitting inside the word. The corrected layout gave the label the full row width and placed the switch below it.

The follow-up check, `20261015T174102.653786Z-check-9fb81632`, passed 75/76. Its sole failure was the new largest-text Career switch target assertion: the native switch exposed 28 points despite its surrounding frame. The correction surrounds the unchanged native artwork with the shared button hit-area pattern and keeps native Toggle accessibility representation. The 44-point assertion remains, and the test also taps near the top of the expanded target. The final full check recorded above passes both the geometry and interaction assertions; its images show the whole labels and unchanged switch artwork.

## Independent comparison

A fresh agent completed the image-only comparison on 16 October 2026 using the manifest, five relevant references and all 270 exported images, without app source, tests or author conclusions. Its verdict was **“pass after the two must-fix evidence items, C5 and R2”**. Firstmate instructed one independent round, the two capture additions below, and recording C2 without changing the existing composer layout. The original report is retained in the task material as `independent-review.md`. The original review packet is preserved in `independent-review-input/`; refreshed `final-evidence/` contains the post-review full run and a separate `focused-keyboard/` packet, each with its own actual result.

| Finding | Disposition |
| --- | --- |
| C5: hidden-area composer's final chip not fully captured | Added `06-composer--hidden-areas-bottom` after scrolling to the last suggestion. The whole-frame and minimum 8-point-gap assertions passed in `3c1519bc`. Author inspection confirms the complete final Career chip, a clear gap, preview and disabled action are visible. |
| R2: largest-text relationship editor's current value not fully captured | Added `11-settings--relationship-largest-text-current-status` between the top and bottom captures. The complete-label and first-choice visibility assertions passed in `3c1519bc`. Author inspection confirms the complete “Current status: Not set” line above the whole Single row and start of the choices. |
| C2, also noted in E1: composer spacing | Retained unchanged per firstmate: the layout belongs to the already-merged Ask ticket and is a follow-up, not a Settings change. The reviewer calls this non-blocking and does not identify inaccessible content. The exact finding and recommendation are retained below for the pull request. |

> The native upper stack is more spread out. At normalised 390-point width the field begins about 27 points lower than the reference; the last suggestion ends about 38 points lower, while the pinned footer starts higher. The breathing space between the last chip and the preview is therefore much tighter, roughly 20–25 points instead of roughly 75.
>
> **Should fix, non-blocking.** Tighten the ordinary-size gaps above the field/suggestions towards the reference so the chip stack has more breathing room above the fixed footer. Preserve the 56-point primary action and safe-area clearance; do not shrink text or the field to force a fit. This is a visible spacing mismatch, not evidence of inaccessible content.

The reviewer accepted every remaining finding for these manifest-based reasons:

| Findings | Accepted difference and reason |
| --- | --- |
| T1–T2 | Gear is explicitly required by §11c; the correct weekday is fixture content. |
| T3–T5 | Native card/details positioning and art retain the 5:8 Star grammar; reflective copy, literal colour name and wrapping area lines preserve the content roles. Darker area text and omitted non-functional chevrons follow the manifest. |
| T6–T7 | Two tabs, placeholder icons and the selected ink pill follow the existing navigation rules; History is #19. The shorter “Ask the cards” entry is specified in §11a, the omitted introductory heading is redundant and the composer explains the three-card step. Midnight copy remains. |
| T8–T9 | Hidden areas leave a full-width remaining score/line; largest text stacks content and preserves the gear artwork size, as required. |
| A1–A3 | Actual saved card/line replaces sample context; darker labels, modest native selector/arrow differences and question-form suggestions follow the roles and wording rules. |
| A4–A7 | Named-person entry is #18; full-width status choices and Skip, conditional saved-reading section with actual card faces/question/date, and the two-tab treatment follow §§11a–11b. |
| A8 | Filtering and large-text reflow keep the remaining area and complete entry/recent-reading content together. |
| C1, C3–C4 | Native header/text wrapping, preview dashes/helper wrapping and safe-area footer placement retain hierarchy and wording; filtering and largest-text inline action follow the manifest. C2 separately records the spacing concern. |
| E1–E4 | Shared native rendering differences follow C1/C3, with C2 retained; the enabled action wraps at largest text, keyboard states use the specified focus/Done flow and the limit state shows textual error feedback. |
| S1–S3 | Native spacing/alignment and row heights preserve the three-group hierarchy; native thumb/off/disabled appearances are specified. Unset status and its large-text stacked value are valid. |
| S4–S5 | Reminder/export/delete remain #21/#22; About and Privacy chevrons identify navigation and Settings has no tab bar. |
| S6–S8 | Exact last-area explanation, native recoverable-save alert, whole largest-text area words and normal-size switch artwork follow §11c. |
| R1, R3 | The explicit current-value line reinforces the saved choice; multiline options and Clear retain the selected checkmark and readable layout. R2 separately adds the missing value evidence. |
| B1–B2, P1–P2 | Quiet scrolling pages contain the required full disclaimer and phone-only paragraphs; their paired largest-text captures cover the complete copy. |

The review does not certify the combined hidden-area/largest-text state or largest-text last-area/save-error variants; those combinations were not captured. It found no other obvious broken settled layout in the retained regression images. Still screenshots cannot establish behaviour, persistence, native semantics, exact fonts, measured contrast or motion timing. The test evidence supplies applicable runtime checks; manual VoiceOver order and real-device behaviour remain unverified.

## Post-review checks and focused rerun

The delivery `./scripts/harness check`, `20261016T063832.756516Z-check-77dbacdc`, ran on clean `e755389` and passed **76/76 iOS tests**, with zero failures, skips or expected failures, plus all **34 command-contract tests** and the design-role guard. This passing full run is the delivery result for the final source and test set.

The earlier failed full run and focused rerun remain recorded separately below; the focused result is not used to relabel that failed full run.

`./scripts/harness check` ran once as authorised on clean `4a8dca7`. Its own completed `summary.json` reports exit 65, 75 passed, one failed and zero skipped tests. The sole failure is `testComposerKeyboardLayoutEvidence` at `HarnessShellUITests.swift:1804`: after tapping the native Done key at largest text, the keyboard still existed throughout the five-second disappearance wait. The standard-size pass through that test completed. The keyboard test and composer implementation are unchanged by the review correction; no cause or permanent product defect is inferred from this single failure.

Both corrected Settings tests passed: `testSettingsStatusInformationAndLargestTextEvidence` in 157.095 seconds and `testSettingsVisibilityPersistsWithoutChangingDailyCard` in 145.644 seconds. Their two new kept captures were opened and inspected, as was the largest-text keyboard capture immediately before the failed Done interaction. The latter shows the complete question and native keyboard/key; it does not establish what happened after the tap. `./scripts/harness evidence --run .harness/runs/20261016T022341.962700Z-check-3c1519bc` was read.

The failed run's summary, logs, screenshots, manifest/reference copies and keyboard attachments remain in the task folder's `post-review-check-3c1519bc/`. Firstmate then directed treating this as a known intermittent pre-existing test interaction: the same test passed on `d7b4123`, and the diff from that passing revision to `4a8dca7` changes neither app code nor `testComposerKeyboardLayoutEvidence`. No composer or keyboard-test change was made.

Exactly one focused rerun was performed as authorised. The repository CLI has no test selector, so a task-local Python runner used the existing harness queue, dedicated-device selection, Xcode command builder and evidence-export helpers, adding only `-only-testing:HarnessShellUITests/HarnessShellUITests/testComposerKeyboardLayoutEvidence`. It required exactly one passing test, no skips and both dismissed-keyboard captures. No repository harness code or its four-test minimum for ordinary checks changed.

Run `20261016T043417.343365Z-focused-keyboard-a7519fc5` passed on clean `4b917e8`: **1/1 test**, zero failures, skips or expected failures, exit 0. The test passed in 96.592 seconds, including the unchanged five-second keyboard-disappearance assertion at both text sizes, retained text, primary-action reachability and transition to the spread. Its four exported keyboard/keyboard-dismissed images were opened and inspected. Standard text retains the full action above the keyboard; after dismissal the largest-text capture shows the complete preview and inline primary action with the keyboard absent. The prior failed run remains recorded as failed, and the intermittent interaction remains a known limitation to include in the eventual PR description.
