# Morning reminder verification (#21)

Status: the initial implementation passed local iOS verification on 18 October 2026 (Sydney). The writer inspected its retained screenshots and comparison page. The L1/F2/F3 follow-up full run completed with 96/97 tests passing; the unchanged card-size proof test failed to advance from The Star to Ten of Wands. This follow-up is not a passing full check. The independent visual recheck passed with L1/F2/F3 closed. Validation after rebasing onto History and the manual system-permission check remain pending; this is not yet a complete acceptance sign-off.

## Behaviour and tests

The first saved daily draw records the invitation's local date in the same SwiftData transaction. On that date, Today inserts the optional invitation after the extras. Either answer is saved before any permission request; Not now calls no notification API. The invitation expires permanently after leaving the first date. Settings remains available after either answer or expiry.

The reminder uses one stable identifier and a repeating calendar trigger containing hour 8 and minute 0, with no fixed date or time zone. Its title is “Your card is ready” and its body is “Take a quiet moment for today's reading.” No saved card, question or personal data enters its content. This follows Apple's [calendar notification trigger](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger) and [permission API](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)). No APNs registration, network service, new dependency or entitlement is needed.

The UI switch turns on only after permission, scheduling and preference persistence succeed. Off saves the preference then cancels the request. A failed enable-save cancels its new request. Launch and foreground refresh reconcile the saved preference with system permission without prompting. Notification denial leaves the switch off with system-settings instructions. Save and scheduling failures show a retryable native alert.

| Criterion | Evidence |
| --- | --- |
| First-day invitation and equal-effort choices | `testMorningInvitationEvidenceAndPermanentDecline`; equal-width controls and 44-point targets, first-day reference capture |
| Not now, no permission request, no recurrence | Same UI test checks zero permission requests/no pending notification and disk relaunch |
| First-date expiry | `testMorningInvitationExpiresAfterFirstDateEvenWithoutAnswer`, including returning to the earlier date and excluding the invitation from an archived card |
| Allow schedules daily 08:00 with generic copy | `testMorningReminderSchedulesPersistsCancelsAndReflectsRevocation` checks the actual request built at the platform boundary |
| Settings asks only when needed; denied remains off | `testMorningReminderDenialAndSettingsPermissionRequest` exercises both entry points, no repeated request after denial, and the explanation |
| Off cancels; on/off survives relaunch; revoked permission | `testMorningReminderSchedulesPersistsCancelsAndReflectsRevocation` |
| Failure recovery | `testMorningReminderFailuresRemainRecoverable` checks rollback on failed dismissal and a scheduling retry with no second permission request |
| Engine seam | `MorningReminderRuleTests` checks eligibility, permanent expiry and local 08:00 across three zones including Sydney's daylight-saving change |

The test-mode notification boundary is in memory and never shows the system prompt. It builds the same `UNNotificationRequest` as the real path, retaining it for the UI test evidence. It proves app control flow and request configuration, not OS delivery. A relaunch fixture explicitly provides the permission retained by the simulated system; the reminder preference itself persists in the real SwiftData test store.

## Design check

Touched screens: Today (`04-today-first-day` and normal `04-today`) and Settings (`11-settings`). New states: invitation, denial, reminder enabled/disabled, and update failure. The manifest describes their layout and copy. Existing test coverage retains normal and largest-text Today/Settings screens; new tests retain the first-day top, invitation, bottom and largest-text choices, plus enabled, denied and failure states. Existing Draw, Reveal and pick Reduce Motion evidence remains in the full suite; this ticket changes none of those screens.

`./scripts/harness doctor` passed. `./scripts/harness check` passed with **96 tests passed, zero failures and zero skips**, plus **34 command-contract tests** and the lexical design-role guard. The bundled-typeface registration test passed. The native accessibility audits remained strict, with all categories enabled on settled Today and Settings screens. The retained denied-state contrast measurements use the existing audited helper; no audit code was changed.

Run: `.harness/runs/20261017T160555.520960Z-check-2fafed54`. Xcode 27.0 (27A266a), iOS Simulator 26.5, dedicated `iPhone Tarot Harness 36a5dbe24882e53f` (`7F3CF927-C74F-458F-8320-D614D6AC2AFA`), 390 × 844 points. The harness acquired its shared queue at 17:39 UTC and completed at 19:03 UTC on 17 October. Its `summary.json`, raw test log and retained attachments establish the run. It was built from the uncommitted implementation; only verification documentation changed after it passed.

The writer opened `design-comparison.html` with `chrome-devtools-axi` and inspected the exported first-day top, invitation, bottom, largest-text, denied and failure captures, plus Settings top/bottom, on, off, denied, failure and largest-text captures. Both invitation choices fit at standard size and remain fully reachable together after scrolling at the largest size. The large-text reminder label and switch reflow without truncation, and the denial guidance can be read in full.

Accepted visible differences to carry into the PR:

- **Both screens:** the web references show full scrolling documents; native captures are 390 × 844-point viewports with real system status/safe areas. Top, intermediate and bottom captures show the complete content. Native font rasterisation and the existing grain rendering differ slightly; the bundled font test and design roles pass.
- **Today:** the fixture is Sunday 11 October 2026, rather than the reference's Saturday. Original bundled interpretation/area copy and “Sage” differ from the example wording; these are the existing saved-content rules from #9. Card-face linework follows the established #12 grammar.
- **Today:** the gear, high-contrast selected tab, plain non-navigating area rows and shorter “Ask the cards” entry follow the existing manifest (§11 and §11a). The original captures had two tabs; the rebased branch preserves the three-tab shell and History supplied by #19. The reference's extra Ask heading/helper remain omitted as in the existing #13 implementation.
- **Invitation:** both labels use the manifest's Gabarito button role; “Not now” is consequently heavier than the reference raster. They have equal widths and target heights. At the largest text size the choices stack as the manifest specifies. The initial native viewport ends part-way through the invitation, so its full controls are retained in the separate invitation capture and remain reachable by scrolling.
- **Settings:** the initial reminder is off until explicit opt-in, unlike the reference's on example. The on variant is retained. “Every day at 8:00 am on this phone.” is added to explain the fixed schedule. The native switch and its wrapping label follow the existing accessible Settings pattern rather than the reference's custom single-line switch artwork.
- **Settings:** the fixture relationship status is “Not set”, and the About/Privacy rows have navigation chevrons because they open child pages. Export and Delete remain omitted under #22, whose text owns those features. These are existing #20 scope/fixture differences.
- **Denied and failure states:** no reference exists. They use the manifest's secondary text and native alert rules, explain the recovery path, and do not claim successful scheduling. Large-text captures show the full denial explanation.

## Independent comparison and follow-up

The fresh-session reviewer inspected all 384 images, with detailed review of the eight Settings/reminder states and a quick regression review of Today and other screens. Initial verdict: **pass after L1**, a missing middle scroll stop in the largest-text Settings evidence. The reviewer found no definite clipping or overlap defect in the reminder UI. Firstmate requested the following fixes and a limited check of the added images:

| Finding | Disposition |
| --- | --- |
| L1, R3: area helper, About you and the complete relationship row lack largest-text evidence | Added UI-test stops named `11-settings--largest-text-area-helper`, `--largest-text-about-you-heading` and `--largest-text-about-you`. Each asserts its entire target is inside the viewport; no layout change. The writer and independent reviewer inspected the captures; the helper, heading and complete relationship row are visible across overlapping stops. Closed by the limited recheck. |
| F2: scheduling alert suggests an unestablished storage cause and redirects to Settings while already there | Fixed and closed by the limited recheck. The message now follows the failed action; enabling from Settings says “Try turning this reminder on again.” Invitation dismissal says “Try your reminder choice again.” Only failures outside app Settings name that destination. The UI test asserts the new scheduling recovery line. |
| F3: native scheduling alert lacks largest system-text evidence | Added `testMorningReminderSchedulingFailureSystemTextEvidence`, which inherits real system text, records the category and verifies the whole title/message/OK action. The host set and read back `accessibility-extra-extra-extra-large` on this worktree's dedicated simulator. Focused run `20261017T192625.649543Z-test-cd5eabdf` passed 44/44 tests (engine target plus this UI test), with zero failures/skips. The writer inspected the retained `11-settings--reminder-schedule-failure-largest-text` image: title, recovery line and OK are complete and reachable. The host restored and read back `large`, and the original full-test scheme was restored byte-for-byte. The independent reviewer closed the enlarged alert layout finding; the host transcript separately establishes the actual text category. The subsequent full run is recorded below; it is not green. |
| S1–S2: system chrome and heavier native navigation symbols | Accepted: real status bar and recognisable native controls; no fake chrome or extra primary action. |
| S3–S4: lower groups, taller rows, outer-guide alignment and native text metrics | Accepted: coherent 20-point alignment, readable rows and scrolling content; do not compress to fit the full web artboard. |
| S5, S7, O1: native switch shape/grey off state and wrapped reminder label | Accepted: the manifest specifies native switches and growing rows. The on state is clear; large off/denied captures establish shared reflow. |
| S6: relationship status “Not set” | Accepted: a valid saved fixture state explicitly supported by the manifest. |
| S8: added 08:00 helper | Accepted: required by the updated manifest. |
| S9: absent Export/Delete | Accepted: issue #22 owns these features; the manifest requires omission until functional. |
| S10: About/Privacy chevrons | Accepted: the rows navigate to child pages, following the list rule. |
| S11: more mottled/less pink grain and native edge rendering | Accepted: decorative texture preserves the dawn hierarchy; role/contrast checks establish code-level compliance separately. |
| O2, D3, B2: shared shell differences | Accepted for S1–S11's reasons. The normal/bottom captures cover unchanged lower content. No separate large on-state claim is made. |
| D1–D2, DL1: denied copy and no extra Settings button | Accepted: the complete explanation follows the manifest; no separate button is required. |
| R1–R2, DL2, L2–L3, B1: large-text reflow and scroll-boundary crops | Accepted: complete controls/helpers are readable across overlapping captures. R2 is a denied-state stop; the ordinary helper is shown separately. L1 addresses the missing middle coverage. |
| F1: native alert styling | Accepted: the manifest specifies a native error alert, with an off switch underneath and no success claim. |

The reviewer also accepted the settled Reduce Motion captures and found no obvious regression in the other image families. Static images do not establish animation timing, VoiceOver order, notification permission or delivery. Firstmate requested one full harness check after the changes and then a limited recheck of the new images. Follow-up run `.harness/runs/20261017T192844.676625Z-check-e16dbdf6` completed with **97 total, 96 passed, one failed, zero skipped**, exit 65. Its only failure is `testFaceSizesAndLargestTextProof`: after the first Next cards tap, the first sample remained The Star when Ten of Wands was expected. The test method and proof sample/deck code are identical to `origin/main` at `25c012b9d466423ff2505a8f02683a854880e95c`; the proof entry bypasses AppSession and the store. Retained video confirms that page advancement did not complete. This supports a pre-existing proof-navigation timing failure, but the exact reason the tap failed to advance is unproven without a rerun. Firstmate accepted the diagnosis and authorised one isolated rerun. Run `20261017T211201.038784Z-test-5d17fdc1` passed the unchanged proof test (1/1, zero failures/skips, xcodebuild exit 0); the harness exited 1 solely because its unchanged minimum is four tests. This does not turn the preceding full run green. The full scheme was restored and the worktree was clean afterward.

The independent reviewer’s 18 October addendum gives a **pass**, closing L1, F2 and F3 with no must-fix remaining. All eight linked built captures and the Settings reference were opened individually against the manifest, without inspecting source or test logs. The review found no new difference needing correction or acceptance. It confirms visual completeness only; the existing accepted differences and the original quick-review scope for Today still apply.

## Integration with History

Rebased onto `origin/main` at `5d44a9e`. History’s navigation, timestamps, store revision and test fixtures are preserved. The shared Today view accepts the reminder session only for live Today; an archived card has no invitation. The existing expiry UI test now also checks an archive round trip leaves the live invitation available. The manifest records this distinction.

Before the full integration run, Swift parsing passed for all 17 Swift files, all 34 command-contract tests passed, and the unchanged lexical design guard passed. The full harness check on this rebased code is pending; the earlier runs above do not verify this revision.

## Manual system permission check

Pending. Use the dedicated harness simulator after the harness queue is available. Launch an ordinary app session through `./scripts/harness launch` (or an explicitly configured Debug `--test-real-notifications` session). Record the simulator/runtime, date, visible permission prompt and selected response. Check that Not now never opens a prompt; Remind me opens the native prompt; Allow enables the switch; denied permission leaves it off with the explanation; and off cancels the request. Do not change another simulator or assume a simulated permission fixture proves the native prompt. Device notification delivery and Focus/Scheduled Summary timing remain system-controlled.
