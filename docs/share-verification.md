# Sharing (#23)

Reveal and the reading header share a locally rendered PNG through the native system share sheet. Images use saved snapshots, so sharing cannot redraw cards, recompose text or alter notes. No network service, third-party dependency or file persistence is added.

## Verification

`./scripts/harness check` passed in `20261016T192137.663550Z-check-d58372c9` on source commit `20e7b9c`: **75/75 logical tests passed, zero failed/skipped/expected failures**, plus 34 command tests. This includes 34 engine/font tests and 41 UI tests; the parameterised cases account for the device-level count of 78. Xcode exited successfully, the harness exported 317 screenshots and released its simulator lock at 20:27:26 UTC on 16 October 2026.

`./scripts/harness evidence` was inspected, the run's `design-comparison.html` was opened, and the final normal, reopened, Reduce Motion, largest-text, lower-scroll, native-sheet and actual copied-image screenshots were visually inspected. The PNG payloads are 780 × 1147 pixels for the card and 780 × 2776 for the long reading. The full question, all passages, reflection and disclaimer are visible without truncation. Bundled typefaces and the design-role guard passed. The independent comparison and its follow-up are recorded below.

- `testActivitySheetSharesCardAndReadingImagesAndCancels` drives both Share actions, closes each native sheet, and checks that the same screen and content remain usable. It then chooses native Copy and retains the actual image payloads as `share-card-image` and `share-reading-image`.
- On-device Vision text recognition checks the card name, orientation and disclaimer, plus the reading's long question, all three card names, reversed label, every complete position passage, connecting passage, reflection and disclaimer. Overlapping recognition strips preserve legibility for a tall image. The reading payload must exceed twice the card-image height.
- The engine seam remains covered by `testCompositionUsesEveryPositionOrientationAndAreaLensDeterministically`, `testSnapshotRoundTripKeepsOriginalContent` and `testReadingAnnotationsRoundTripWithoutChangingOriginalContent`. Sharing adds no tarot rules and does not change the engine or store.
- Existing strict Reveal and Reading audits retain all manifest categories and their existing coverage/contrast measurement rules. Normal, reopened, bottom-of-scroll, largest-text and Reveal Reduce Motion screenshots are retained. Added largest-text captures explicitly show each Share control; bottom captures verify that primary actions remain reachable.
- Bundled-font checks and the lexical design-system guard are unchanged. All new type, colour and shape styling uses the existing design system. Source review of the share path finds rendering, in-memory PNG encoding and UIKit handoff only; it creates no URL, network client or metadata-fetch request.

The native sheet's completion handler clears SwiftUI's presentation item after either cancellation or completion. This fixes an observed empty presentation container that otherwise left the original screen occluded.

## Payload format finding

`20261016T190315.483771Z-check-8244bece` opened and cancelled the sheet, but native Copy returned no image readable through `UIPasteboard.image`. Trying UIKit's upfront-object initializer in `20261016T191812.555108Z-check-bfb3e405` produced the same result and identified the copied type as `public.heic`. The final implementation explicitly encodes PNG and registers only that data representation, with the same local preview/title. Both actual-image and cancellation checks then passed in `20261016T192137.663550Z-check-d58372c9`. The test keeps its original image assertion and reports copied types if it fails.

## OS-owned accessibility finding

An additional audit of the native share sheet initially found an unlabelled default preview (`20261016T173828.240205Z-check-7b51e2b6`). Supplying the local image and descriptive title fixed that preview. Both supported metadata approaches then exposed Apple's `LP.CaptionBar.TopCaption` title with a 207.7 × 18-point hit region: link metadata in `20261016T174359.301382Z-check-9f42d048` and UIKit's image-items configuration in `20261016T174835.563425Z-check-0b1c51b5`.

Firstmate clarified on 16 October 2026 that the ticket's strict audit covers app-owned screens, not the OS-owned share sheet. Only the added native-sheet audit call was removed. No app-screen audit category or issue handling was changed, and no OS finding was filtered. The sheet is still captured and tested for appearance, both cancellations and both image payloads. This platform finding must be listed in the PR.

The complete pre-final run `20261016T174835.563425Z-check-0b1c51b5` exported 75 logical tests: 74 passed, one failed (the native preview hit region), and zero skipped. All app-owned regression and design tests passed. Xcode exited naturally after its simulator shutdown callback completed.

## Design comparison

Touched reference screens are `03-reveal` (including reopened Reveal) and `09-reading`. The shared images and native share sheet have no reference; manifest §11c describes their layout and behaviour. The final run has main screenshots for both touched references and their required variants. Its four unmatched reference screens belong to other feature slices and are not screens changed here.

Author comparison of the original passing run:

| Screen/state | Visible difference and disposition |
|---|---|
| Both app screens | **Accepted:** real iOS status bar/safe areas, native font rasterisation, SF Symbol strokes and grain differ from the web artboards. Existing named palette/type roles and native layout remain in use; controls keep at least 44-point targets. The share symbol is larger/heavier than the web symbol, and Reveal's pill is wider, matching the established native header/button roles. |
| Reveal | **Accepted:** the established 214-point, 5:8 card is slightly shorter than the reference and begins about 25 points lower with the native safe area and Share header. The full face, name, metadata, action and disclaimer remain visible. The native footer sits above the system bottom safe area. The face's geometric linework follows the existing full-deck grammar. |
| Reopened Reveal and largest text | **Accepted:** reopened Reveal adds the existing Back chevron. At accessibility sizes selection text moves beneath Back/Share, text wraps and the footer moves inline; this follows manifest §11/§11c and keeps every action reachable. The Reduce Motion capture shows the same completed state. |
| Reading content | **Accepted:** the deterministic fixture uses the saved Star/Sun-reversed/Fool reading and original starter-library passages/reflection rather than the artboard's Two of Cups/Temperance/Sun example. Explicit Upright/Reversed labels improve orientation recognition. “Saved on this phone” accurately describes local storage. The ornamental area dot is absent; the area remains named in text. |
| Reading layout | **Accepted:** Done/disclaimer are pinned at standard size while the reference is a full-length canvas. At accessibility sizes cards and responses stack and Done moves inline. These are the shared layout's manifest rules; top, overlapping scroll and bottom captures retain the complete reading and reachable actions. |
| Shared images | **Accepted new state:** navigation, response controls and personal notes are omitted. The PNGs use the manifest's dawn ground, card faces, type and reflection panel at standard document scale, with natural height. This preserves the complete original reading in a portable image. |
| Native sheet | **Accepted new state:** system typography, colours, close control and thumbnail crop are OS-owned. Both local titles and image previews are visible; a cropped thumbnail does not crop the exported PNG. The native title hit-region finding is recorded above, per firstmate's scope clarification. |

## Independent comparison and follow-up

One fresh image-only review completed on 17 October 2026. Its verdict was **pass after CS1/RS1 evidence is supplied and inspected**, with no demonstrated blocking visual defect in the app screens or exports. [The retained review](share-design-review.md) contains every finding and the accepted-difference reasons to copy into the PR.

- **CS1 / RS1:** added a UI test that opens Settings, enables Larger Accessibility Sizes and moves the actual system text-size slider to maximum. It captures that setting, opens each native share sheet without the app-only size override, retains top/scroll screenshots and checks reachable Copy, Save to Files and Close controls. Teardown restores the prior switch and slider values. Full-run verification and image inspection are pending.
- **RD3:** restored the decorative area-accent dot before the saved-area metadata at standard text sizes, using the design system. Large-text metadata keeps its existing wrapping.
- **RD8:** standard-size response choices now use equal available widths and centred labels; their accessibility-size vertical stack is unchanged.
- **SR3:** the actual shared-image test now also retains `09-reading--shared-source`. Its existing functional assertions compare the full question and all original passages against the copied image, establishing source/export identity beyond the review's image-only evidence.
- **Render-failure alert (unverified item): accepted evidence limitation.** The existing Debug test configuration has storage-failure fixtures but no way to force `ImageRenderer` or PNG encoding to return nil. The alert remains described in manifest §11c; its appearance/retry path is not claimed as verified. No memory-pressure manipulation or new failure-injection mechanism was added for this optional evidence request.

All other rated differences were accepted for the reasons in the independent report. There is no second independent round; firstmate requested author inspection of the new captures and one complete harness check.

## Limits

Sharing includes the original reading, not its optional personal note or feedback response. Images use standard document typesetting; the app controls still follow Dynamic Type. The app renders and hands off locally; onward transmission belongs to the destination the person chooses. Simulator verification does not establish real-device behaviour, third-party destination support or manual VoiceOver reading order.
