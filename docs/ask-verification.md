# Ask foundation (#13)

Scope: the first complete Today → Ask → composer → three-card pick → reading path. The independent image comparison is complete. The latest full check on 14 October 2026 passed all 26 iOS tests on `49b2eb9`, with native control audits unsuppressed. Inspection of its 78 images found one remaining composer helper alignment detail; the one-line correction is implemented but awaits a fresh check and captures after the shared-simulator scheduling hold clears. This report does not claim that the earlier pass validates that final correction.

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
| Draw and Reveal | Standard composition retains the #7 foundation and its documented artwork, fan, texture and safe-area differences. At accessibility sizes the shared primary action uses the 22-point surface radius instead of a capsule, keeping multiline text away from the corners; actions remain inline and reachable. |
| Today | The existing basic card/interpretation gains the Ask entry and two tabs. Scores, extras, area readings and other fuller Today content belong to #9; Settings is #20 and the reminder is #21. |
| Today and Ask tabs | Two tabs rather than three, explicitly required by #13. History joins in #19. Icons use the platform symbols within the manifest's selected-pill and labelled-tab treatment. The selected pill uses ink fill and a surface-coloured icon after the native accessibility audit rejected the reference tint, including with an ink outline. The label remains ink on surface. |
| Ask | The context panel, recent reading and relationship-status prompt belong to #14. The named-person entry belongs to #18. The remaining content keeps the manifest's hierarchy and leaves open ground below the suggestions. Suggestions are actual questions, as required by #13 and the manifest, unlike the reference's topic phrases. |
| Composer, empty and filled | Character count/limit and the miniature empty-slot preview belong to #14. The explanatory three-card sentence remains above the primary action. The native keyboard Done key dismisses it; no accessory toolbar is added. The selector reserves a 44-point Back target, and the title wraps after “ask” rather than “to” at default size. Native font metrics, safe-area placement and the manifest’s section spacing are retained instead of forced line breaks or compressed type. |
| Three-card pick | The compact fan retains the established card-back drawing with narrower visual offsets and angles after review, while preserving five separate tap lanes. The progress label is centred on the screen independently of the 44-point Back control; the ritual disc is larger than the mock-up, using the foundation’s 1.345-width proportion in the shared screen ground and staying in place across both states. Shuffle, pulse and restoration of unfinished picks belong to #15. A quiet instruction replaces the absent shuffle action. Empty slots have an explicit night-ground fill so their gold numerals retain contrast over the disc. The cards show the injected starter draw, rather than the reference's sample spread. |
| Completed pick | The same six-card starter art and original names replace the reference examples. Filled cards use the required gold outline and say “Upright” as well as “Reversed”, adding a line to upright cards so orientation is always explicit. Distinct full-library faces are #12. |
| Reading | Original starter position meanings and the area lens replace the sample reading. Cards retain the starter faces and explicit Upright/Reversed labels described above. Area-coloured section headings use darker partners (5.7–5.9:1 on plain ground) after the native audit rejected the former near-threshold relationship colour over grain. The saved label says “Saved on this phone” until History exists (#19). Feedback and More belong to #16; Share belongs to #23. Done remains the only primary action and is pinned at standard size, following the manifest; it becomes inline at accessibility sizes. The small decorative area dot is omitted: the area is written in the saved label and repeated by the section-heading colour. |
| All touched screens | Native status bar and safe-area placement; bundled native font rendering and original deterministic grain can differ slightly from web/JPEG rendering. Larger text wraps and scrolls instead of being reduced to match the reference. |

The largest-text layout keeps three labelled area choices visible in a vertical segmented selector, moves the composer's Back control to its own row, stacks spread cards, and places the action after scroll content. Multiline controls use the surface radius to keep their text clear of the corners. These adaptations and states without reference images are described in `design.md` §11a.

## Keyboard editing and contrast verification

The toolbar warning was attributed with one bounded, two-variant UI test on 14 October 2026 (local date), under the shared simulator lock. The intended multiline field without its accessory toolbar and a bare single-line field both passed with zero runtime warnings in `.harness/ask-keyboard-no-toolbar.xcresult`. The original toolbar-containing composer emitted “Invalid frame dimension (negative or non-finite)” on focus. Removing the toolbar eliminated that warning in the next full run, but `onSubmit` did not dismiss the multiline field: the native Done key inserted a newline. The final editing rule intercepts that edit instead, while retaining the wrapping field.

A question is a single paragraph. A lone inserted Return preserves the question and clears focus. Pasted runs of line breaks collapse to one space with focus retained; ordinary text is unchanged. One pure function implements and unit-tests these rules, including applying a supplied character limit after collapsing breaks. This foundation composer remains uncapped; #14 owns the character-limit/count UI. The UI tests require Done to hide the keyboard at standard and largest text sizes, keep the question unchanged, and allow reaching suggestions and submitting. No accessory toolbar or diagnostic input variant remains. The first measured-audit full run verified Done at both text sizes but its largest-text screenshot exposed question text behind the keyboard. Focusing now scrolls the field to the top; the keyboard test also requires its full frame above the keyboard before capturing it. That run also exposed an inline-footer shortcut in the new scrolling helper; only already-visible pinned actions can use that shortcut now.

Three bounded reading-only audit runs on the assigned simulator (`.harness/ask-reading-three-runs.xcresult`) each flagged `reading-situation`, `reading-action` and the off-screen `reading-outcome`. With failure continuation enabled, Action was also reported; earlier tests had stopped at the first flag. The kept Situation and Action images show fully visible text without an overlay. Their measured ratios were **9.061062:1** and **9.060674:1** respectively, identical in all three runs, exceeding the required 7:1 diagnosis gate. Outcome’s off-screen image contained the pinned footer instead, so it was not measured or treated as a visible-text pass.

The shared helper uses the [WCAG sRGB relative-luminance formula](https://www.w3.org/TR/WCAG22/#dfn-relative-luminance), estimates dominant background luminance, and selects the 1% luminance tail farthest from it for text. Synthetic near-10:1 pairs measured 9.894 in both directions; the near-3:1 pair measured 2.995 and remained below 4.5. These self-checks also run in the UI-test target. Alpha-dependent images cannot establish a background and are rejected.

Every audit category stays enabled. Fixtures use the existing Debug Reduce Motion switch and wait for real state/geometry conditions, with no fixed sleep. The Debug-only viewport value comes from the actual scroll layout after safe-area/pinned-action insets. A contrast issue can be dismissed only for plain static text without non-text descendants, fully inside that viewport and its own image measures at least 4.5:1, with identifier, label, image and ratio kept in evidence. No identifier allow-list is used. Off-screen contrast issues are deferred only if the same element is audited fully visible at another stop; unresolved deferrals fail the test. No other audit category is dismissed. The latest passing run’s per-element dispositions are listed below. The stricter current guard leaves native control failures unsuppressed; the earlier button failure and its bounded frequency check are retained under Validation limits.

## Latest complete verification evidence

`lockf /tmp/tarot-ios-harness.lock ./scripts/harness check --device B8FDA44A-52B0-45F2-9FFE-1E3381435CAC` passed on clean commit `49b2eb97368c20274110a70d0ad1588512bf273f` in `.harness/runs/20261013T201947.958208Z-check-f9595a6b/`. It ran **32 Python command tests, the design-role guard, and 26 iOS tests** (13 engine/font and 13 UI), with zero failures, skips, expected failures or runtime warnings. Toolchain: Xcode 27.0 (27A266a), iPhone 17e Tarot 1, iOS 26.5. This pass includes the independent review's layout/capture changes and Draw test synchronisation, but precedes the final composer helper alignment correction described below.

`./scripts/harness evidence` was inspected, and all ten matched states on the generated comparison page were opened with chrome-devtools-axi and visually compared. All **78 exported images** were inspected: 68 full-screen captures and ten contrast crops. The ten main reference states are Draw empty/chosen, Reveal, Today, Ask, composer empty/filled, pick empty/complete and reading. Every touched screen has largest-text captures; Draw, Reveal and both pick states have Reduce Motion captures. Storage-open failure also has standard and largest-text evidence. Missing main references are Welcome, Today’s reminder state, About someone, History and Settings, all outside #13; strict all-screen coverage was not requested.

The author inspection verified the new tabs/entry, all three area labels, complete suggested questions, empty/enabled composer actions, ordered labelled slots, positions/orientations, position passages, lens, reflection and Done. Largest-text captures overlap across long text, include each spread slot, and show reachable actions. Filled-composer top captures include Back, selector and title; separate stops cover the full guidance, field, all three suggestions, footer and keyboard states. Completed-pick top captures include Back, progress and the full question. The focused field is checked and shown above the keyboard at both text sizes. No content or primary action was unreachable in the inspected captures.

The original independent-review input remains preserved separately: clean code/test commit `5494309`, full passing run `20261013T180322.383990Z-check-492295a2`, 73 images (65 full-screen and eight contrast crops). The independent report refers to that original packet. The newer passing packet retains its own manifest copy, references, comparison page, screenshots, logs, result bundle, audit records and the failed-run/frequency evidence. It must not be relabelled as evidence for the pending helper correction.

### Measured contrast dismissals in the latest passing run

These are **all ten** built-in contrast dismissals in run `20261013T201947.958208Z-check-f9595a6b`. Each was contrast-only, plain static text without non-text descendants, fully inside the true viewport and measured from its own kept image. All other screens’ audits passed without a measured dismissal. All categories remained enabled and all controls passed the strict native audit. Ratios below are rounded to six decimal places; kept `accessibility-audit-*` attachments and `audit-records.json` contain full precision, frames, viewport, labels and luminances.

| Audit capture | Element identifier or semantic key | Measured ratio |
| --- | --- | --- |
| `09-reading` | `reading-situation` | 9.061062:1 |
| `09-reading` | `reading-action` | 9.060674:1 |
| `09-reading--action` | `reading-situation` | 9.061062:1 |
| `09-reading--action` | `reading-action` | 9.060674:1 |
| `09-reading--outcome` | `reading-situation` | 9.060874:1 |
| `09-reading--outcome` | `reading-action` | 9.062421:1 |
| `09-reading--bottom` | `reading-situation` | 9.059955:1 |
| `09-reading--bottom` | `label:48:Action · The Sun, reversed` | 5.226312:1 |
| `09-reading--bottom` | `reading-action` | 9.064122:1 |
| `09-reading--bottom` | `reading-lens` | 9.061047:1 |

Outcome was deferred at the top and Action audit stops, then audited fully visible at the Outcome stop. The lens and reflection were deferred at the Outcome stop and audited fully visible at the bottom stop. Off-screen Situation, Action and Outcome card-position labels had already been audited fully visible at the top. No unresolved deferral remained, and no other audit category was dismissed. The synthetic near-3:1 control still failed the 4.5 floor in the measurement self-check.

## Independent comparison follow-up

The fresh-session reviewer opened all 65 full-screen images, eight contrast crops and ten matching references without app source, tests or author findings. The verdict was **“pass after the listed must-fix items”**. This was one independent round; the author then implemented the corrections below. No second independent verdict is claimed.

| Review IDs | Disposition |
| --- | --- |
| C4, CE4 | Shared dawn footer padding now uses the content’s 20-point guide. Final inspection found the composer helper’s intrinsic-width text still centred about six points inside that guide; its footer stack now uses leading alignment. The primary action already met the guide. This last alignment correction awaits fresh standard, largest-text and keyboard-dismissed captures. |
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

The subsequent full strict check on `49b2eb9` passed **26/26**, including the composer control audit and both daily Draw tests. All native controls and mixed/grouped elements retain native failures. Only the ten measured plain-static-text findings listed above were dismissed. The earlier failed runs remain part of the validation record rather than being replaced by the later pass.

### Pending final alignment verification

After that passing run, image inspection found the composer footer helper's intrinsic-width text centred slightly inside the 20-point button/content guide. `QuestionComposerScreen` now uses a leading-aligned footer stack. This is the remaining C4/CE4 detail; it does not change colours, type roles, chip style or audit handling. A fresh full check and inspection of empty/filled, standard/largest-text and keyboard-dismissed composer captures are required before completion. No simulator-driving command will start while Firstmate’s scheduling hold is in force.

## Remaining release limits

Content remains original draft writing requiring editorial review. Unfinished question/pick persistence is #14/#15; crisis handling is #17; History, export and deletion are their own tickets. No account, network, AI service or dependency was introduced. Manual VoiceOver reading order and real-device behaviour are not established by simulator screenshots or XCTest audits.
