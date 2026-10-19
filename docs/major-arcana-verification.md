# Major Arcana content verification

Issue #24. First draft, 19 October 2026. Jackie's editorial review is required before any real-user release. Automated checks do not establish that readings are helpful, kind or safe.

## Content and wording review

`HarnessShell/Resources/starter-cards.json` is the single bundled library, now version 6. It contains the 22 Major Arcana, ranks 0–21, in both orientations. Each has three or four keywords, two sentences of daily interpretation, three distinct area lines and integer scores, a named hex colour, object, best hour and all six position meanings. Existing identities and the first six cards' order stay intact; the other sixteen are appended. Expanding the pool necessarily changes future unsaved draws. Saved daily and reading snapshots retain their original content and version.

The original six cards were reviewed along with the new sixteen; their Outcome passages now explicitly invite reflection. The Sun's daily text and the Magician's connection text were also revised to remove implied future change. Outcome describes what to consider, not what happens next. Them asks the reader to hear the other person's account rather than claiming to know their thoughts. Death concerns changing habits and roles; The Devil concerns habits and agency; The Tower concerns reassessing assumptions. Traditional catalogue names remain unchanged. Their interpretations contain no mortality, health, medical, financial or lucky-number content. Scores and extras are prompts for reflection, not probabilities or promises.

Reviewed the Career, Social and all four Relationship lenses (the neutral `lens` plus `single`, `inRelationship` and `complicated`), every suggested question and the complete reflection pool. Their wording keeps decisions with the reader and avoids claims about other people's feelings. Changed the future-directed Relationship suggestion “Where is this going?” to “What matters to me here?” and the reflection about worrying how words land to “What would you like to express more clearly?”. Australian/British forms include colour, recognise, judgement, honours and organising. No source text was copied or external content service used. Crisis patterns and provisional support resources are unchanged and retain their separate release sign-off.

## Automated coverage

The loader checks every card present, including future additions, for filled identity fields, filled keywords (three or four), two or three interpretation sentences, daily extras, all area scores (0–100), distinct trimmed/case-folded area lines and all six meanings. Colour decoding requires exactly six hexadecimal digits after `#`, including rejection of signed numeric strings. Shared suggested questions cannot match after case, punctuation and whitespace normalisation. Lenses and reflection questions must be filled. Authored card text, suggestions, lenses and reflections reject the word “lucky”, including mixed case, hyphenated and spelled-number wording. This deliberately small lexical rule does not classify predictive claims or serious-topic content; those require editorial review. The sentence check counts non-empty segments separated by `.`, `!` or `?`, so editors should avoid abbreviations containing full stops in the daily interpretation.

Unit tests verify all 22 catalogue identities and 44 meanings, compose both reading types across every Major and orientation, and inject invalid fields, scores, colours, duplicate lines and lucky wording into every card orientation. Shared-content mutations cover duplicate questions, all lens variants and reflection wording. Existing snapshot and composition tests remain in place.

UI tests use the app's existing Debug launch configuration. The main reference fixtures use new deterministic seeds to retain The Star upright and Strength on the previous date with the larger pool. Extra tests show the newly added High Priestess reversed on Reveal and Today at normal and largest text sizes, and compose High Priestess upright, Death reversed and World upright through both question and named-person readings. Standard captures use the existing settled-screen strict accessibility audit; existing large-text and Reduce Motion flows remain enabled.

## Verification and design check

`./scripts/harness check` passed in `.harness/runs/20261019T000342.431986Z-check-85c06404`: 34 command-contract tests, the design-role guard and 121/121 iOS tests, with zero failures, skips, expected failures or runtime warnings. Xcode 27.0 (27A266a), iPhone 17e, iOS 26.5. All 15 reference states have main captures; 565 images were exported. The run waited on the shared simulator queue, then finished at 04:36 UTC on 19 October. The test log explicitly records passes for the new whole-library validation and both new Major Arcana UI tests.

Opened the run's `design-comparison.html` in Chrome through `chrome-devtools-axi`. Author inspection covered all 65 `major-content` captures, including every overlapping largest-text stop; main reference pairs for Reveal, Today, Ask, the filled composer, both pick states and reading; representative Ask/composer/pick largest-text and Reduce Motion captures; Today's final action; and the full shared-reading image. This does not claim manual inspection of all 565 images. The High Priestess name wraps without horizontal clipping, the new reading passages remain readable, and the primary actions remain reachable at the largest text size. The existing all-category accessibility audits, font checks and guard passed without any policy changes.

The fresh-session independent comparison returned on 19 October: **pass after one evidence-only correction, T04-E1**. It inspected 415 built images and ten reference images, found no image-proven implementation defect, and rated every other finding acceptable. Jackie's editorial review and real-device/VoiceOver checks remain release limitations.

No layout, typography, colour role, component or motion code changed. The independent reviewer noted that the standard-size reversed Star and reversed High Priestess captures labelled `--bottom` stopped at the area readings. The upright Star and largest-text variants showed their endings, but could not substitute for those two missing states.

## Independent findings and dispositions

The author accepts the review's 53 acceptable findings for the reasons below. T04-E1 is being corrected in the UI evidence tests: keep the intermediate area captures under `--area-readings`, scroll to the midnight caption, verify the final row/action/caption/tabs, then run the existing strict audit and retain the actual `--bottom`. The code is prepared and parses; new captures await firstmate's simulator hold being cleared. No product change is required by this review. The complete independent report is retained in the task evidence as `independent-design-review.md`.

| Finding | Disposition and reason |
| --- | --- |
| T04-E1 | Pending evidence correction: add the actual standard-size endings for reversed High Priestess and reversed Star; the previous area-group images do not establish their final actions/footer. |
| R03-1 | Accepted: selected card identities, artwork, orientation and keywords vary; High Priestess's two-line name remains clear. |
| R03-2 | Accepted: native safe areas, viewport and scrolling explain the lower header/face, higher footer and modest vertical-spacing differences. |
| R03-3 | Accepted: the code-drawn Star retains the manifest's geometric grammar despite different contours, grain and glow/shadow rendering. |
| R03-4 | Accepted: native Share/arrow glyphs, pill width and text metrics preserve the labelled action and hierarchy. |
| R03-5 | Accepted: reopened/archive back navigation and largest-text header rows are specified variants. |
| R03-6 | Accepted: accessibility sizes place the action/disclaimer after scrolling content; all text appears across the captured stops. |
| T04-1 | Accepted: the correct fixture date, selected card and reflective content replace illustrative reference values; colour remains clearly named. |
| T04-2 | Accepted: a native viewport needs multiple captures; the long name wraps alongside the 120-point thumbnail without shrinking content. |
| T04-3 | Accepted: the gear, darker selected tabs and placeholder icon substitutions are explicit manifest choices. |
| T04-4 | Accepted: darker area labels support contrast; static area rows deliberately omit navigation chevrons and grow with their text. |
| T04-5 | Accepted: the manifest specifies the shorter Ask entry; the composer supplies the three-card explanation. |
| T04-6 | Accepted: invitation placement, stacked large-text choices and native permission/save feedback follow the existing states. |
| T04-7 | Accepted: archives retain History selection and omit live-day actions; old snapshots and hidden areas use their specified notices/subsets. |
| T04-8 | Accepted: the largest-text header, extras and scores stack; complete area text and the final action are visible across stops. |
| A05-1 | Accepted: the context panel deliberately uses the saved card name, daily line and score rather than a second interpretation. |
| A05-2 | Accepted: all suggestions are complete reflective questions; changed widths follow the new wording. |
| A05-3 | Accepted: full-width relationship choices, Skip and the conditional recent-reading row are specified states. |
| A05-4 | Accepted: scrolling and stacked controls expose the full content order at larger text sizes. |
| A05-5 | Accepted: native safe areas, grain, typography and the approved dark tab treatment retain the hierarchy. |
| C06-1 | Accepted: the first suggestion matches the reflective question on Ask. |
| C06-2 | Accepted: native title wrapping, chevron weight and spacing preserve field, guidance and count hierarchy. |
| C06-3 | Accepted: preview geometry and footer wrapping retain the three-card explanation and disabled action above the safe-area inset. |
| C06-4 | Accepted: large-text Back/selector/field/footer reflow and hidden-area omissions follow the manifest. |
| CE06-1 | Accepted: the selected question and 24/300 counter reflect the replacement question consistently through the flow. |
| CE06-2 | Accepted: keyboard fixtures scroll the question into view and expose the full action after dismissal. |
| CE06-3 | Accepted: synthetic limit text and the error-role counter demonstrate the specified 300-character limit state. |
| P08-1 | Accepted: the new question and named-person prompts match their composer and position types. |
| P08-2 | Accepted: native spacing, fan angles and disc extent retain the centred progress, three slots and five-card fan. |
| P08-3 | Accepted: night-ground slot interiors and the stronger active edge are explicit component requirements. |
| P08-4 | Accepted: filled slots show real faces, names and orientations without obscuring the next prompt. |
| P08-5 | Accepted: native footer placement, punctuation and large-text vertical stacking preserve Shuffle and its explanation. |
| PC08-1 | Accepted: deterministic fixtures use different example cards; every rotated face agrees with its explicit orientation label. |
| PC08-2 | Accepted: orientation lines add height while preserving card/position associations and the single Read my spread action. |
| PC08-3 | Accepted: retaining the disc and stacking the completed content at largest text are specified layouts. |
| Q09-1 | Accepted: the selected question remains complete and leading, even when it wraps or uses a longer fixture. |
| Q09-2 | Accepted: new card identities and separate orientations follow the face grammar; the long Priestess name stays within its column. |
| Q09-3 | Accepted: original distinct reflective position meanings replace illustrative reference passages in the same order. |
| Q09-4 | Accepted: the longer neutral lens and new reflection remain fully readable and precede optional feedback and Done. |
| Q09-5 | Accepted: audited darker headings and native metrics/glyphs preserve readable sections and distinct header controls. |
| Q09-6 | Accepted: Done/disclaimer are pinned at ordinary size and inline at largest text, as the shared layout specifies. |
| Q09-7 | Accepted: feedback, notes and native menu/confirmation/error states follow the existing reading variants and keep deletion separate. |
| N09-1 | Accepted: You and Sam and You/Them/The Connection are the designed named-person labels. |
| N09-2 | Accepted: dedicated named-position text fits each card/orientation and does not claim certainty about the other person. |
| N09-3 | Accepted: the named introduction and neutral Relationship lens are explicitly shared across all named-person relations. |
| N09-4 | Accepted: extra scroll length exposes every passage, lens and reflection, then feedback, Done and disclaimer. |
| H10-1 | Accepted: questions, cards, dates and marks reflect different saved-state fixtures; image comparison does not prove persistence. |
| H10-2 | Accepted: the gear, dark tab, omitted missed-day commentary and legible future days follow the manifest. |
| H10-3 | Accepted: native wrapping plus large-text date rows, filters and multiline entries preserve readable history navigation. |
| H10-4 | Accepted: archive navigation and omission of live Today actions are specified; archived reading controls remain readable. |
| SH-1 | Accepted: card exports contain only the face, name, orientation and disclaimer, with no app controls. |
| SH-2 | Accepted: reading exports retain all original reading sections and disclaimer while deliberately excluding controls, notes and responses. |
| SH-3 | Accepted: a 390-point document at double resolution uses natural height and ordinary type, independently of screen text size. |
| SH-4 | Accepted: native share-sheet styling and descriptive payload previews are specified platform behaviour. |

The image review does not prove numeric contrast, font loading, VoiceOver behaviour, tap targets, persistence or animation timing; those remain separate automated/manual checks. Its still-image Reduce Motion check found complete settled states.

## Committed-head recheck

A fresh full check on clean `a183885` ran in `.harness/runs/20261019T093349.560097Z-check-775993fd`. It passed the 34 command-contract tests and design-role guard, then recorded 61 passing XCTest cases and one failure in the unchanged 78-face gallery's Next navigation: the title remained 67–69 instead of 70–72 immediately after the tap. The new question/named-person Major Arcana reading test passed; the daily-content test was still running when the check stopped. These are partial log counts, not a completed suite result.

Firstmate identified the gallery failure as the known dropped-tap-after-audit issue and is arranging its test-wait fix separately. At firstmate's instruction the harness received SIGINT to release the simulator for another review. It exited 130, explicitly reporting an incomplete run, and released the lock at 10:26:05 UTC on 19 October. Its xcodebuild child also exited. The interrupted result bundle lacks `Info.plist`, so `xcresulttool` cannot export its attachments; the raw test log, metadata and failed summary are retained. No failed-run screenshots are claimed. The failure and interruption prevent this run establishing verification.

No tests or audit categories were filtered. The capture correction above was prepared after this run had built and is not claimed to be tested by it. No new simulator run will start until firstmate clears the hold; that run must include the corrected final Today captures.
