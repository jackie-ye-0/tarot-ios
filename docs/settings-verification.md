# Settings verification (#20)

Status: initial full harness check passed. The follow-up check on the stacked largest-text layout failed its new 44-point switch-target assertion (75/76). The native switch was only 28 points high despite its surrounding layout frame. A button hit area using the existing shared-control pattern now wraps the unchanged native artwork, with native Toggle accessibility representation. Focused and full verification of that correction, then independent design comparison, are pending.

## Behaviour and evidence

| Requirement | Evidence |
| --- | --- |
| Settings at the top right of Today | `testSettingsVisibilityPersistsWithoutChangingDailyCard`, plus the `04-today` reference capture |
| Hidden areas disappear from Today, Ask and composer | The same UI test hides Relationship and Social, checks the score/line and both selectors, relaunches and restores them |
| At least one area stays visible, with a reason | Parameterised engine test `lastAreaCannotBeHidden` tries each possible last area; UI test checks the disabled switch and explanatory hint |
| Hiding preserves the daily card, all scores and saved readings | `preferencesPreserveSnapshotsAndSurviveReopening` compares full daily and question snapshots through disk reopening; the UI test restores all scores and reopens the original Relationship reading |
| Relationship status can change or clear | `testSettingsStatusInformationAndLargestTextEvidence` exercises all four choices, clear and relaunch; store tests check persistence and the retained answered/skipped flag |
| About and Privacy | UI tests open both pages, run the strict accessibility audit and capture them at normal and largest text sizes |
| No birth-details or pronoun rows | UI assertions and the Settings source |
| Failed saves are recoverable | `testSettingsSaveFailureRetainsSettingAndCanRetry` and `failedSettingsSaveKeepsPreviousChoiceAndRetryWorks` prove the previous preference remains, and a repeated choice succeeds |

History (#19) is not in this branch's base. No store query is filtered by visibility, and hidden-area saved readings remain retrievable. When History lands, its existing all-area filters must remain independent of `session.visibleAreas`; its header can use `SettingsAction` to set `session.showsSettings`. This ticket does not create History.

## Design evidence

Touched screens: Today, Ask, composer, Settings, relationship-status editor, About these readings and Privacy. The existing standard and largest-text Today/Ask/composer tests remain in the full run. New captures use `11-settings` plus named variants for the three child pages, largest text, last-area hint and save error; hidden-area variants cover Today, Ask and composer. Draw, Reveal and the pick are unchanged; their existing Reduce Motion evidence remains in the full suite.

The settings child pages and last-area state have no reference. Their layout, wording, selection and error behaviour are specified in design manifest §11c. The design-role guard is unchanged. Existing bundled-font tests and strict, unfiltered all-category audits remain the verification mechanism.

Reference differences recorded during the first comparison:

- Settings omits Morning reminder because #21 explicitly owns its switch, and omits Export/Delete because #22 explicitly owns those actions. No inert controls are shown.
- Relationship status starts as “Not set” rather than the reference's example “In a relationship”. Status is optional and the test uses a fresh synthetic store.
- About and Privacy rows have chevrons because they navigate, following manifest §5.
- Native switches use the system's accessible semantics and the design system's ink tint.
- Today, Ask and composer retain previously documented content/artwork and unfinished-sibling differences in `today-verification.md`, `ask-verification.md` and `ask-composer-verification.md`. Settings adds the requested gear and intentional hidden-area states.

## Run and independent comparison

The full `./scripts/harness check` run `20261015T131900.614113Z-check-1625bdf2` passed with 76 tests, zero failures and zero skips, after all 34 command-contract tests and the unchanged design-role guard passed. Doctor passed in `20261015T131021.455040Z-doctor-92234b57`. Both used this checkout's dedicated iPhone simulator on iOS 26.5. The run exported `design-comparison.html`, reference copies and all new Settings captures. Exported-image inspection and firstmate's independent comparison are pending.

The first comparison opened the run's `design-comparison.html` with `chrome-devtools-axi` and inspected the exported Settings child pages, normal and largest-text Settings, Today, Ask and composer, plus hidden-area variants. The only new layout defect found was the largest-text Relationship switch label splitting inside the word. The corrected layout places each native switch below a full-width area label, and tests now operate all three switches at the largest text size. The new build requires a fresh full check and final screenshot inspection.

The failure in `20261015T174102.653786Z-check-9fb81632` was `testSettingsStatusInformationAndLargestTextEvidence`, at the Career switch (`visible-career`) after relaunching at the largest text size. The 44-point assertion remains unchanged; the test also taps near the top of the expanded hit area to prove it is interactive, not only a larger reported frame.
