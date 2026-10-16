# Sharing (#23)

Scope: Reveal and the reading header share a locally rendered image through the native system share sheet. The image uses saved snapshots, so sharing cannot redraw cards, recompose text or alter notes. No networking, dependency, file persistence or service is added.

## Verification

The full local harness check and independent comparison are pending. A successful build alone is not verification.

`testActivitySheetSharesCardAndReadingImagesAndCancels` drives both Share actions, cancels each native sheet and checks that the same screen and content remain. It then chooses the native Copy action and retains the actual image passed through the sheet. On-device Vision text recognition checks the exported card name/orientation/disclaimer and the reading's question, card names, reversed label, all three complete passages, connecting passage, reflection and disclaimer. Overlapping image strips keep long-image text legible to the recognition engine. The reading payload must extend beyond twice the card-image height.

The existing engine composition tests verify all three orientation-specific passages, the selected area lens, reflection and snapshot round-trip. Sharing introduces no new tarot rules. Existing Reveal/Reading design tests audit settled screens with all categories enabled and retain normal, largest-text, bottom-of-scroll and Reveal Reduce Motion captures. Added largest-text captures explicitly show each Share control. Font-loading and lexical design-role checks remain unchanged.

The first full check, `20261016T160943.911256Z-check-674cd55e`, found a UI-test selector error: iOS exposes the native Copy action as a cell, not a button. The retained accessibility hierarchy confirms the sheet opened. The selector was corrected, and the run was deliberately interrupted after the standard Reading and Reveal audits had passed so the correction could be exercised. This interrupted run is not passing verification.

The second run, `20261016T164030.236628Z-check-c95b91f5`, reached the real Close action and found the underlying Share button remained occluded. UIKit had finished its activity while SwiftUI retained the presentation container. The completion handler now clears that presentation for cancellation and completed activities. The native-sheet capture also waits for stable Copy/Close controls instead of traversing the remote hierarchy by stale indices. This run was deliberately interrupted after the failure and is not passing verification.

The next run, `20261016T165441.665101Z-check-36ac5e47`, verified that both Close and Copy restored a hittable Reveal, then paused at the test runner’s cross-app paste-permission prompt. A retained diagnostic screenshot identifies the prompt. The test now reads the clipboard on a background queue and handles “Allow Paste” through the system UI before inspecting the image. This changes no app permission or simulator setting.

Run `20261016T171141.681984Z-check-47b921fd` handled paste permission and verified the actual card image, then found a test navigation mistake: the composer’s Back helper was used on Reading, whose control is Close. The test now scrolls directly to the Share control.

## Design comparison

Touched reference screens: `03-reveal` (including reopened Reveal) and `09-reading`. Shared images and the native share sheet have no reference; §11c of the manifest describes their layout and behaviour. Final screenshot comparison and independent findings will be recorded here before delivery.

## Limits

Sharing deliberately includes the original reading, not its optional personal note or feedback response. Images use standard document typesetting so their layout is portable; the app's controls still follow Dynamic Type. The app renders and hands off locally; any onward transmission is performed by the share destination the person chooses. Simulator verification does not establish real-device behaviour, third-party destination support or manual VoiceOver reading order.
