# Export and delete all data (#22)

Status: the implementation passed the full check below. Independent review requested two evidence additions; their focused verification passed and the required full rerun is pending. The full scheme remains the committed configuration.

On 19 October 2026 (Sydney), focused run `20261018T222624.975839Z-test-6a017dbc` passed **55/55 tests**, with zero failures or skips: all engine tests plus all three data-ownership UI tests. The actual-largest-system-text run `20261018T222431.409434Z-test-4df8b386` separately passed **53/53**, also with zero failures or skips. The focused scheme was temporary and is not committed. These focused passes are supplementary to the full check below.

The flow run verifies repeated export after dismissal, native Copy of three draws and three readings (including the hidden Career area), cancellation retaining data, successful deletion and persisted Welcome after relaunch, empty History, default preferences, cancelled reminder, export/delete failures and retries, and a fresh draw after reset. Its retained `exported-readings` text was read in full. Strict app-owned audits passed for Settings data actions and returned Welcome; the unchanged measured-contrast rule recorded the Welcome promise at 10.75:1. Bundled-font checks passed. Non-simulator checks after rebase passed all 34 command tests, Swift parsing, the design-role guard and `git diff --check`. Earlier interrupted, cancelled and failed exploratory runs are not claimed as passing verification.

## Behaviour and boundaries

Settings' Good to know group ends with Export my readings and the destructive Delete all my data row. Export produces one UTF-8 `Daybreak-readings.txt` from the saved History snapshots, independent of hidden areas. It includes each daily date and recorded timestamp, card identity, orientation, picked position, original interpretation, keywords, colour, object, hour, all area scores and lines; each question reading includes timestamp, ID, area, question, all three cards/orientations/positions, original sections, connecting passage, reflection, optional response and notes. Named-person readings also include the saved name, relation and original context note, separately from the later reflection note. Old daily snapshots without a timestamp say “Time not recorded”. An empty archive exports a readable empty-state sentence.

The native share sheet receives a local file URL. Copy reads that same file as text. No account, network request, remote metadata lookup, dependency or service is added. The temporary export is removed on dismissal, before another export or deletion, and on launch after interruption. The user controls any destination chosen in the system share sheet.

Delete requires a native confirmation that states its irreversible scope and that copies already saved elsewhere remain. All eight current SwiftData model types are deleted in one save; a failure rolls back the context and leaves Settings and data intact. Success clears session readings, question and spread state, status and area preferences, clears the in-memory installation seed, removes pending and delivered local notifications, and returns to Welcome. The identity remains absent until a new start or app launch, both of which create a fresh seed. The deletion does not remove exports outside the app or phone backups.

The integrated Morning reminder preference is included in the same deletion transaction. The existing notification boundary cancels pending and delivered notifications and clears its Debug fixture. Deletion is unavailable while an asynchronous reminder operation is busy, preventing that operation from restoring data after the wipe. A regression verifies that a failed deletion preserves the scheduled reminder, successful deletion cancels it, a foreground refresh cannot restore it, and a fresh first draw can offer the invitation again.

## Verification map

- Engine export checks cover every daily field, all areas, original reading passages, Unicode and multi-line notes, named-person name/relation/context and all six position labels, orientations, deterministic output, old dates and an empty archive.
- A persisted deletion regression populates every current model, forces a failure after all deletions are staged, checks rollback, retries successfully, checks zero rows of every type, reopens the disk store and checks zero rows again. Session assertions check the empty in-memory state (including the named person), both named-person draft types, rollback preserving their context, and a fresh replacement seed.
- Real-app UI tests export three daily draws and three area readings through the native Copy activity and retain the resulting text. They check hidden-area inclusion, cancellation preserving data, confirmed deletion returning to Welcome, relaunch retaining Welcome, empty History and default preferences, and drawing again after reset.
- Error injection covers failed export/retry and failed delete/retry at ordinary and largest app text sizes. These flags are parsed only in Debug test mode.
- Existing Settings captures retain `11-settings` and its bottom and largest-text variants; this change adds data-action, share-sheet, confirmation and error variants. Returned Welcome uses `01-welcome--after-delete` and its largest-text variant. The existing font-loading and lexical design guard remain unchanged.

## Design comparison

Compare `11-settings` and all data-action variants against `docs/design-reference/11-settings.jpg` and manifest §11i. The integrated morning-reminder section remains between About you and Good to know, as in the reference. Relationship status reflects the synthetic fixture rather than the reference's selected value. Native confirmation/error alerts and the share sheet have no reference images and use system styling, as recorded in the manifest. Welcome is reused without visual changes.

The focused comparison page was opened in Chrome and the Settings data-action, normal alert/share-sheet and returned Welcome captures were inspected against the references and manifest. Largest-app-text data-action/Welcome captures and all eight actual-largest-system-text images were also inspected. The primary controls remain whole and reachable.

Accepted differences to carry into the pull request:

- Settings uses native status-bar/safe-area space, font metrics, deterministic grain, growing row heights and scrolling, so the full page is taller than the web reference. The reference's group and action order, colours, labels and surface roles are retained. Unset relationship status and reminder on/off values are synthetic fixture state. The existing reminder helper explains its schedule; About and Privacy chevrons identify navigation, while export/delete have none, as §11e/§11g/§11i specify.
- At largest text, action labels wrap and the page scrolls; the complete Export and Delete rows remain visible. This follows the existing uncapped accessibility layout rather than shrinking text to fit the reference.
- Returned Welcome reuses the established screen: real status indicators, native font/safe-area spacing, deterministic grain and minor code-drawn card-back geometry differ from the web rendering. These retain the manifest roles and existing foundation treatment. At accessibility sizes the primary action follows the scrolling content, as required.
- Confirmation/error alerts and the system share sheet have no separate reference. They use iOS typography, controls and destructive tint, as §11i requires. Actual-largest-system-text differences are recorded below.

The final full-run comparison page was opened in Chrome. Settings top/bottom and data-action captures, the normal native confirmation/error/share-sheet states, and returned Welcome normal/largest captures were inspected again. The accepted differences above remain; independent findings are pending.

## Final full check

`./scripts/harness check` run `20261019T000249.892921Z-check-74921b18` passed on clean `0fffd35fa86902d15bf8408552f0e7aa3ea29d95` after rebasing onto `7284429`. Its final summary reports **124/124 tests**, zero failures, skips or expected failures. All **34 command-contract tests** and the design-role source guard passed. The bundled-font test and all five data-ownership engine tests passed, including named-person export and persisted deletion/rollback/reopen. The UI tests passed the real app workflows through Debug test mode. There are **552 exported images**, with a main capture for all 15 design references; unrelated regression screens are retained as context, not added to this ticket's review scope.

The evidence command and result metadata were inspected. The native Copy attachment contains three daily draws and three readings, including hidden Career, original text and note fields. Settings and returned Welcome retain their strict app-owned audit coverage. This ticket does not alter Draw, Reveal or the three-card pick; their existing largest-text and Reduce Motion captures and tests also passed in the full suite. No new colour, font or radius is defined outside the design system.

The final packet contains the full-run comparison, references and images, the current manifest, and the separate actual-largest-system-text evidence below. The latter predates the named-person rebase; Settings' alert/share-sheet presentation and the reused Welcome view are unchanged by that integration. The final full run supplies the current normal-system and largest-app-text states. Physical-device behaviour and manual VoiceOver reading order remain unverified, as for the existing app.

## Native platform audit boundary

Firstmate confirmed on 19 October 2026 (Sydney), inbox 003, that native alerts follow the existing platform boundary used for image sharing and reminders: keep native confirmation/error alerts, retain every strict app-owned audit, and verify native alerts with actual largest-system-text captures plus full-text and reachable-action assertions. Only the new native-alert audit calls/helper were removed; no finding is filtered and the existing Settings/Welcome audit helper is unchanged. The failed exploratory runs `20261018T192933.285319Z-test-a0765f44` and `20261018T193417.523909Z-test-7e78b046` reported “Dynamic Type font sizes are partially unsupported” on UIKit alert text, including after all alert elements settled and every category ran in manifest order. They are not passing verification. The final native system-size run `20261018T222431.409434Z-test-4df8b386` passed all 53 tests with no failures or skips. Its retained category is `UICTContentSizeCategoryAccessibilityXXXL`; host `simctl ui` readbacks confirmed the setting before the run and restoration to `large` afterwards. All eight exported images were inspected, including the first and final scroll positions of each alert, the share sheet and returned Welcome. Exact full message text is asserted; the final line must be reachable inside the native text viewport, and every action must remain within the window and hittable. The prior iterations exposed XCTest's 128-character identifier-query limit and an incorrect expectation that a long scrolling paragraph fit wholly in the window; the final assertions use an exact-label predicate and check the real text viewport after scrolling.

Accepted native differences: at the largest system size, alert wording scrolls and the edges show partial lines while moving between the first and final positions; actions remain fixed and reachable. The native share sheet truncates its secondary document-type/size metadata and uses a horizontal app-destination shelf, while the complete filename, Copy, Save to Files and Close remain available. These controls and fonts belong to iOS, consistent with the approved native boundary. Returned Welcome uses its existing scrolling accessibility layout, with its primary action fully visible in the retained capture. The full check above passed; independent comparison remains pending.

## Independent comparison and dispositions

A fresh reviewer who did not write the change inspected the manifest, both in-scope references and all 560 supplied images on 19 October 2026. It reviewed 42 touched-state captures in detail and the others only for obvious regression/crop problems. Its verdict was **“pass after the two listed must-fix evidence items, DC-01 and EX-02”**; it found no product/layout defect and recommended no redesign. Firstmate requested the two capture additions and a recheck. Both additions passed focused verification and author inspection; the required full rerun and independent recheck remain pending, so this is not yet an unconditional independent pass.

| Finding | Disposition and reason |
| --- | --- |
| ST-01 | Accepted: real status indicators and the heavier/inset native Back chevron follow the native-chrome rule; no fake status bar. |
| ST-02 | Accepted: lower title/groups, larger gaps and taller rows scroll within the shorter native viewport. The bottom sequence exposes every action; rows follow the manifest's 60–76-point range. |
| ST-03 | Accepted: headings/helpers share the 20-point dawn page guide, preserving consistent alignment. |
| ST-04 | Accepted: native switch proportions and brighter knobs are required; reminder on/off differences are fixture state. |
| ST-05 | Accepted: Not set is a supported relationship value, rather than the reference's selected value. |
| ST-06 | Accepted: the reminder label wraps and its added schedule helper follows §11g; rows grow without truncating text. |
| ST-07 | Accepted: About and Privacy navigate and therefore have chevrons; export/delete are actions and explicitly omit them. |
| ST-08 | Accepted: deterministic grain and minor native glyph/weight/rasterisation differences retain the named dawn/surface/ink/secondary/destructive roles. |
| EX-01 | Accepted: system material, typography, icons and actions follow §11i's native-sheet requirement. Preview file-size differences reflect fixture content. |
| EX-02 | Fixed in the capture test: `11-settings--export-sheet-largest-system-text-destinations.png` shows the complete More icon and label after horizontal scrolling; the opening image is retained. Author inspection confirms both destinations can be read across the pair. No custom share sheet. Independent recheck pending. |
| EX-03 | Accepted with explicit limitation: the largest-system sheet ellipsises secondary file-size metadata. Document name/type and primary actions remain readable; no claim of literally zero truncation is made. |
| EE-01 | Accepted: the native export error correctly reports unchanged saved readings and provides Cancel/Try again. |
| EE-02 | Accepted: separate actual-system opening/end images cover the complete scrolling error message and stacked actions. App-only large text is not counted as native scaling proof. |
| DC-01 | Fixed in the capture test: `11-settings--delete-confirmation-largest-system-text-middle.png` shows the whole daily-card identity/reminder-cancellation clause. It overlaps the opening at “preferences” and the end at “It cannot be”. A slow held drag preserves this intermediate stop; the endpoints are retained. Author inspection confirms continuous wording coverage. Independent recheck pending. |
| DC-02 | Accepted: the ordinary confirmation contains the required scope, irreversibility and external-copy warning with separate Cancel/Delete actions. |
| DC-03 | Accepted: the native destructive red, wrapped label and stacked action order follow the required system alert; actions remain clear and readable. |
| DE-01 | Accepted: the native deletion error keeps Settings behind it, explains unchanged data and offers OK before another confirmed attempt. |
| DE-02 | Accepted: opening/end images overlap and collectively expose the full actual-largest-system deletion-error text and reachable OK; partial lines at a scroll boundary are covered at another stop. |
| WE-01 | Accepted: real status indicators and the slightly wider 24-point night guide follow the manifest. |
| WE-02 | Accepted: small upward composition shifts accommodate native safe areas while retaining the card's dominance, hierarchy and complete ordinary footer. |
| WE-03 | Accepted: small inner-frame/ray/shadow/grain differences retain the tilted tall card, gold double frame, half-sun/horizon and single disc grammar. |
| WE-04 | Accepted: native glyph rendering and largest-text reflow grow the headline, promise and action without shrinking text. |
| WE-05 | Accepted using the complete reused-Welcome top/promise/bottom sequence: the large-text footer is inline and scrollable, and all copy/actions appear across that sequence. |

The reviewer found the required settled Reduce Motion states in the regression images but made no motion-sequence verdict from stills. It did not certify persistence, network absence, font loading, measured contrast, actual system settings or VoiceOver order from screenshots; the applicable automated results and remaining manual limitations are recorded separately above.

### Capture additions after review

Focused run `20261019T024657.032359Z-test-7428ad80` passed **59/59 tests**, zero failures or skips. It retained ten images at actual `UICTContentSizeCategoryAccessibilityXXXL`, including DC-01's middle-warning capture and EX-02's horizontally scrolled destination strip. The opening/end warning and opening share-sheet captures remain. Those four warning/sheet images were inspected together: the entire missing warning clause and the full More icon/label are visible. Host readbacks confirm the actual largest system size before the run and restoration to `large` afterwards. This changes only UI evidence collection and documentation; app behaviour/layout is unchanged. The full rerun required for test-code changes is pending.
