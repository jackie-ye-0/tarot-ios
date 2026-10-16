# Reading in full verification

Issue #16 adds an optional response, editable note and confirmed deletion to the saved reading. Original text and cards remain immutable. Ask's recent-reading cache reflects successful annotation edits and deletion immediately, retaining the previous reading for an area when one remains.

## Verification status

The baseline full check `20261015T210426.074284Z-check-1a383fc6` on clean commit `250bc9f` passed 74/74 logical iOS tests, with no failures, skips or expected failures. The device count was 77 because one parameterised test ran four cases. All 34 command tests, the design-role guard and `testBundledTypefacesDoNotFallBack` passed. The exported comparison page and Reading/Ask captures were inspected. The result included three non-failing “Invalid frame dimension (negative or non-finite)” runtime warnings in note-related tests.

The independent-review corrections below have passed the lexical design guard and Swift syntax parsing. Their full simulator check and refreshed image inspection are **pending**; the baseline pass does not verify the corrections. No simulator run was started while the machine was reserved for another ticket's review.

## Acceptance coverage

- `testReadingResponseNoteAndConfirmedDeletionPersist` exercises selecting and clearing responses; multiline note save, edit, cancelled edit and clearing; reopening through Ask and disk relaunch; deletion cancellation and confirmation; immediate removal from Ask while retaining another area's reading; and removal of the last reading after relaunch.
- The same test checks exact original question, position passages, combined passage and reflection after a changed-library relaunch. `testTypedQuestionWhitespaceAndSavedReadingSurvivesRelaunch` also compares saved strings with revised content enabled.
- `testReadingChangesRecoverFromFailedSaveAndDelete` exercises rollback, retained note text and retry. It now captures both ordinary and largest-text failure states.
- `testReadingAnnotationsRoundTripWithoutChangingOriginalContent` covers every response, multiline notes, clearing and legacy snapshots without annotation fields, while retaining the original reading snapshot.
- More's actions and the native confirmation's buttons are captured and checked for existence/hittability. App-screen audits run after overlay dismissal. No shared audit helper or audit category was weakened.
- Reading sections, response, note editor and saved note retain the existing settled-screen audits. Largest-text reading, editor, keyboard, saved note, menu and confirmation captures cover the changed screens. Draw/Reveal/pick Reduce Motion captures remain in the full suite.

## Independent design review

A fresh image-only session reviewed the supplied manifest, two references, all 34 Reading images, all 20 Ask images, 76 Reading contrast crops and six Reduce Motion regression images on 16 October 2026: 138 source images. It did not inspect source, tests or logs and did not delegate. Its verdict was **“pass after the listed must-fix items”**, N1, N2 and A1. One independent round satisfies the assigned review requirement; the corrections still need the authorised full check and new-capture inspection.

| Finding | Disposition and verification to perform |
| --- | --- |
| N1: keyboard Done overlaps Save note or the field | Implemented: retain the multiline TextEditor, reuse the composer's focus scrolling and shared safe-area layout, and place the secondary Done capsule in reserved bottom space instead of a floating keyboard toolbar. Save note remains pinned ordinarily and inline at accessibility sizes. Note-scoped UI checks require the field and Save note to sit at least eight points above Done, capturing the field and the scrolled action at largest text. Inspect the refreshed keyboard captures before marking verified. |
| N2: empty field lacks a placeholder | Implemented “Write a note” with the existing placeholder/body roles; it disappears when text is nonempty and does not consume taps. There is no note character limit or newline filtering. Inspect empty and populated captures at both sizes. |
| A1: post-deletion Ask bottom not captured | Added ordinary and largest-text top/bottom captures after actually deleting the last reading. Bottom captures expose Skip and assert that no recent-reading row exists. Inspect these new captures before marking verified. |
| D4: optional action-specific deletion-failure heading | Accepted unchanged at firstmate's direction. “Your change could not be saved” remains understandable in the deletion context, and the message explicitly says the saved reading is unchanged and explains recovery. The manifest prescribes no particular heading. |
| F2: optional action-specific note-save-failure heading | Accepted unchanged at firstmate's direction. The same heading is shown over the retained note draft with clear reassurance/retry guidance. The manifest prescribes no particular heading; this is a copy refinement rather than a required behaviour change. |

The largest-text deletion-cancelled state and both largest-text operation-failure alerts were also added to close the review's stated evidence gaps. The keyboard keeps Return for note line breaks; the composer's one-paragraph question rule is not applied to notes.

## Accepted visual differences

The following are the independent review's accepted differences, retained unchanged. Manifest sections refer to the design rules supplied with the reviewed images.

| IDs | Difference and reason |
| --- | --- |
| R1 | Native status bar and finite scrolling viewport replace the long web artboard. Safe areas and scrolling are required by §§4 and 11. |
| R2 | Close/More are heavier native icons with 44-point targets. Share is absent because §11a assigns it to #23. |
| R3 | The decorative area dot is omitted; text and coloured headings identify the area. “Saved on this phone” replaces “Saved to History” until #19, as §11a specifies. |
| R4 | Different saved starter cards and the newer full-deck artwork grammar replace illustrative reference cards. Reversed art and explicit orientation labels follow §§5 and 11a. |
| R5 | Separate name and orientation lines, including explicit Upright, make the card label block taller. This preserves scalable, unambiguous card identity and state. |
| R6 | Saved passages, combined interpretation and reflection differ in length and wording. Their order and non-predictive meaning remain; §11a does not fix example results. |
| R7 | Darker area headings and more visible native grain follow §2's contrast partners and texture roles. The image review is not numerical contrast certification; audits provide that separate evidence. |
| R8 | Native glyph shapes, weights and wrapping differ slightly from the web reference while preserving display/body hierarchy, permitted by §12. Bundled-font identity is separately tested. |
| R9 | Response chips fit their labels rather than filling three equal-width columns. §5 requires the shape, spacing and selected ink/light treatment, not equal widths. |
| R10 | Done/disclaimer remain pinned while ordinary-size content scrolls and move inline at accessibility sizes. The shared layout explicitly requires this, with one primary action and no exposed Delete. |
| R11 | The reflection panel's size changes with actual wording and native text metrics. Its dark surface, large question and quiet helper retain the reference hierarchy. |
| M1 | More uses native material, fonts, icons and destructive red. §11a explicitly specifies a native menu. |
| M2 | The temporary menu obscures part of the reading, with readable actions; dismissal restores the complete header and Done. Delete remains confined to More. |
| N3 | The spacious surface editor and blank ground above its pinned action follow the no-reference dawn/title/quiet Cancel/Save note definition. |
| N4 | Largest text enlarges content and places Save note inline below the field. It remains reachable by scrolling and after keyboard dismissal; N1 separately corrects overlap while editing. |
| N5 | Notes preserve multiple lines and retain Return plus a separate Done control. §11a's one-paragraph rule applies to questions, not notes. |
| S1 | The saved note adds a heading and body text after feedback without an extra panel, explicitly required by §11a. |
| S2 | Somewhat is ink-filled; other choices remain light. Largest text stacks all choices and keeps Done reachable. |
| S3 | Different ordinary/largest-text note fixtures are intentional. Note and response/action content fit; complete disclaimer text is demonstrated by the overlapping Reading bottom captures. |
| D1 | The native confirmation's system material, red action, dimming and “This cannot be undone” warning are appropriate to the specified native confirmation. Both buttons and message fit. |
| D2 | Cancellation evidence uses a different Career/revised-content fixture, matching the reading behind that confirmation. It is not a comparison with the separate Relationship fixture. |
| D3 | Failure reassurance and an OK dismissal allow retry from the retained reading, consistent with §11a; an immediate Retry button is not required. |
| F1 | Native failure material overlays a retained populated note and gives reassurance/recovery. Platform styling is expected. |
| A2 | Native status area, spacing and finite viewport differ from the long reference while keeping aligned, ordered and readable controls. |
| A3 | The actual saved card name and shorter daily area line replace the illustrative headline/paragraph; §11b requires this. The darker score label follows §2. |
| A4 | Actual question-form suggestions replace topic fragments, changing chip widths as required by the question-writing rules. |
| A5 | Named-person entry is absent because §11a assigns it to #18. |
| A6 | Four full-width relationship choices and Skip replace wrapping pills, as §11b explicitly requires. Answered/skipped states omit the prompt. |
| A7 | No-reading states omit the recent row and empty placeholder. Existing rows show real card faces/question/date, stacking at largest text. A1 supplies the deletion-specific bottom evidence. |
| A8 | Today/Ask tabs remain until #19 adds History. The selected ink pill is the mandated contrast treatment; tab icons are still placeholders. |
| A9 | Native font rendering, grain and darker score text differ as in R7–R8; existing palette and hierarchy remain, with no added primary action. |

Real-device interaction and manual VoiceOver order are outside this simulator/image evidence. The independent review does not establish persistence, audit outcomes, exact font loading or motion timing; those are separately covered by the automated suite and retained run evidence.
