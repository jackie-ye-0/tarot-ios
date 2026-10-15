# Ask foundation (#13)

Scope: the first complete Today → Ask → composer → three-card pick → reading path. The independent comparison and its follow-up are complete. Historical verification below passed on `3dd2f82`; the recovery branch now includes the subsequently landed daily-flow and full-deck artwork work and requires a fresh full check. Native control flags remain unsuppressed. Every retained failed full check and failed diagnostic is disclosed below.

## Recovery after integration with main

The first no-mistakes run (`01M4W063NT766PH222SH9VNYTR`) rebased the change and applied the approved review fixes, then reached its 30-minute test-agent limit before pushing. Its focused test run reported two passing behavioural scenarios and two unclassified visual/audit failures while Xcode finalised the result bundle. That is a failed validation, not a passing check.

The preserved pipeline head `f3ec9ed3` was recovered onto `fm/tarot-13-ask-end-to-end-r2` and manually rebased onto `60569dd`. The original branch remains unchanged at `94fe646`. Integration retains all tests from both branches, one shared audit helper with every category and Dynamic Type last, the two established audit rules, the 78 card faces and both artwork proof screens. Ask's night outline is preserved alongside the new artwork.

Commit `95a0393` repairs two test-only integration defects: the synthetic 78-card fixture now supplies the required bundled question content, and the missing scroll helper intersects the real screen-content frame with the safe viewport, including keyboard, tabs and pinned-footer bounds. The prior pipeline test log identified both build defects. The first recovery check, `20261014T025617.305607Z-check-5d17e081` on clean `70aca0b`, passed 34 command tests and the design-role guard, but failed 9 of 47 iOS tests with zero skips or runtime warnings. Eight tests stopped when scrolling on Today: its standalone ScrollView had no `screen-content` identifier, unlike the shared layout used by Draw, Reveal and Ask. Retained failure hierarchies show the unlabelled ScrollView; the source and pre-failure log confirm the failing screen. Adding the same identifier changes no visible layout or accessibility labels.

The ninth failure was the inherited Today text-exposure test. It correctly recreated its original scrolled geometry, but the new tab bar covered the Relationship row: its paragraph frame ended at 799.7 points while the visible content ended at 738.7. The retained screenshot confirms the cover. The same exact Relationship labels and full-frame visibility are now checked at the already existing lower scroll stop, alongside Social; all original text assertions remain. No audit category or handler changed. These are integration defects, not a native-control contrast dismissal. A fresh check and capture inspection are pending; the historical results below do not establish a pass for the recovered revision.

The second recovery check, `20261014T031611.329661Z-check-e24fb5de` on clean `207268d`, passed **42/47 iOS tests**, with 34 command tests, the design guard, zero skips and zero runtime warnings. The missing identifier and Today exposure corrections passed, as did the Social flow and typed-question persistence. Five tests failed:

- Three largest-text paths exhausted ten half-viewport drags before reaching a distant Today target. The retained recordings show real progress through the longer Today content, ending before the Ask entry or card. The helper now uses up to 80% of the viewport per drag; the iteration bound and full-visibility assertions remain unchanged.
- The reading audit failed deferred coverage. Native callbacks placed Situation and heading labels above the viewport, while subsequent logged gestures continued upward. The helper now waits for the native scaling audit to finish restoring geometry and retains the native callback frame as a fallback when an off-screen query loses its frame. It still requires each deferred element to be audited fully visible; no coverage requirement or measurement condition is removed. Its content viewport now excludes a pinned footer, while an inline footer remains part of the scrollable content.
- The inherited card-size proof's direct combined audit flagged the plain static “120 points · Reversed” caption. Its app image and element crop were inspected; it was not a control finding. The proof now calls the existing shared seven-category helper, with Dynamic Type last and the same two audit rules, retaining a named `card-sizes--audit` capture. No control or mixed-content measurement override was added.

Both failed recovery bundles, logs, screenshots and audit records are preserved in task evidence. These repairs still require a fresh full check; no pass is claimed for them yet.

The third recovery check, `20261014T035945.282814Z-check-530bcb26` on clean `2a7ef67`, passed **44/47**: reading failed on ambiguous repeated “Upright” text, and two reopened-Reveal paths queried both the foreground and underlying `screen-content` nodes. Commit `40f51b0` selects the hittable scroller and gives each orientation label a stable position identifier, without changing its visible or VoiceOver text. Its full check, `20261014T045356.368361Z-check-e820508b`, again passed **44/47**. Standard reopened Reveal passed and the repeated orientation label was resolved; the remaining failures were initial daily-card selection, unresolved reading coverage for Situation and the Action heading, and largest-text reopened Reveal's computed disclaimer viewport. Both runs passed 34 command tests and the design guard, with zero skips, expected failures or runtime warnings.

Two temporary focused diagnostics then ran and were fully reverted. The first reproduced the reading coverage failure and logged all seven categories at twelve bounded stops. Only text clipping changed the fresh Situation query, repeatedly shifting its y-coordinate by 132 points. The offset probe returned a constant value even during deliberate scrolling, so it does not establish physical scroll movement versus stale geometry. The second diagnostic missed the initial card tap and never reached reading. Both failed; neither is counted as verification. Their logs, bundles, recordings and temporary patch remain in task evidence.

The next bounded test repair adopts the shared `tapWhenSettled` helper from ticket #8's `e024f7a`: one tap only after the target is hittable and unchanged across two reads, within five seconds. Audit ordering now puts **traits, text clipping, then Dynamic Type** last, following element detection, contrast, hit regions and sufficient description. Coverage and reading-scroll direction use query frames captured before the two resizing categories; the existing stable-frame wait remains before navigation. The modal viewport excludes underlying tabs when their controls are not hittable. The unique-match guard, native control/mixed-content failures, 4.5:1 plain-text requirement, complete-category audit and deferred-coverage requirement are unchanged; no retry bound or colour changed. One fresh full check is required for this revision.

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

The author compared the final captures with all ten applicable reference states. These differences are accepted for the reasons below, including the independent findings recorded later in this report. They are not exceptions to accessibility or action reachability. The original artwork, grain, daily wording and native rendering differences recorded in [foundation verification](foundation-verification.md) remain applicable to Draw, Reveal and the basic Today.

| Screen | Difference and reason |
| --- | --- |
| Draw and Reveal | Standard composition includes the landed ritual motion (#10) and full-deck artwork (#12), retaining their documented foundation texture and safe-area differences. At accessibility sizes the shared primary action uses the 22-point surface radius instead of a capsule, keeping multiline text away from the corners; actions remain inline and reachable. |
| Today | The landed full Today (#9) retains its scores, extras and area readings, with the Ask entry and two tabs added. Settings is #20 and the reminder is #21. |
| Today and Ask tabs | Two tabs rather than three, explicitly required by #13. History joins in #19. Icons use the platform symbols within the manifest's selected-pill and labelled-tab treatment. The selected pill uses ink fill and a surface-coloured icon after the native accessibility audit rejected the reference tint, including with an ink outline. The label remains ink on surface. |
| Ask | The context panel, recent reading and relationship-status prompt belong to #14. The named-person entry belongs to #18. The remaining content keeps the manifest's hierarchy and leaves open ground below the suggestions. Suggestions are actual questions, as required by #13 and the manifest, unlike the reference's topic phrases. |
| Composer, empty and filled | Character count/limit and the miniature empty-slot preview belong to #14. The explanatory three-card sentence remains above the primary action. The native keyboard Done key dismisses it; no accessory toolbar is added. The selector reserves a 44-point Back target, and the title wraps after “ask” rather than “to” at default size. Native font metrics, safe-area placement and the manifest’s section spacing are retained instead of forced line breaks or compressed type. |
| Three-card pick | The compact fan retains the established card-back drawing with narrower visual offsets and angles after review, while preserving five separate tap lanes. The progress label is centred on the screen independently of the 44-point Back control; the ritual disc is larger than the mock-up, using the foundation’s 1.345-width proportion in the shared screen ground and staying in place across both states. Shuffle, pulse and restoration of unfinished picks belong to #15. A quiet instruction replaces the absent shuffle action. Empty slots have an explicit night-ground fill so their gold numerals retain contrast over the disc. The cards show the injected starter draw, rather than the reference's sample spread. |
| Completed pick | The injected six-card starter readings now use the distinct faces supplied by #12 and original names in place of the reference examples. Filled cards use the required gold outline and say “Upright” as well as “Reversed”, adding a line to upright cards so orientation is always explicit. All 78 artwork identities from #12 remain available; the interpretation library remains six cards. |
| Reading | Original starter position meanings and the area lens replace the sample reading. Cards use the landed distinct faces and explicit Upright/Reversed labels described above. Area-coloured section headings use darker partners (5.7–5.9:1 on plain ground) after the native audit rejected the former near-threshold relationship colour over grain. The saved label says “Saved on this phone” until History exists (#19). Feedback and More belong to #16; Share belongs to #23. Done remains the only primary action and is pinned at standard size, following the manifest; it becomes inline at accessibility sizes. The small decorative area dot is omitted: the area is written in the saved label and repeated by the section-heading colour. |
| All touched screens | Native status bar and safe-area placement; bundled native font rendering and original deterministic grain can differ slightly from web/JPEG rendering. Larger text wraps and scrolls instead of being reduced to match the reference. |

The largest-text layout keeps three labelled area choices visible in a vertical segmented selector, moves the composer's Back control to its own row, stacks spread cards, and places the action after scroll content. Multiline controls use the surface radius to keep their text clear of the corners. These adaptations and states without reference images are described in `design.md` §11a.

## Keyboard editing and contrast verification

The toolbar warning was attributed with one bounded, two-variant UI test on 14 October 2026 (local date), under the shared simulator lock. The intended multiline field without its accessory toolbar and a bare single-line field both passed with zero runtime warnings in `.harness/ask-keyboard-no-toolbar.xcresult`. The original toolbar-containing composer emitted “Invalid frame dimension (negative or non-finite)” on focus. Removing the toolbar eliminated that warning in the next full run, but `onSubmit` did not dismiss the multiline field: the native Done key inserted a newline. The final editing rule intercepts that edit instead, while retaining the wrapping field.

A question is a single paragraph. A lone inserted Return preserves the question and clears focus. Pasted runs of line breaks collapse to one space with focus retained; ordinary text is unchanged. One pure function implements and unit-tests these rules. This foundation composer remains uncapped; #14 owns the character-limit/count UI. The UI tests require Done to hide the keyboard at standard and largest text sizes, keep the question unchanged, and allow reaching suggestions and submitting. No accessory toolbar or diagnostic input variant remains. The first measured-audit full run verified Done at both text sizes but its largest-text screenshot exposed question text behind the keyboard. Focusing now scrolls the field to the top; the keyboard test also requires its full frame above the keyboard before capturing it. That run also exposed an inline-footer shortcut in the new scrolling helper; only already-visible pinned actions can use that shortcut now.

Three bounded reading-only audit runs on the assigned simulator (`.harness/ask-reading-three-runs.xcresult`) each flagged `reading-situation`, `reading-action` and the off-screen `reading-outcome`. With failure continuation enabled, Action was also reported; earlier tests had stopped at the first flag. The kept Situation and Action images show fully visible text without an overlay. Their measured ratios were **9.061062:1** and **9.060674:1** respectively, identical in all three runs, exceeding the required 7:1 diagnosis gate. Outcome’s off-screen image contained the pinned footer instead, so it was not measured or treated as a visible-text pass.

The shared helper uses the [WCAG sRGB relative-luminance formula](https://www.w3.org/TR/WCAG22/#dfn-relative-luminance), estimates dominant background luminance, and selects the 1% luminance tail farthest from it for text. Synthetic near-10:1 pairs measured 9.894 in both directions; the near-3:1 pair measured 2.995 and remained below 4.5. These self-checks also run in the UI-test target. Alpha-dependent images cannot establish a background and are rejected.

Every audit category stays enabled. Fixtures use the existing Debug Reduce Motion switch and wait for real state/geometry conditions, with no fixed sleep. The Debug-only viewport value comes from the actual scroll layout after safe-area/pinned-action insets. A contrast issue can be dismissed only for plain static text without non-text descendants, fully inside that viewport and its own image measures at least 4.5:1, with identifier, label, image and ratio kept in evidence. No identifier allow-list is used. Off-screen contrast issues are deferred only if the same element is audited fully visible at another stop; unresolved deferrals fail the test. No other audit category is dismissed. The latest passing run’s per-element dispositions are listed below. The stricter current guard leaves native control failures unsuppressed; the earlier button failure and its bounded frequency check are retained under Validation limits.

## Latest complete verification evidence

`lockf /tmp/tarot-ios-harness.lock ./scripts/harness check --device B8FDA44A-52B0-45F2-9FFE-1E3381435CAC` passed on clean source/test commit `3dd2f826a3c000c26f4c346dad0c25d8bc0ce6ed` in `.harness/runs/20261014T005437.772748Z-check-0a007915/`. It ran **32 Python command tests, the design-role guard, and 26 iOS tests** (13 engine/font and 13 UI), with zero failures, skips, expected failures or runtime warnings. Toolchain: Xcode 27.0 (27A266a), iPhone 17e Tarot 1, iOS 26.5. This pass includes all independent-review corrections, the final composer helper alignment and the corrected reflection-caption stop. Later changes to this report do not change the tested app or tests.

`./scripts/harness evidence` was inspected and the generated comparison page opened with chrome-devtools-axi. All ten applicable reference pairs were visually compared, including the full-height references. All **76 exported images** were inspected: 68 full-screen captures and eight contrast crops. The ten main reference states are Draw empty/chosen, Reveal, Today, Ask, composer empty/filled, pick empty/complete and reading. Every touched screen has largest-text captures; Draw, Reveal and both pick states have Reduce Motion captures. Storage-open failure also has standard and largest-text evidence. Missing main references are Welcome, Today’s reminder state, About someone, History and Settings, all outside #13; strict all-screen coverage was not requested.

The author inspection verified the tabs/entry, all three area labels, complete suggested questions, empty/enabled composer actions, ordered labelled slots, positions/orientations, position passages, lens, reflection and Done. Largest-text captures overlap across long text, include each spread slot, and show reachable actions. Filled-composer top captures include Back, selector and title; separate stops cover the full guidance, field, all three suggestions, footer and keyboard states. Completed-pick top captures include Back, progress and the full question. The focused field is fully above the keyboard at both text sizes, with the action reachable after dismissal. The standard reading bottom now shows the whole reflection box, including “Something to sit with”, above the pinned footer. No content or primary action was unreachable across the inspected captures.

Final evidence is retained in the task folder at `final-evidence/ordered-audit-3dd2f82/`, including the manifest, references, comparison page, screenshots, result bundle/logs, exact audit records, author inspection, independent report, before/after counts and failed-run records. The original independent input remains unchanged: clean code/test commit `5494309`, run `20261013T180322.383990Z-check-492295a2`, 73 images (65 full-screen and eight crops). The earlier strict passing packet `post-review-49b2eb9/` is also retained as historical evidence, not relabelled as a pass for later changes.

### Measured contrast dismissals in the latest passing run

These are **all eight** contrast dismissals in `20261014T005437.772748Z-check-0a007915`. Each was contrast-only, plain static text without non-text descendants, fully inside the true viewport and measured from its own kept image. All other screens’ audits passed without a measured dismissal. All seven native categories ran once per stop, with Dynamic Type last. No control or composer-heading contrast flag appeared. Ratios below are rounded to six decimal places; kept attachments and `audit-records.json` contain full precision, frames, viewport, labels and luminances.

| Audit capture | Element identifier | Measured ratio |
| --- | --- | --- |
| `09-reading` | `reading-action` | 9.060674:1 |
| `09-reading` | `reading-situation` | 9.061062:1 |
| `09-reading--action` | `reading-action` | 9.060674:1 |
| `09-reading--action` | `reading-situation` | 9.061062:1 |
| `09-reading--bottom` | `reading-action` | 9.060761:1 |
| `09-reading--bottom` | `reading-lens` | 9.060963:1 |
| `09-reading--outcome` | `reading-action` | 9.062036:1 |
| `09-reading--outcome` | `reading-situation` | 9.061638:1 |

Outcome was deferred at the top and Action stops, then audited fully visible at the Outcome stop. The reflection was deferred at Outcome and audited fully visible at the bottom. Off-screen Situation text and the Action position heading at the bottom had already been audited fully visible. The final caption was visible and passed. No unresolved deferral remained, and no other audit category was dismissed. The synthetic near-3:1 control still failed the 4.5 floor in the measurement self-check.

## Independent comparison follow-up

The fresh-session reviewer opened all 65 full-screen images, eight contrast crops and ten matching references without app source, tests or author findings. The verdict was **“pass after the listed must-fix items”**. This was one independent round; the author then implemented the corrections below. No second independent verdict is claimed.

| Review IDs | Disposition |
| --- | --- |
| C4, CE4 | Shared dawn footer padding now uses the content’s 20-point guide. Final inspection found the composer helper’s intrinsic-width text still centred about six points inside that guide; its footer stack now uses leading alignment. The primary action already met the guide. All 16 final composer captures from `0a007915` were inspected, including empty/filled, standard/largest text, keyboard and keyboard-dismissed states. They confirm the helper/action guide and reachable actions after dismissal; the final full check passed. |
| R6 | Fixed through the same dawn-footer change. Done keeps standard-size pinning and largest-text inline placement. |
| S2 | Fixed in shared content alignment and footer spacing: short error copy aligns to the leading 20-point guide instead of centring its intrinsic width; retry shares that guide at both sizes. |
| CE3 | Added a true filled-composer navigation-top capture, guidance stop, separate field capture and complete-suggestions stop; retained footer/keyboard evidence. |
| PC5 | Completed-pick largest-text capture now returns to the navigation origin and explicitly checks Back, progress and question visibility, retaining each slot and footer. |
| CE2 | Added a clear 12-point strip above dawn footer contents so scrolled suggestions cannot touch the helper, including with the keyboard present. A suggestion can meet the scroll boundary while editing; it is fully visible in the suggestions and keyboard-dismissed captures, and the focused field and primary remain above the keyboard. |
| P1, PC3 | Progress centres across the full screen independently of the 44-point Back target, in both empty and completed picks. |
| P2 | Compact fan horizontal steps changed from 20% to 16% of available width, per-step angles from 8° to 6° and vertical steps from 18 to 12 points. Five independent tap lanes retain their width and height. |

All other reviewer findings were acceptable. Their screen-by-screen reasons are retained below, including the smaller native rendering differences:

- **D1–D5, DC1–DC4:** fixture weekday; deferred History/shuffle; foundation disc/fan/art geometry; selected card in front for clear selection; native type, texture and footer placement. These retain the approved #7 foundation and readable single-primary structure.
- **RV1–RV5:** deferred Share; small native card aspect/art/glow and text-metric differences; explicit rotated Reversed variant and changed keywords. The common card shape, wording roles, orientation and disclaimer remain present.
- **T1–T6:** fixture date; deferred Today extras/Settings/History; original reflective reading copy; “Ask the cards” wording; the required two labelled tabs and audited dark selected pill; thumbnail/native wrapping differences. The reference contains later-ticket content.
- **A1–A4:** #14 context/status/recent-reading and #18 named-person content deferred; suggestions changed to actual questions; two audited tabs; native selector/chip spacing and arrow weight. The approved hierarchy is preserved.
- **C1–C3, CE1, CE5:** #14 count/limit/mini-preview deferred; native Back and font wrapping; field and chip spacing; disabled/enabled labels; alternate typed keyboard question. Full content remains reachable without compressed type.
- **P3–P6, PC1–PC2, PC4, PC6:** 24-point night guide; opaque night slot fill; deferred #15 shuffle/pulse; stable foundation disc; injected six-card art/wording rather than reference examples; explicit Upright/Reversed captions; slightly larger filled cards and shifted vertical spacing; settled Reduce Motion states. The compact fan/progress corrections above supersede the older fan/alignment acceptance.
- **R1–R5, R7:** deferred Share/More/feedback; “Saved on this phone” pending History; omitted decorative area dot with area still named; original six-card position/lens/reflection text; explicit orientation and audited darker area headings; pinned/inline Done per manifest. The Action audit screenshot repeats the already-visible top passage; other captures cover the remainder.
- **S1, S3:** manifest-compliant error copy and retry; intentionally open middle at standard text and inline retry at largest text. S2's old inset difference is fixed.

The follow-up also limits measured contrast overrides to plain static text with no non-text descendants. Grouped/mixed elements retain native failures; no 7:1 branch exists in the test helper, whose only acceptance floor is 4.5:1.

### Draw test synchronisation follow-up

Two post-review full checks each passed 25/26 iOS tests. The first missed the first daily-card tap; the unchanged five-position test then passed in a focused run. The second passed that test but missed the tap following the Draw accessibility audit. Recorded frames show the audit temporarily enlarging text and restoring normal geometry near that interaction. This supports a settling issue after the native audit, but does not establish the cause of the earlier launch-time miss.

Commit `b0d0d40` uses the existing unchanged-frame predicate immediately before those Draw interactions. There is still one tap, with no fixed delay or retry. Both affected tests passed in two focused iterations (four successful executions), with no skips or runtime warnings. App layout and content were unchanged by this test-only follow-up. The final full-run outcome is recorded separately.

## Validation limits: intermittent native control-contrast flag

The full locked check on code/test commit `b0d0d40`, `.harness/runs/20261013T194910.479224Z-check-c4718bc9/`, passed 32 command tests, the design-role guard and **25/26 iOS tests**, with no skips or runtime warnings. The sole failure was the filled composer's native contrast audit on the `suggestion-0` Button (“Where is this going?”). That run remains failed and its screenshots, logs and result bundle are retained. The static-text-only guard did not suppress it.

The failed native element crop's text/background measurement was **11.369905:1**, diagnostic only. A control image does not qualify for the static-text override, and that measurement does not establish the border's contrast. No control exception, colour change or chip-style change was introduced.

A bounded diagnostic then ran only the standard filled-composer audit five consecutive times with the app and audit policy unchanged. **All five passed: 0/5 reported the `suggestion-0` flag, and no other element identifier was flagged in any iteration.** There were no runtime warnings. Temporary logging recorded every native callback and failure continuation would have retained failures while collecting all flags. The temporary fixture was removed byte-for-byte before the full check; no permanent retry loop was added. The five-execution raw log, result bundle, per-iteration captures and result inventory are preserved. This demonstrates an intermittent native flag, not a reason to dismiss future control failures.

A later fresh-launch-only filled-composer test failed on its first execution (1/1): the native audit flagged the static heading “Or start from one of these”, then failed the `suggestion-0` Button. The remaining nine authorised executions were not started, and the test-only restructure was reverted completely. The retained isolated observations are now 1/6 executions with flags, alongside 4/9 full-flow filled-composer audits with flags: evidence, not proof of a cause or reliable rates. Earlier Ask/empty-composer audits in the same session are not required for the failure. The failed execution and tested source remain in task evidence; native control flags remain unsuppressed.

The earlier full strict check on `49b2eb9` passed **26/26**, including the composer control audit and both daily Draw tests. All native controls and mixed/grouped elements retain native failures. Only ten measured plain-static-text findings were dismissed in that historical pass; their exact records remain in its evidence packet. The earlier failed runs remain part of the validation record rather than being replaced by the later pass.

### Reflection-caption audit coverage follow-up

Run `20261013T213027.896263Z-check-760c90c0` on clean `3eb99a7` passed 32 command tests, the design guard and 25/26 iOS tests, with no skips or runtime warnings. Standard empty/filled and largest filled composer footer images confirm the leading-alignment correction. The sole failure was an unresolved deferred contrast issue on the reading's “Something to sit with” caption. Its recorded frame was `(40, 772.0667, 121, 17)` outside viewport `(0, 47, 390, 658)`. The bottom screenshot shows the question but clips the caption below the pinned footer: the test had scrolled only to `reflection-question`.

The final reading audit stop now scrolls to the caption and explicitly requires the question to remain visible above the footer. It waits for both texts to settle before the audit. App layout, wording and audit policy are unchanged. This targets the coverage gap without suppressing any additional issue. The next two full runs stopped at the composer audit before reaching the corrected reading stop. The final ordered-audit run `0a007915` subsequently reached it, passed and captured the whole reflection box. The failed run and exact audit records are preserved. Xcode took roughly ten minutes after the test suite ended to finalise its result bundle; it was left running and completed without intervention.

### Repeated native control failures and stop bound

Two subsequent full locked checks used unchanged clean commit `2c7ab55ed0e186d3f4b250a67ab8106eb2d9c5f1`:

| Run | Result | Sole failure |
| --- | --- | --- |
| `20261013T221357.163338Z-check-73ca2848` | 32 command tests and design guard passed; 25/26 iOS tests; no skips or recorded runtime warnings | Filled-composer `suggestion-0` Button, “Where is this going?”, native `Contrast failed` |
| `20261013T224836.297676Z-check-e4b78f9d` | 32 command tests and design guard passed; 25/26 iOS tests; no skips or recorded runtime warnings | The same native `suggestion-0` Button contrast failure |

Their app and element screenshots were inspected and both result bundles, logs and exported images preserved. Both current button crops measure **11.369905:1 for text/background**, diagnostic only, identical to the original failed crop. This does not establish border contrast or qualify a control for the static-text override. The earlier focused result remains **0/5 flags**, with no other identifiers flagged; the later full-run recurrences are recorded alongside it. No colour, chip style, native-control exception, audit-category change or permanent retry loop was added.

Each failed filled-composer audit also attached a crop of the plain static text “Or start from one of these” before reaching the button failure. Its final audit JSON attachment was not exported after the test stopped; the raw log and crop are preserved, and no missing record or ratio is invented. Neither run reached the corrected reading-caption audit stop. The largest-text path and keyboard tests passed independently.

All 16 composer captures from `e4b78f9d` were inspected. They confirm the final C4/CE4 leading alignment across empty/filled, standard/largest-text, keyboard and keyboard-dismissed states, with full guidance/suggestions covered by overlapping stops. This visual verification does not turn the failed native control audit into a pass. No inspection of all 65 images from this failed run is claimed.

At that stage, three consecutive full checks had failed for contrast-related reasons: unresolved off-screen caption coverage (`760c90c0`), then the native button twice (`73ca2848`, `e4b78f9d`). Further reruns stopped at the instructed bound, and Inbox 012 imposed a simulator hold. Later Firstmate instructions released the bounded diagnostic and full checks described next. No failed run was changed into a pass.

## Audit-ordering follow-up

After the simulator release, one final combined-call check on clean `f40cb0c`, `20261014T004324.397812Z-check-c22e5033`, failed 25/26 with the same heading callback followed by native `suggestion-0` control contrast. It had zero skips and runtime warnings. Its kept composer image and native control crop were inspected; the run remains failed.

The only subsequent test change takes the per-category ordering supplied from the Today work: `elementDetection`, `contrast`, `hitRegion`, `sufficientElementDescription`, `textClipped`, `trait`, then `dynamicType`. Each category runs once per existing stop. The handler is byte-for-byte unchanged, as are the two agreed rules: measured fully visible plain static text at 4.5:1, and off-screen deferrals resolved only by a fully visible audit. No app code, colour, chip style, audit stop, retry, continuation or control exception changed.

The first check with this ordering passed 26/26, with **0/1 runs reporting a control or composer-heading contrast flag**. It stopped the authorised maximum-three sequence at its first complete pass. In the ten preceding retained full-flow runs from `13b64511` through `c22e5033`, **5/10 reported both heading and control flags** at the filled-composer stop. Separately, the fresh-launch diagnostics recorded **1/6 isolated executions with flags**. These small, differing samples are evidence, not proof of the Dynamic Type hypothesis or reliable failure rates. The historical `13b64511` pass measured/dismissed control findings under the old broader handler; that treatment has been removed and is not counted as a strict native control pass.

| Full-flow run | Audit ordering | Filled-composer control flag | Filled-composer heading flag |
| --- | --- | --- | --- |
| `20261013T172811.274577Z-check-13b64511` | combined | Yes | Yes |
| `20261013T180322.383990Z-check-492295a2` | combined | No | No |
| `20261013T190550.159708Z-check-65ee2119` | combined | No | No |
| `20261013T191941.856030Z-check-0b7fc21f` | combined | No | No |
| `20261013T194910.479224Z-check-c4718bc9` | combined | Yes | Yes |
| `20261013T201947.958208Z-check-f9595a6b` | combined | No | No |
| `20261013T213027.896263Z-check-760c90c0` | combined | No | No |
| `20261013T221357.163338Z-check-73ca2848` | combined | Yes | Yes |
| `20261013T224836.297676Z-check-e4b78f9d` | combined | Yes | Yes |
| `20261014T004324.397812Z-check-c22e5033` | combined | Yes | Yes |
| `20261014T005437.772748Z-check-0a007915` | per-category, Dynamic Type last | No | No |

The ordering prevents the Dynamic Type category from running before contrast in the same stop. Whether that was the cause of every earlier native misfire remains unproven. Future control findings still fail the test; a later pass does not erase the failed checks.

## Complete retained failure history

All 14 failed full checks retained for this task are listed below. None is reclassified as passing. Every one ran with zero skipped and expected-failure tests; dirty development snapshots are identified. The result bundles remain under `.harness/runs/`, with summaries, logs and command metadata copied into the final evidence’s `failed-run-records/`.

| Run | Revision | iOS passed/total | Recorded failure |
| --- | --- | --- | --- |
| `20261013T132503.563953Z-check-0e831628` | `f6ef8e7` + development changes | 16/23 | Seven UI failures across Ask navigation, first Draw selection, large-text action visibility and relaunch paths. |
| `20261013T134244.816046Z-check-022432f9` | `f6ef8e7` + development changes | 20/23 | Large-text question-field visibility; native contrast on the Ask and Today tab labels. |
| `20261013T135345.588164Z-check-8fa04ce2` | `f6ef8e7` + development changes | 21/23 | Native contrast on the Ask and Today tab labels. |
| `20261013T142631.456392Z-check-1ae3a641` | `f6ef8e7` + development changes | 22/23 | Native contrast on the empty pick’s first slot numeral. |
| `20261013T151130.778351Z-check-620dda71` | `159e114` | 22/23 | Native contrast on the filled-composer suggestion heading. |
| `20261013T154558.495948Z-check-2f0876f7` | `6a2435e` | 21/24 | Native reading Situation contrast and two keyboard/typed-question assertions. |
| `20261013T170154.880762Z-check-ecd94ef2` | `f3d895e` | 23/26 | Large-text Ask, Draw and storage-retry actions not reached by the scroll helper. |
| `20261013T190550.159708Z-check-65ee2119` | `2977339` | 25/26 | First daily-card tap did not reach Reveal in the five-position regression. |
| `20261013T191941.856030Z-check-0b7fc21f` | `2977339` | 25/26 | Post-audit Draw interaction did not reach the expected settled elements. |
| `20261013T194910.479224Z-check-c4718bc9` | `b0d0d40` | 25/26 | Native filled-composer suggestion-0 control contrast. |
| `20261013T213027.896263Z-check-760c90c0` | `3eb99a7` | 25/26 | Unresolved deferred reflection-caption audit: caption was outside the scroll viewport. |
| `20261013T221357.163338Z-check-73ca2848` | `2c7ab55` | 25/26 | Native filled-composer suggestion-0 control contrast. |
| `20261013T224836.297676Z-check-e4b78f9d` | `2c7ab55` | 25/26 | Native filled-composer suggestion-0 control contrast. |
| `20261014T004324.397812Z-check-c22e5033` | `f40cb0c` | 25/26 | Native filled-composer suggestion-0 control contrast; final combined-call run before the ordering change. |

Failed focused diagnostics are also retained: `reveal-regression-red.xcresult` (0/1, large-text Reveal keywords outside the visible window); `ask-slot-background.xcresult` (0/1, reading Situation heading “Contrast nearly passed”); `ask-reading-three-runs.xcresult` (all three diagnostic executions failed, reporting Situation, Action and off-screen Outcome contrast; the summary aggregates the repeated test as one failed test); and `isolated-filled-composer/iteration-01.xcresult` (0/1, heading flag followed by the native suggestion-button failure). The isolated experiment stopped after the first failure and its test restructure was completely reverted. The measured build-only result ran zero tests and is not used as test verification.

The failed-run counts are a disclosure of development and validation history, not a claim that unrelated failures share one cause. Earlier broad measurement handling is historical: the final helper only permits measured plain static text and never dismisses native control flags.

## Remaining release limits

Content remains original draft writing requiring editorial review. This #13 slice deferred unfinished question/pick persistence to #14/#15; crisis handling is #17, while History, export and deletion retain their own tickets. No account, network, AI service or dependency was introduced. Manual VoiceOver reading order and real-device behaviour are not established by simulator screenshots or XCTest audits.
