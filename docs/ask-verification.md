# Ask foundation (#13)

Scope: the first complete Today → Ask → composer → three-card pick → reading path. The full local check and author image comparison passed on 14 October 2026. The required independent comparison is pending.

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

The author compared the final captures with all ten applicable reference states. These differences are accepted for the reasons below, subject to the independent comparison. They are not exceptions to accessibility or action reachability. The original artwork, grain, daily wording and native rendering differences recorded in [foundation verification](foundation-verification.md) remain applicable to Draw, Reveal and the basic Today.

| Screen | Difference and reason |
| --- | --- |
| Draw and Reveal | Standard composition retains the #7 foundation and its documented artwork, fan, texture and safe-area differences. At accessibility sizes the shared primary action uses the 22-point surface radius instead of a capsule, keeping multiline text away from the corners; actions remain inline and reachable. |
| Today | The existing basic card/interpretation gains the Ask entry and two tabs. Scores, extras, area readings and other fuller Today content belong to #9; Settings is #20 and the reminder is #21. |
| Today and Ask tabs | Two tabs rather than three, explicitly required by #13. History joins in #19. Icons use the platform symbols within the manifest's selected-pill and labelled-tab treatment. The selected pill uses ink fill and a surface-coloured icon after the native accessibility audit rejected the reference tint, including with an ink outline. The label remains ink on surface. |
| Ask | The context panel, recent reading and relationship-status prompt belong to #14. The named-person entry belongs to #18. The remaining content keeps the manifest's hierarchy and leaves open ground below the suggestions. Suggestions are actual questions, as required by #13 and the manifest, unlike the reference's topic phrases. |
| Composer, empty and filled | Character count/limit and the miniature empty-slot preview belong to #14. The explanatory three-card sentence remains above the primary action. The native keyboard Done key dismisses it; no accessory toolbar is added. The selector reserves a 44-point Back target, and the title wraps after “ask” rather than “to” at default size. Native font metrics, safe-area placement and the manifest’s section spacing are retained instead of forced line breaks or compressed type. |
| Three-card pick | Static reuse of the existing fan gives a wider, deeper spread than the mock-up, retaining the established card-back drawing and five separate tap lanes. The progress label centres in the space beside the 44-point Back control; the ritual disc is larger than the mock-up, using the foundation’s 1.345-width proportion in the shared screen ground and staying in place across both states. Shuffle, pulse and restoration of unfinished picks belong to #15. A quiet instruction replaces the absent shuffle action. Empty slots have an explicit night-ground fill so their gold numerals retain contrast over the disc. The cards show the injected starter draw, rather than the reference's sample spread. |
| Completed pick | The same six-card starter art and original names replace the reference examples. Filled cards use the required gold outline and say “Upright” as well as “Reversed”, adding a line to upright cards so orientation is always explicit. Distinct full-library faces are #12. |
| Reading | Original starter position meanings and the area lens replace the sample reading. Cards retain the starter faces and explicit Upright/Reversed labels described above. Area-coloured section headings use darker partners (5.7–5.9:1 on plain ground) after the native audit rejected the former near-threshold relationship colour over grain. The saved label says “Saved on this phone” until History exists (#19). Feedback and More belong to #16; Share belongs to #23. Done remains the only primary action and is pinned at standard size, following the manifest; it becomes inline at accessibility sizes. The small decorative area dot is omitted: the area is written in the saved label and repeated by the section-heading colour. |
| All touched screens | Native status bar and safe-area placement; bundled native font rendering and original deterministic grain can differ slightly from web/JPEG rendering. Larger text wraps and scrolls instead of being reduced to match the reference. |

The largest-text layout keeps three labelled area choices visible in a vertical segmented selector, moves the composer's Back control to its own row, stacks spread cards, and places the action after scroll content. Multiline controls use the surface radius to keep their text clear of the corners. These adaptations and states without reference images are described in `design.md` §11a.

## Keyboard editing and contrast verification

The toolbar warning was attributed with one bounded, two-variant UI test on 14 October 2026 (local date), under the shared simulator lock. The intended multiline field without its accessory toolbar and a bare single-line field both passed with zero runtime warnings in `.harness/ask-keyboard-no-toolbar.xcresult`. The original toolbar-containing composer emitted “Invalid frame dimension (negative or non-finite)” on focus. Removing the toolbar eliminated that warning in the next full run, but `onSubmit` did not dismiss the multiline field: the native Done key inserted a newline. The final editing rule intercepts that edit instead, while retaining the wrapping field.

A question is a single paragraph. A lone inserted Return preserves the question and clears focus. Pasted runs of line breaks collapse to one space with focus retained; ordinary text is unchanged. One pure function implements and unit-tests these rules, including applying a supplied character limit after collapsing breaks. This foundation composer remains uncapped; #14 owns the character-limit/count UI. The UI tests require Done to hide the keyboard at standard and largest text sizes, keep the question unchanged, and allow reaching suggestions and submitting. No accessory toolbar or diagnostic input variant remains. The first measured-audit full run verified Done at both text sizes but its largest-text screenshot exposed question text behind the keyboard. Focusing now scrolls the field to the top; the keyboard test also requires its full frame above the keyboard before capturing it. That run also exposed an inline-footer shortcut in the new scrolling helper; only already-visible pinned actions can use that shortcut now.

Three bounded reading-only audit runs on the assigned simulator (`.harness/ask-reading-three-runs.xcresult`) each flagged `reading-situation`, `reading-action` and the off-screen `reading-outcome`. With failure continuation enabled, Action was also reported; earlier tests had stopped at the first flag. The kept Situation and Action images show fully visible text without an overlay. Their measured ratios were **9.061062:1** and **9.060674:1** respectively, identical in all three runs, exceeding the required 7:1 diagnosis gate. Outcome’s off-screen image contained the pinned footer instead, so it was not measured or treated as a visible-text pass.

The shared helper uses the [WCAG sRGB relative-luminance formula](https://www.w3.org/TR/WCAG22/#dfn-relative-luminance), estimates dominant background luminance, and selects the 1% luminance tail farthest from it for text. Synthetic near-10:1 pairs measured 9.894 in both directions; the near-3:1 pair measured 2.995 and remained below 4.5. These self-checks also run in the UI-test target. Alpha-dependent images cannot establish a background and are rejected.

Every audit category stays enabled. Fixtures use the existing Debug Reduce Motion switch and wait for real state/geometry conditions, with no fixed sleep. The Debug-only viewport value comes from the actual scroll layout after safe-area/pinned-action insets. A contrast issue can be dismissed only when fully inside that viewport and its own image measures at least 4.5:1, with identifier, label, image and ratio kept in evidence. No identifier allow-list is used. Off-screen contrast issues are deferred only if the same element is audited fully visible at another stop; unresolved deferrals fail the test. No other audit category is dismissed. The final run’s per-element dispositions are listed below.

## Final evidence and independent comparison

`lockf /tmp/tarot-ios-harness.lock ./scripts/harness check --device B8FDA44A-52B0-45F2-9FFE-1E3381435CAC` passed on clean code/test commit `5494309` in `.harness/runs/20261013T180322.383990Z-check-492295a2/`. It ran **32 Python command tests, the design-role guard, and 26 iOS tests** (13 engine/font and 13 UI), with zero failures, skips, expected failures or runtime warnings. Toolchain: Xcode 27.0 (27A266a), iPhone 17e Tarot 1, iOS 26.5. This report-only update does not change the tested app or tests.

`./scripts/harness evidence` was inspected, and the generated comparison page was opened with chrome-devtools-axi. All **73 exported images** were inspected: 65 full-screen captures and eight contrast crops. The ten main reference states are Draw empty/chosen, Reveal, Today, Ask, composer empty/filled, pick empty/complete and reading. Every touched screen has largest-text captures; Draw, Reveal and both pick states have Reduce Motion captures. Storage-open failure also has standard and largest-text evidence. Missing main references are Welcome, Today’s reminder state, About someone, History and Settings, all outside #13; strict all-screen coverage was not requested.

The author inspection verified the new tabs/entry, all three area labels, complete suggested questions, empty/enabled composer actions, ordered labelled slots, positions/orientations, position passages, lens, reflection and Done. Largest-text captures overlap across long text, include each spread slot, and show reachable actions. The composer additionally captures its full guidance, empty/filled field, complete suggestion list, keyboard and post-dismissal action. A native off-screen text field can lack usable geometry: the helper now rejects empty/invalid frames, approaches that field through surrounding text, and checks its visible frame before capture. This closes the earlier false-passing footer capture. The focused field is also checked and shown above the keyboard at both text sizes.

### Final measured contrast dismissals

These are **all eight** built-in contrast dismissals in the final run. Each issue was contrast-only, fully inside the true viewport and measured from its own kept image. All other screens’ audits passed without a measured dismissal. All categories remained enabled. Ratios below are rounded to six decimal places; kept `accessibility-audit-*` attachments and the packet’s `audit-records.json` contain full precision, frames, viewport, labels and luminances.

| Audit capture | Element identifier | Measured ratio |
| --- | --- | --- |
| `09-reading` | `reading-action` | 9.060674:1 |
| `09-reading` | `reading-situation` | 9.061062:1 |
| `09-reading--action` | `reading-action` | 9.060674:1 |
| `09-reading--action` | `reading-situation` | 9.061062:1 |
| `09-reading--bottom` | `reading-lens` | 9.060849:1 |
| `09-reading--bottom` | `reading-situation` | 9.060999:1 |
| `09-reading--outcome` | `reading-action` | 9.062703:1 |
| `09-reading--outcome` | `reading-situation` | 9.061240:1 |

Outcome was deferred at the top and Action audit stops, then audited fully visible at the Outcome stop. The reflection was deferred at the Outcome stop and audited fully visible at the bottom stop. An off-screen “Action” card-position label had already been audited fully visible at the top. No unresolved deferral remained, and no other audit category was dismissed. The synthetic near-3:1 control still failed the 4.5 floor in the measurement self-check.

### Independent comparison

Pending Firstmate’s fresh-session reviewer. The final packet contains the committed manifest, references, built screenshots, comparison page, run summary and kept audit evidence. The reviewer receives only the images and manifest, with a handoff naming the touched states. Findings and each disposition will be recorded here before the first completion handoff, and in the eventual pull request.

## Remaining release limits

Content remains original draft writing requiring editorial review. Unfinished question/pick persistence is #14/#15; crisis handling is #17; History, export and deletion are their own tickets. No account, network, AI service or dependency was introduced. Manual VoiceOver reading order and real-device behaviour are not established by simulator screenshots or XCTest audits.
