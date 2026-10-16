# Settings verification (#20)

Status: implementation and author inspection complete; independent design comparison pending. The final full `./scripts/harness check`, `20261015T215219.051931Z-check-815ecaaf`, built clean commit `d7b4123963b6cca2278fd046165f863203035daa` and passed **76/76 iOS tests**, with zero failures, skips or expected failures, plus **34 command-contract tests** and the unchanged design-role guard. Later changes to this report do not alter the tested app, tests or manifest.

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

Pending firstmate's fresh-session image/manifest comparison. The final run's reference copies, screenshots, comparison page and manifest are copied into the task folder's `final-evidence/`, with a touched-state handoff. The independent verdict and each finding's disposition will be added here before the first completion handoff. No independent pass is claimed yet. Simulator evidence does not establish manual VoiceOver order or real-device behaviour.
