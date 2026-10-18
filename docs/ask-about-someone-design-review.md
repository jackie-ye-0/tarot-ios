# Issue #18 independent design review

> Historical independent comparison of the screenshots from run `20261017T205214.525756Z-check-1c7ea2ed`, app revision `2d142eb`. This preserves the review's verdict, findings, accepted differences and evidence limits. The complete original inventory (7 references, 142 built images) is retained in the task evidence. Current dispositions and later validation are in [verification](ask-about-someone-verification.md#independent-review-and-corrections).

**Verdict: pass after the listed must-fix item, C-M1.** The empty ordinary composer needs a capture with its last suggestion fully clear of the pinned footer, with a layout fix if necessary. One wording improvement, P-S1, should also be made. The named-person form, reading, largest-text coverage and settled Reduce Motion states otherwise meet the supplied visual rules. This is an image-based design verdict, not functional or accessibility-test certification.

Reviewed 18 October 2026 by an independent, fresh agent session. No implementation changes were made.

## Scope and evidence

The handoff's six touched groups determined scope: Ask; About someone; initial and completed three-card pick; Reading; empty and entered ordinary composer; and the reading note editor. I compared all seven applicable reference images with the built states, opening every image in the inventory below. Ordinary variants and additional retained states received regression checks; unrelated reference screens were excluded. Four Draw/Reveal Reduce Motion images received a settled-state sanity check only.

Source root, referred to as **E** below:

`/Users/JackieYe/Documents/AI coding/firstmate2/data/tarot-18-ask-about-someone/final-evidence/`

- **M** means `E/design.md`; line references identify the supplied manifest, not repository source.
- **R/** means `E/design-reference/`.
- **S/** means `E/screenshots/`.
- The handoff was used solely for its touched-state list. Its build/run claims did not influence this verdict.

Inspected **7 references and 142 built screenshots**, including the four Draw/Reveal sanity checks. Images were displayed side by side at the same 390 × 844 layout scale, preserving their aspect ratio. I reopened original images where a boundary needed closer inspection. The original empty-composer bottom capture confirms C-M1; the original named-person largest-text reading bottom confirms that Done and its disclaimer are present and readable.

Severity: **must fix** means a supplied rule/evidence requirement is not satisfied; **should fix** means an actionable visual or wording improvement that does not block this comparison; **acceptable** records a visible difference and its reason. Viewport-edge cropping during a scroll is acceptable when another capture shows the same content completely. I have not treated a partial first viewport as a defect by itself.

## Ask: `05-ask`

Reference: `R/05-ask.jpg`. Main evidence: `S/05-ask.png`, `S/05-ask--named-person-entry.png`, `S/05-ask--bottom.png`, `S/05-ask--recent-reading.png`.

| ID | Rating | Visible difference and disposition |
|---|---|---|
| A-A1 | Acceptable | The native status bar adds a top band; the heading begins lower and the screen is much taller in content than the densely packed reference. Text has natural proportions, larger supporting copy and more line spacing. Native type roles, scrolling and the real status bar take precedence over fitting the entire reference into one viewport (M:80–106, 257). |
| A-A2 | Acceptable | “The Star” and “Let a kind word make room for connection.” replace “Open-handed” and the longer reference interpretation. The tint panel is taller, and its score label is darker. M:212 expressly requires the saved daily card and area line; M:66 and 76 require the darker area-text partner. |
| A-A3 | Acceptable | The selector, outlined entry and arrow, and suggestion pills are taller/larger, with wider vertical gaps. The three suggestions remain in order and use sentence-case questions. “Where is this going?” gains its question mark; “What am I not saying?” replaces the reference's “A conversation I'm avoiding”. The latter is not phrased as a question; the built copy follows M:159. Control sizes follow M:103, 113–115. |
| A-A4 | Acceptable | The named-person entry has a taller surface panel and its helper wraps onto two lines. Its title, helper and trailing chevron match M:242 exactly. It is below the first viewport, but entirely visible in the entry and bottom captures. Its position before the relationship-status prompt is correct. |
| A-A5 | Acceptable | Relationship choices form four full-width rows instead of the reference's two compact rows. An explicit “Skip” is added. The helper and spacing are larger. These are required by M:212 and the 48-point chip floor at M:114. |
| A-A6 | Acceptable | A recent-reading row is absent in the no-reading fixture, and present in the dedicated recent-reading capture with different question/date and three illustrated card faces rather than flat colour marks. M:212 requires omission when no reading exists and real saved faces when one does. |
| A-A7 | Acceptable | Two widely spaced tabs replace three; History is omitted. The selected Ask icon has a dark pill instead of the reference tint, and icon shapes differ. This relies explicitly on deferred History at M:194, the contrast change at M:112, and placeholder tab icons at M:250. |
| A-A8 | Acceptable | Ground and grain look slightly cooler/more mottled than the reference, while surfaces, clay tint, ink and dividers retain their intended hierarchy. No unapproved colour role is apparent. Native textured rendering and small glyph-weight differences are permitted by M:70–76 and 257; exact colour/contrast is not certified by this inspection. |

No must-fix Ask finding. The hidden-area, skipped-status and deleted-reading captures show no obvious regression; their conditional omissions agree with M:204, 212 and 234.

## About someone: `07-about-someone`

Reference: `R/07-about-someone.jpg`. Evidence includes every `S/07-about-someone*.png` file.

| ID | Rating | Visible difference and disposition |
|---|---|---|
| B-A1 | Acceptable | A native status bar is added; the back chevron is larger/heavier, and the heading and form start slightly lower. Side alignment and content order remain correct. This is compatible with real native chrome and the back target at M:103, 106 and 136. |
| B-A2 | Acceptable | The name field has a dark ink outline instead of the pale reference outline and is taller, approximately the specified 60-point pill. The optional context field likewise has an ink border and more height. These changes follow the explicit field requirements at M:115 and 242. |
| B-A3 | Acceptable | Relation chips are slightly taller, with more vertical space; they remain two rows of three at ordinary size. The empty state has no selection. Filled evidence makes Friend dark with light text. M:114 and 242 specify these states. |
| B-A4 | Acceptable | “Anything specific? (optional)” is one left-aligned label rather than a left title plus right-aligned “Optional”. The meaning is unchanged and the large-text version wraps without losing the optional qualifier. The example remains a placeholder; filled captures replace it with entered text. |
| B-A5 | Acceptable | The footer preview uses “The Connection” capitalisation, slightly larger text and a higher bottom position than the reference. The disabled and enabled labels are “Add a name and who they are” and “Draw for you and Sam”. These match M:244; the higher footer accommodates the native bottom safe area. |
| B-A6 | Acceptable | Typography is slightly less heavy in labels/placeholders, the field example's line breaks differ, and ground/grain have the same small native-rendering differences as Ask. The screen retains the supplied title, explanation, names of all six relations, field hierarchy and rounded surfaces (M:80–115, 242, 257). |

No must-fix form finding. The standard “bottom” capture shows the same whole form as the main capture; that is sufficient here because the complete form and action fit.

## Three-card pick: `08-three-card-pick`

Reference: `R/08-three-card-pick.jpg`. Named-person standard evidence is `S/08-three-card-pick--named-person-reduce-motion.png`; the ordinary main capture and all retained pick variants were also inspected.

| ID | Rating | Visible difference and disposition |
|---|---|---|
| P-S1 | **Should fix** | The instruction reads **“Choose your You card”** in the named-person Reduce Motion capture. The slot is clear, but the sentence is awkward. Use a natural instruction that preserves the position, for example **“Choose a card for you”**; use equivalent wording for Them and The Connection. Check all three instructions and their largest-text wraps. M:155 asks for plain instructional titles. No interaction change is needed. |
| P-A1 | Acceptable | “You and Sam”, “Your relationship reading”, and You / Them / The Connection replace the ordinary question/subtitle and Situation / Action / Outcome. M:246 explicitly introduces these names and positions. The opening and closing quotation marks remain consistent with the existing layout. |
| P-A2 | Acceptable | The native status bar and heavier back glyph are added. The progress remains centred separately from Back. Divider, slots and instruction sit a little lower; slots are slightly larger and their numbers more prominent. These preserve the order and 5:8 shape while respecting M:100–106 and 198. |
| P-A3 | Acceptable | The slots have explicit dark interiors instead of showing the underlying disc. Active slot 1 has the gold dashed outline; inactive slots have muted outlines. M:118 expressly requires the fill and active-slot distinction. |
| P-A4 | Acceptable | The five-card fan sits lower, has modestly different overlaps/angles and simplified ray/line placement. It retains identical rounded backs, gold inner/outer frames and half-sun motif. M:116 and 198 define the compact native fan; no separate reference geometry is mandated for each back offset. |
| P-A5 | Acceptable | The disc has a slightly different visible extent. Shuffle and its helper sit higher above the bottom edge; the helper is smaller than in the reference. The single disc, quiet underlined Shuffle and exact helper remain present, without a filled primary button before completion (M:91, 111, 198). |
| P-A6 | Acceptable | Night grain and text rendering differ slightly from the web rendering. Cream, lavender, gold and indigo retain their assigned roles. The settled state has no duplicated/floating intermediate cards. |

Ordinary one-picked, two-picked and shuffle-settled captures show the correct next position, filled card names/orientations and remaining slots. The draft-save alert is legible and preserves the visible spread behind it. These are regression observations, not a test of persistence or retry.

## Completed pick: `08-three-card-pick-complete`

Reference: `R/08-three-card-pick-complete.jpg`. Named-person evidence: the `--named-person-reduce-motion` and all `--named-person-largest-text*` variants.

| ID | Rating | Visible difference and disposition |
|---|---|---|
| PC-A1 | Acceptable | The title/subtitle and position labels use the named-person wording. The Star, Sun and Fool replace the reference's Two of Cups, Temperance and Sun. Their orientations also differ. Example results are not fixed by the reference (M:202); named positions follow M:246. |
| PC-A2 | Acceptable | Card faces are slightly larger, with the full-deck geometric sky/landscape/emblems, clearer borders and separate orientation labels for upright as well as reversed cards. Reversed artwork is visibly rotated. This follows M:117, 125–127 and 198. The Star includes its gold four-point star, smaller light centre and flowing landscape; the other shown emblems are identifiable. |
| PC-A3 | Acceptable | Names/orientations/positions take more vertical space and sit lower than the reference. “Your spread is laid”, its helper and Read my spread sit modestly higher. The single disc, open middle space and one cream bottom action remain; the fan and Shuffle are correctly absent after completion (M:198). |
| PC-A4 | Acceptable | Native chrome, heavier back glyph, grain and minor type weight/line-break differences are the same native adaptations already described. Ordinary and largest-text named-person fixtures show different Sun/Fool orientations; their labels agree with their artwork within each fixture. Images do not establish any result-changing behaviour. |

No must-fix completed-pick finding.

## Reading: `09-reading`

Reference: `R/09-reading.jpg`. Evidence includes named-person opening, You, Them, Connection, lens/Read together, bottom, largest-text scrolls 0–9 and bottom, plus ordinary reading and feedback captures.

| ID | Rating | Visible difference and disposition |
|---|---|---|
| R-A1 | Acceptable | The native reading is substantially longer than the packed reference: larger naturally proportioned type, body leading and spacing, true tall cards, and larger controls require scrolling. M:80–106 and 182 require readable scaling/scrolling; compressing the reading to one viewport would conflict with them. |
| R-A2 | Acceptable | “You and Sam”, You / Them / The Connection and the dedicated position passages replace the ordinary question and reference passages. Read together explicitly mentions Sam and stays reflective rather than claiming knowledge of their feelings. The reflection question also differs. This is required/permitted by M:156, 202 and 246. |
| R-A3 | Acceptable | Metadata says “Saved on this phone” instead of “Saved to History”. The relationship dot is retained at standard size and omitted in the large-text layout. This relies on M:202 and 218; History remains a later slice. |
| R-A4 | Acceptable | Cards and artwork differ as described in PC-A1/2. Names and orientations occupy separate readable lines; headings use a darker clay than the reference. Correct reversal is conveyed by both image and words. M:66, 76, 117 and 127 support these differences. |
| R-A5 | Acceptable | Close, Share and More symbols are larger and more widely spaced, with a distinct header row before the title. The native status bar is added. Their ordering matches M:204 and 222; no tabs or visible destructive action intrude. |
| R-A6 | Acceptable | The dark reflection panel is taller with more readable title/helper text. Feedback choices are taller equal-width pills at standard size, and stack at large size. Selected Somewhat is dark with light text. M:204 and 218 expressly specify these states. |
| R-A7 | Acceptable | Done is a full-height pinned action with a larger disclaimer at standard size, so it appears while earlier passages are being read. The content and action become one scroll sequence at large size. This follows M:110, 182 and 202, rather than the reference's unusually compressed footer. |
| R-A8 | Acceptable | Ground/grain and glyph weight differ slightly. No extra boxed reading sections were introduced beyond the specified reflection panel; the open text hierarchy remains clear (M:19, 202). |

No must-fix reading finding. All named-person standard passages are readable across the supplied stops. The full large-text connecting passage and disclaimer are covered across overlapping captures; the bottom capture shows a complete Done action.

## Ordinary composer, empty: `06-composer`

Reference: `R/06-composer.jpg`. All 21 empty/entered composer captures were inspected because the shared suggestion chips changed; the entered state is also assessed separately below.

| ID | Rating | Visible difference and disposition |
|---|---|---|
| C-M1 | **Must fix: comparison/evidence** | In **`S/06-composer.png` and `S/06-composer--bottom.png`**, the third suggestion, **“What do I actually want?”**, has its lower rounded edge cut into a straight horizontal edge by the scroll/footer boundary. The two captures show essentially the same position; neither shows the whole chip clear of that boundary. The reference shows a complete pill with clear space before the preview. The text itself remains readable, so this is not a claim of truncated wording. Supply a standard empty-state stop with the entire chip visible above the footer. If it cannot be reached, adjust the content's bottom clearance/scroll extent, preserving the 48-point chip and the footer's clear gap. Relevant rules: rounded chips M:101 and 114; unoccluded viewport/fully visible evidence M:258; clear footer spacing M:188. The filled composer's bottom capture already shows the complete chip, illustrating the intended result. Do not treat a filename ending in `--bottom` as proof that coverage is complete. |
| C-A1 | Acceptable | Native status bar/back glyph and slightly different selector padding are added. The title is a little lower/lighter and breaks after “ask” rather than after “to”. Guidance, field, counter and suggestions consequently begin lower. This is native type/layout variation within M:80–106 and 257. |
| C-A2 | Acceptable, apart from C-M1 | Suggestions are taller and spaced farther apart than the reference. Placeholder/entered text is a little lighter and line breaks differ. The 48-point shared chip floor is deliberate (M:114); it must be accommodated by scrolling rather than reduced. |
| C-A3 | Acceptable | The three dashed preview cards and explanatory text use slightly different widths, offsets and wraps. The pinned button sits higher for the native safe area; the enabled arrow is larger. One disabled/enabled action, correct labels and a trailing count are retained (M:110, 196, 214). |
| C-A5 | Acceptable | The hidden-area fixture has only Career and corresponding prompts. It remains readable across top/bottom stops. This is the explicit visibility rule at M:234, not a missing-segment defect. Ground/grain differences are consistent with the other dawn screens. |

C-M1 is a narrow layout/evidence correction worth shipping if a recapture cannot expose the full chip. The images alone cannot identify its implementation cause or prove the chip cannot be scrolled farther.

## Ordinary composer, question entered: `06-composer-question-entered`

Reference: `R/06-composer-question-entered.jpg`. Main evidence: the matching main/bottom captures, all largest-text stops, keyboard/dismissed states and limit capture.

| ID | Rating | Visible difference and disposition |
|---|---|---|
| CE-A1 | Acceptable | Native header, title wrapping, taller suggestions and spacing differ in the same ways as C-A1/2. The field correctly contains “Where is this going?” with `20 / 300`. The final chip is partial in the main viewport but fully visible in `--bottom`; this supplies the coverage missing from the empty state. |
| CE-A2 | Acceptable | The dark enabled button and larger arrow replace the disabled state, at the same safe-area-adjusted footer position described in C-A3. “Draw my three cards” matches the reference, with the three-card preview/helper above it (M:110, 196, 214). |
| CE-A3 | Acceptable | Keyboard states place the active question at the top, expose native Done, and move the standard footer above the keyboard. Largest-text action/preview are inline and readable after dismissal. Limit evidence adds “Limit reached · 300 / 300” in the error role. These are manifest-defined states without separate references (M:196, 214). |

No must-fix entered-composer finding; its bottom capture demonstrates the full suggestion chip above the footer.

## Reading note editor: `09-reading--note-editor`

There is no standalone reference. Authority: M:206. Inspected the six note-editor/note-keyboard captures in the inventory.

| ID | Rating | Manifest check and disposition |
|---|---|---|
| N-A1 | Acceptable | Dawn ground, quiet Cancel, Your note, an ink-bordered surface field with rounded corners, and one Save note primary action match M:206. The empty placeholder “Write a note” is whole at both sizes, and disappears in filled evidence. No character counter is added. |
| N-A2 | Acceptable | At largest text, the field and text grow and Save note moves inline. Empty and filled/bottom captures show the complete action. The filled note wraps naturally; no overlap or lost placeholder text is apparent. |
| N-A3 | Acceptable | Keyboard evidence adds the secondary Done capsule in reserved space. In the first largest-text keyboard stop, Save note is partially at the viewport edge; **`--note-keyboard-largest-text-bottom`** shows the whole button above Done with separation. This is acceptable scroll coverage, unlike C-M1, and follows M:206. |

## Largest text, Reduce Motion and motion evidence

| State/variant group | Result | Image-based evidence |
|---|---|---|
| Ask, ordinary and named entry | Pass | `--largest-text`, `--context`, `--entry`, `--suggestions`, four `--status-*` stops, `--bottom`, `--recent-reading`, and the two named-person largest-text stops cover all headings, three areas, question entry, suggestions, relations and helpers. Named action and explanation can each be read fully, as permitted by M:242. Both tabs remain labelled. |
| About someone | Pass | `--largest-text`, `--explanation`, `--name`, six relation stops, `--note`, `--bottom` and `--filled-bottom` cover all content and both actions. The whole example fits its field. Name/context keyboard captures keep entered words visible and show dismissal controls. Large context field height remains stable in the supplied empty/filled evidence. |
| Initial pick | Pass for supplied coverage | Named top/You/Them/Connection stops show all named slots and labels. The handoff explicitly assigns the inherited `--largest-text-fan` and `--largest-text-bottom` captures to the shared fan region; those show all five backs, Shuffle and its whole helper. This establishes the shared layout's coverage, not a direct image of the named-person fan's large-text instruction. |
| Completed pick | Pass | Named top/You/Them/Connection/bottom stops cover all cards, names, orientations, positions, completion copy and the whole Read my spread action. Ordinary completed variants also remain readable. |
| Named-person Reading | Pass | Opening + scroll-0 through scroll-9 + bottom overlap continuously through card metadata, all three passages, Read together, reflection, feedback, Done and disclaimer. No text is permanently lost at an edge across this sequence. Ordinary reading and selected-feedback variants also pass this visual check. |
| Ordinary composer, empty and filled | Pass at largest text | Top/guidance/field/suggestions/bottom stops expose the full labels, counts, three chips, preview/helper and primary action. Keyboard/dismissed captures retain the entered question and return to a reachable action. C-M1 concerns the **standard empty** state. |
| Note editor | Pass | Empty, filled/bottom, keyboard and keyboard-bottom captures show the full placeholder/note and an unobscured Save note. |
| Named-person Reduce Motion pick | Pass as settled images | Both `08-three-card-pick--named-person-reduce-motion` and `08-three-card-pick-complete--named-person-reduce-motion` show coherent final states: initial fan/empty numbered slots, then three fully face-up cards/completion action. No partial flip, wash or transitional opacity is visible. |
| Ordinary Reduce Motion pick | Pass as regression images | Initial and completed Reduce Motion captures likewise show complete final states. |
| Draw/Reveal Reduce Motion | Quick regression pass | `02-draw--reduce-motion`, `02-draw-card-chosen--reduce-motion`, `03-reveal--reduce-motion`, and `03-reveal--reopened-reduce-motion` show the final fan/selection or face/text/action. No comparison with these untouched screens' references was made. |
| Motion filmstrips | Not supplied | `E/motion/` does not exist. A settled screenshot cannot establish timing, easing, first-paint immediacy, cancellation, pulse suppression or absence of animation over time (M:142–151, 198). |

## What the images cannot establish

- Actual hit regions, VoiceOver labels/order/traits, focus behaviour, font-file identity, colour-token use or numerical contrast. Visual legibility is not an accessibility-audit result. No test/run logs or implementation were read.
- That “largest-text” and “reduce-motion” filenames correspond to actual platform settings rather than a debug configuration; I assessed the rendered variants as supplied.
- Successful taps, saving/restoring drafts, keyboard-dismissal behaviour, error recovery, persistence, local storage, hidden-area routing or whether each relation generates the correct stored reading. Filled/selected screenshots establish visible states only.
- Whether C-M1 is a scroll-position capture problem or an app layout limitation. A complete empty-composer chip at another standard-size stop would resolve the evidence gap; otherwise fix the layout and recapture.
- Exact motion timing or interaction during animation. No motion filmstrip was provided. Different card orientations between independent fixtures do not by themselves show a persistence bug.
