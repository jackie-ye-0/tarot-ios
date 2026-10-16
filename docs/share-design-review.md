# Independent sharing design comparison (#23)

A fresh reviewer completed one image-only comparison on 17 October 2026 using the original `final-evidence` package from commit `5bfba51`. It did not inspect the implementation or automated test results. Its verdict was: **pass after must-fix evidence items CS1 and RS1 are supplied and inspected**. It found no demonstrated blocking visual defect in Reveal, Reading or the two exports.

The findings and accepted-difference reasons below are retained from that review. `E` denotes its supplied evidence package; `M` denotes the manifest copy in that package, so cited line numbers belong to the reviewed copy. The follow-up dispositions are recorded in [sharing verification](share-verification.md). The PR must retain these accepted-difference reasons as well as the follow-up result.

## Reveal: 03-reveal

Compared `E/design-reference/03-reveal.jpg` with `03-reveal.png` and all 11 variants. The selection header, trailing Share pill, upright face, name, orientation/arcana, keywords, meaning action and disclaimer are present in the correct order. There is no tab bar or competing primary action.

| ID | Visible difference | Rating and reason / action |
|---|---|---|
| RV1 | The built screen has native status information and safe-area space absent from the reference artboard. The header is lower, the card begins roughly 25 points lower, and the name/details sit correspondingly lower. | **Acceptable.** The app is a real 390 × 844 viewport rather than a web artboard. M:106 requires real, reflowing screens and forbids a fake status bar. All content remains visible at standard size. Approximate positions are visual comparisons, not layout measurements. |
| RV2 | The meaning button is a little wider and sits higher than in the reference; there is more space below the disclaimer and less open ground between the keywords and button. | **Acceptable.** The built footer follows the 20-point dawn side guide and native bottom safe area (M:188), while retaining the full-width pill, bottom placement and one-primary-action hierarchy (M:110). |
| RV3 | The Share pill is wider, its icon and label more prominent, and the primary-action arrow is larger/heavier than the reference's thin glyph. | **Acceptable.** The label remains secondary to the card/name and primary action. It follows the surface-pill requirement (M:220) and button type role (M:87); recognisable native glyph rendering need not duplicate the web glyph. Keep the existing quiet surface treatment. |
| RV4 | The built card is a little shorter relative to its width; corner curvature and outline joins differ slightly. The star's points are sharper and slightly differently proportioned, and the small dots, hills and flowing lines are repositioned slightly. | **Acceptable.** The approximately 5:8 rounded frame, ink outline, inset sky, four-point ochre/light star and sage/clay flowing landscape retain the required face grammar (M:100, M:125). No identity-bearing feature is missing. |
| RV5 | The background looks slightly greyer/less rosy, with a different fine grain pattern. The soft warm halo around the card differs from the reference's darker lower shadow. | **Acceptable visually.** These remain dawn ground and subtle grain, and the warm glow is explicitly required by M:149. This is not a claim of measured colour-token or contrast compliance. |
| RV6 | Glyph edges, spacing and line metrics differ slightly, especially in the display name and button text. | **Acceptable.** The rounded display/body distinction and weight hierarchy match. Small web/native text-rendering differences are expressly allowed by M:233. The upright wording itself matches the reference. |
| RV7 | Reopened Reveal adds a leading back chevron, shifting the selection text right. | **Acceptable.** Required by M:186. In `03-reveal--reopened.png` the back, complete selection sentence and Share pill fit without overlap. The card and footer remain aligned with first-draw Reveal. |
| RV8 | The reversed variant rotates the face, changes “Upright” to “Reversed”, and uses “Patience, quiet, care, perspective” instead of the upright keywords. | **Acceptable.** Orientation is communicated by both art and text (M:117, M:163). The same layout remains intact in `03-reveal--reversed.png`. |
| RV9 | At largest text, Share has its own controls row, selection wraps below it, and the details/button/disclaimer occupy later scroll stops. The primary button becomes a tall rounded rectangle with a multiline label. | **Acceptable.** This is required reflow, not a reference mismatch to undo: M:220, M:182 and M:196. Full coverage is recorded below. |

## Reading: 09-reading

Compared `E/design-reference/09-reading.jpg` with the main capture, lower scroll stops and all other Reading variants. The reference is a full-height 390 × 1470 document; the built images are 390 × 844 screen viewports. They must be compared across scroll stops, not by shrinking the full reference into one screen.

| ID | Visible difference | Rating and reason / action |
|---|---|---|
| RD1 | Native status information adds top space. Close, Share and More are larger/heavier and more widely separated than their reference glyphs. The question begins lower. | **Acceptable.** Native safe-area presentation and clear 44-point header controls are consistent with M:103, M:106 and M:220. Share is correctly immediately before More, with Close on the left. Visible glyph size alone does not prove hit-target size. |
| RD2 | “Saved to History” becomes “Saved on this phone”. | **Acceptable; explicitly deferred feature relied upon.** M:202 reserves History wording for issue #19. Do not restore the reference wording before History exists. |
| RD3 | The small clay dot before “Relationship” is absent in `09-reading.png`. The area text begins directly at the side guide. | **Should fix.** Restore the reference's decorative Relationship-accent dot before the area label at standard size, keeping the area as readable text. The dot is not required to understand the screen, so this is reference fidelity rather than a manifest-blocking defect. Use the existing accent role, not a new colour. |
| RD4 | Reference cards Two of Cups / Temperance reversed / The Sun become The Star / The Sun reversed / The Fool, with different artwork. All three now have explicit orientation lines; the card captions and gaps are taller. | **Acceptable.** M:202 expressly says reference cards are not fixed results, and M:125 defines the newer full-deck art grammar. The reversed Sun is visibly upside down and labelled Reversed. Position/name/orientation remain unambiguous. |
| RD5 | All three passages, the combined reading and reflection question differ from the reference. The combined reading is longer, and the built reflection question occupies fewer lines at standard size. | **Acceptable.** The content is allowed to vary (M:202). The required sequence survives: situation, action, outcome, Read together, reflection, optional response, Done. Wording is reflective and tentative rather than a promise, consistent with M:156. The reflection helper and disclaimer remain present. |
| RD6 | Body/heading line metrics and wrapping differ slightly; section headings look darker than the reference clay. The background grain is different and slightly less rosy. | **Acceptable.** Native type rendering is allowed (M:233). Darker area-text partners on textured screens are intentional (M:66, M:76). The display/body hierarchy and paragraph spacing remain legible. Exact fonts, colours and contrast were not certified from appearance. |
| RD7 | Done and its disclaimer remain pinned while the standard-size reading scrolls; the reference presents them after the entire document. Intermediate captures cut content at the viewport boundary above the footer. | **Acceptable.** Required shared footer behaviour (M:182). `--action`, `--outcome`, `--bottom` and `--response` collectively expose the content. The cut reflection-panel edge in `--action` is fully rounded and visible in `--bottom`; this is scrolling, not a broken panel shape. |
| RD8 | The reference gives Yes, Somewhat and Not really equal-width chips across the content width. The built standard-size chips hug their labels, leaving a substantial empty area at the right (`09-reading--bottom.png`, `--response.png`). | **Should fix.** Give the three standard-size choices equal width across the existing row, retaining 44-point minimum height and the existing gaps. Keep the accessible vertical stack. The current choices are readable and usable-looking, so this is not a blocking accessibility defect. |
| RD9 | The reflection panel is shorter because its question is shorter; the gap from response chips to Done is more generous in the viewport than in the reference document. | **Acceptable.** Natural content height and the pinned footer account for these differences. The panel keeps its ink fill, surface-coloured text and rounded corners; it is explicitly part of the reading design (M:202), not an accidental extra content box. |
| RD10 | Selected-response captures fill Somewhat with ink. Saved-note captures add a Your note section after the response. More/menu and deletion/editor variants introduce native controls absent from the static reference. | **Acceptable.** These are specified by M:204 and M:206. The note is plain body content, Delete is confined to More/confirmation, and Done remains the reading's sole primary action. Supplemental-state observations are below. |
| RD11 | Largest-text cards and response chips stack vertically; the question, metadata, passages and reflection expand into many screenfuls. Done/disclaimer become inline. | **Acceptable.** M:182 and M:204 require this adaptation. The capture sequence covers the complete original reading and a reachable Done without horizontal clipping or overlapping text. |

## Native card share sheet

No reference image exists. Checked `03-reveal--share-sheet.png` against M:220 and M:222.

| ID | Finding | Rating and action / reason |
|---|---|---|
| CS1 | **No open card share sheet at largest text is supplied.** `03-reveal--largest-text-share.png` shows Reveal with the Share control, not the sheet. The only sheet capture uses ordinary-sized system text. | **Must fix the evidence.** Set the system text size to its largest accessibility setting, open Share from Reveal, and capture the settled sheet with its title/preview, dismiss control and accessible sharing choices. Add further scroll stops if necessary. M:235 requires largest-text evidence for touched screens; M:222 explicitly requires system text scaling. An enlarged SwiftUI screen alone does not demonstrate native-sheet scaling. Re-review the new images before claiming this check passes. |
| CS2 | The sheet uses native light material, system typography, app icons, separators and a circular Close control rather than dawn styling. It shows a rendered-card thumbnail and “The Star, upright”. | **Acceptable.** System styling is explicitly required by M:222. The preview is descriptive, and visible controls have no clipping or overlap at the captured size. The native square thumbnail crops the taller document; the full export is complete. |

## Native reading share sheet

No reference image exists. Checked `09-reading--share-sheet.png` against M:220 and M:222.

| ID | Finding | Rating and action / reason |
|---|---|---|
| RS1 | **No open reading share sheet at largest text is supplied.** `09-reading--largest-text-share.png` shows the enlarged Reading screen, not the native sheet. | **Must fix the evidence.** Repeat the system-largest-text capture procedure in CS1 from Reading. Include a fully readable “Relationship reading” title, dismissal control and usable sharing choices. Both sheets are new named states in the handoff, so a Reveal control capture cannot stand in for this sheet. |
| RS2 | Native styling matches the card sheet. The square preview shows the centre of the long reading image rather than its question/cards, with “Relationship reading” beside it. | **Acceptable.** M:222 requires the rendered image and descriptive area title, not a custom thumbnail crop. The title identifies the document and the captured controls are clear. A new custom preview design is not necessary for this ticket. |

## Shared card image

Checked `share-card-image.png` against M:222. PNG dimensions are 780 × 1147, consistent with a 390-point-wide document at double resolution and natural height.

| ID | Finding | Rating and reason |
|---|---|---|
| SC1 | The centred face precedes The Star, Upright and the complete “For entertainment and reflection” disclaimer. It omits the app header, arcana number, keywords, buttons and status information. | **Acceptable.** This is precisely the portable-card content defined by M:222; omitted screen controls/content are not missing export requirements. The face is approximately 428 pixels wide, matching the specified 214 points at 2×. |
| SC2 | There is textured dawn ground, generous vertical spacing, a soft card shadow/glow, display-weight name and smaller orientation/caption text. Top/bottom breathing room is consistent with the prescribed margins. | **Acceptable.** No clipped text, stray controls, cut card edge or unintended empty screen-height area is visible. The export is complete at standard text scale as specified. |

## Shared reading image

Checked `share-reading-image.png` against M:222. PNG dimensions are 780 × 2776, consistent with a 390-point-wide document at double resolution and natural height.

| ID | Finding | Rating and reason |
|---|---|---|
| SR1 | A long multi-line question is followed by Relationship, three labelled faces with orientations, all three passages, Read together, the reflection panel/helper and the full entertainment/reflection/not-a-prediction disclaimer. | **Acceptable.** Correct order and complete visible content. Text wraps within the side margins; the final disclaimer and bottom padding are present. No scrolling boundary cuts off the document. |
| SR2 | Saved-on-phone metadata, header controls, Done, the response chips and personal note are absent. | **Acceptable.** M:222 requires no navigation controls and explicitly leaves personal note/response on the phone. Their absence is correct. This visual check does not prove every export path excludes private data. |
| SR3 | The export question is the longer “How can I make room for a thoughtful conversation…” example, whereas the on-screen Reading captures say “Where is this going?”. | **Acceptable as layout evidence, with a verification limitation.** The long example usefully demonstrates wrapping and natural height. The supplied images do not establish that this export came from the same original reading as the screen/share-sheet capture. Do not call this a data-mutation defect based on different image fixtures; use a matched source/export pair or functional evidence to establish identity. |
| SR4 | The export retains the built reading's different card art, passages and reflection, and the slightly different native type/grain treatment. | **Acceptable** for the same reasons as RD4–RD6. There is no separate export reference to match. |

