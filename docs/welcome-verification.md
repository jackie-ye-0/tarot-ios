# Welcome on first open (#8)

Scope: the Welcome screen shown before Draw on first open, and saving its completion on the device. Installations created before Welcome existed are treated as having seen it. Draw, Reveal, Today and the storage-open error screen are unchanged; a read failure just after Welcome is saved now also leads to that screen. Their captures in the same run are regression coverage. No reading rule, dependency or service changed.

## Behaviour and evidence

- `testWelcomeFirstOpenDesignAndPersistentRouting` starts from an empty on-disk store. Before any tap it asserts the app name, headline, promise and full disclaimer are visible with their exact exposed text, that there is exactly one button ("Draw my first card"), and that there are no text fields or app or system alerts. It runs the unfiltered accessibility audit on the settled screen and keeps the `01-welcome` capture. It then relaunches before tapping (Welcome returns), taps through to Draw, and relaunches again: Draw while today's card is undrawn, Today after drawing, and Draw on the next date, never Welcome.
- `testWelcomeRemainsUntilContinuedAcrossMidnight` shows a date change cannot dismiss Welcome and that the button then opens Draw for the new date.
- `testWelcomeFloatingCardDoesNotDelayTheFirstDraw` reaches Draw and Reveal with ordinary animation on.
- `testWelcomeLargestTextAndReducedMotion` captures the largest text size at three scroll positions (top, promise, bottom), asserting the whole headline is visible at the top and the primary action is reachable at the bottom. With Reduce Motion it captures the screen and compares two content images a second apart to show the card is still.
- `testWelcomeSaveFailureKeepsWelcomeAndAllowsRetry` uses the Debug-only `--test-welcome-save-failure` switch to fail the first save. It asserts the native alert's title, message and single button, keeps the `01-welcome--save-failed` capture, confirms Welcome is still in place after dismissal, and follows the retry through to Draw.
- Unit tests cover the store and routing rules. `testLegacyInstallWithoutWelcomeFieldSkipsWelcome` saves an identity in the pre-Welcome store format to a temporary file and reopens it through the app's store: Welcome is skipped. `testNewInstallShowsWelcomeOnlyOnce`, `testCompletingWelcomeWithTodaysDrawRoutesToToday` and `testReadFailureAfterSavingWelcomeRetriesPastWelcome` show that completing Welcome hands off through the launch routing: Draw, Today when today's card is already drawn, and, after a read failure, the storage-failure screen's retry lands past Welcome.
- No reading rule changed. Routing and real SwiftData persistence across relaunch are also exercised through the UI seam.

## Independent findings and dispositions

One independent round was run by a fresh session given only the manifest, the reference image and the captures. Its verdict was **pass after one must-fix, W-01**. Positions below are in points on the 390 by 844 reference screen.

| Finding | Disposition |
| --- | --- |
| W-01, headline lines too far apart for the Display rule (1.0 to 1.05) | **Fixed.** The headline keeps its natural frame and a text renderer draws the first line lower, taking Gabarito's own 1.2 line height to 1.04. Measured on the same letters in each image, the baseline pitch is now about 41.4 points, line height about 1.035, against 48.0 before and about 42 in the reference; the review's 46.7 and 40.5 used a different measuring point. The gap between headline and promise is now the 12-point related-item gap, so the first line dropped 10.7 points and the second 4.0, which puts the headline within 2 points of the reference's position above the promise. The manifest rule is unchanged. |
| W-02, the card has no shadow | **Fixed.** The Welcome card alone carries a soft shadow in the night ground colour; Draw card backs stay flat. Sampled below the card's bottom edge it reads `#21193a`, `#251c40` and `#2b214b` at 3, 15 and 30 points, back to the disc colour by 60, against `#201937`, `#241d3f` and `#2a2148` in the reference. |
| W-03, wordmark lighter and larger than the reference | **Fixed.** Daybreak is now Gabarito 700 at 20 points: 81.7 points wide against 81.5 in the reference (88.7 before). Size 20 is the bottom of the Section title range. The weight is the reference's bolder cut, which the Section title's 600 cannot produce, so the manifest's Welcome paragraph records it. |
| EV-01, no capture of the save-failure alert | **Fixed.** `01-welcome--save-failed` shows the native alert over Welcome. Against the manifest's rule for this state: Welcome stays in place, the alert explains how to retry, says saved cards are unchanged, and the retry works. |
| W-04, disc about 12 points higher, its edge passing behind the wordmark | **Accepted.** Legibility is unaffected (cream on disc 11.7:1) and no rule covers it. The narrower wordmark shortens the overlap to its last letters. The disc stays centred on the card. |
| W-05, side padding 24, not 28 | **Accepted.** The manifest sets 24 on the night ritual screens and Draw uses 24. The manifest wins over the picture. |
| W-06, card slightly shorter with rounder corners | **Accepted.** The manifest asks for 5 wide to 8 tall and a corner radius of one-tenth of the width; the build follows the rule more closely than the picture. |
| W-07, finer card linework | **Accepted.** Small rendering difference; it is the same drawing as the Draw card backs, which the manifest requires to be identical everywhere. |
| W-08, footer block about 8.5 points higher | **Accepted.** The build leaves room for the home indicator, which the reference does not draw. The headline and promise sit higher by the same amount. |
| W-09, status bar and home indicator present | **Accepted.** The manifest forbids a fake status bar, so the picture has none. |
| W-10, line pitch of the small text differs by under 2 points | **Accepted.** Same wraps and widths; the manifest expects small text-rendering differences from the web renderings. |
| LT-01, two of the four largest-text captures were the same frame | **Accepted, and the duplicate removed.** The whole headline is visible at the top position, so there are three distinct positions: top, promise and bottom. The test now asserts that the headline is fully visible at the top instead of capturing it twice. |

## Correction found during verification

The first fix for W-01 set a shorter line height on the text itself. The unfiltered accessibility audit failed with "Text clipped", and the capture showed why: the shorter frame cut off the descenders of "Every morning.". The renderer approach above replaced it; the audit passes with every category enabled and the captures show whole letters at standard and largest text.

## Other evidence

- **Reduce Motion.** `01-welcome--reduce-motion` matches the standard capture pixel for pixel across the app's content; only the clock and the home indicator differ.
- **Largest text.** Nothing is clipped or overlapping, text and button stay inside the 24-point side padding, the button label wraps instead of shrinking, and the action and full disclaimer follow the content inline.
- **Contrast.** The audit raised one built-in contrast flag, on the promise paragraph. The existing measured-contrast check recorded 10.7:1 from that element's own image, above the 4.5:1 floor, and kept the image as `contrast-element-01-welcome-1`. No audit exception or filter was added.
- **Design system.** Bundled-font checks pass and the lexical design-role guard is unchanged and passes. The paragraph colour is the manifest's `#d8cce4`, now a named role.

## Full validation

After rebasing onto the card-face work (#37), `./scripts/harness check` passed on commit `e024f7a` in `.harness/runs/20261014T044013.838512Z-check-1586bdd1/`: **41 iOS tests (16 engine and font, 25 UI) and 34 command tests, plus the design-role guard**, with zero failures, skips or expected failures. Device: the checkout's dedicated iPhone 17e simulator on iOS 26.5, Xcode 27.0. `./scripts/harness evidence` was read, all six Welcome captures were inspected, and the comparison page was opened. Below the status bar the six captures are pixel-identical to those measured above (run `20261014T025642.263196Z-check-917a99e6`, before the rebase), so those measurements stand.

Two earlier runs passed every Welcome test but each failed one Draw test whose card tap was not registered: once just after a cold launch, and once, after the rebase, while the screen was still re-laying out after the Dynamic Type audit (the run's screen recording shows it). The UI tests now tap a Draw card only once it is hittable and its frame is unchanged between two reads, through one shared helper with a five-second limit, with no fixed pause or retry.

## Limits

- The headline's line-height adjustment needs iOS 18. iOS 17 keeps Gabarito's own line height, with everything else the same.
- The save-failure alert is system UI. It is captured and its text and behaviour are asserted, but it is not put through the accessibility audit, the same as the two existing native alerts. An audit of the presented alert with all seven categories (run `20261014T062832.698617Z-check-7836e8bb`, commit `759ea00`) passed six and flagged only the alert's own message text under Dynamic Type. iOS draws that text and the app supplies only its words, so no exception was added.
- Still images show the card at rest. The float (six points over three seconds) is covered by the Reduce Motion stillness assertion and the animation-on test, not by a recording.
- Only the 390 by 844 point phone at default and largest text is captured. Real-device behaviour and a manual VoiceOver pass remain release checks, as in the foundation slice.
