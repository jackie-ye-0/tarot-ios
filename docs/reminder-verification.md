# Morning reminder verification (#21)

Status: implementation and local iOS verification passed on 18 October 2026 (Sydney). The writer inspected the retained screenshots and comparison page. Independent comparison and the manual system-permission check remain pending; this is not yet a complete acceptance sign-off.

## Behaviour and tests

The first saved daily draw records the invitation's local date in the same SwiftData transaction. On that date, Today inserts the optional invitation after the extras. Either answer is saved before any permission request; Not now calls no notification API. The invitation expires permanently after leaving the first date. Settings remains available after either answer or expiry.

The reminder uses one stable identifier and a repeating calendar trigger containing hour 8 and minute 0, with no fixed date or time zone. Its title is “Your card is ready” and its body is “Take a quiet moment for today's reading.” No saved card, question or personal data enters its content. This follows Apple's [calendar notification trigger](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger) and [permission API](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)). No APNs registration, network service, new dependency or entitlement is needed.

The UI switch turns on only after permission, scheduling and preference persistence succeed. Off saves the preference then cancels the request. A failed enable-save cancels its new request. Launch and foreground refresh reconcile the saved preference with system permission without prompting. Notification denial leaves the switch off with system-settings instructions. Save and scheduling failures show a retryable native alert.

| Criterion | Evidence |
| --- | --- |
| First-day invitation and equal-effort choices | `testMorningInvitationEvidenceAndPermanentDecline`; equal-width controls and 44-point targets, first-day reference capture |
| Not now, no permission request, no recurrence | Same UI test checks zero permission requests/no pending notification and disk relaunch |
| First-date expiry | `testMorningInvitationExpiresAfterFirstDateEvenWithoutAnswer`, including returning to the earlier date |
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
- **Today:** the gear, two-tab bar, high-contrast selected tab, plain non-navigating area rows and shorter “Ask the cards” entry follow the existing manifest (§11 and §11a). The reference's History tab belongs to #19; it was not added in this ticket. The reference's extra Ask heading/helper remain omitted as in the existing #13 implementation.
- **Invitation:** both labels use the manifest's Gabarito button role; “Not now” is consequently heavier than the reference raster. They have equal widths and target heights. At the largest text size the choices stack as the manifest specifies. The initial native viewport ends part-way through the invitation, so its full controls are retained in the separate invitation capture and remain reachable by scrolling.
- **Settings:** the initial reminder is off until explicit opt-in, unlike the reference's on example. The on variant is retained. “Every day at 8:00 am on this phone.” is added to explain the fixed schedule. The native switch and its wrapping label follow the existing accessible Settings pattern rather than the reference's custom single-line switch artwork.
- **Settings:** the fixture relationship status is “Not set”, and the About/Privacy rows have navigation chevrons because they open child pages. Export and Delete remain omitted under #22, whose text owns those features. These are existing #20 scope/fixture differences.
- **Denied and failure states:** no reference exists. They use the manifest's secondary text and native alert rules, explain the recovery path, and do not claim successful scheduling. Large-text captures show the full denial explanation.

Independent comparison: pending firstmate's fresh-session review. Its verdict and every finding's disposition will be recorded here and in the PR before the first completion handoff.

## Manual system permission check

Pending. Use the dedicated harness simulator after the harness queue is available. Launch an ordinary app session through `./scripts/harness launch` (or an explicitly configured Debug `--test-real-notifications` session). Record the simulator/runtime, date, visible permission prompt and selected response. Check that Not now never opens a prompt; Remind me opens the native prompt; Allow enables the switch; denied permission leaves it off with the explanation; and off cancels the request. Do not change another simulator or assume a simulated permission fixture proves the native prompt. Device notification delivery and Focus/Scheduled Summary timing remain system-controlled.
