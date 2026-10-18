# Ask about someone (#18)

Status: the branch is rebased onto Morning reminder at `9974dae`, with one combined full check pending. The pre-review full check `20261017T205214.525756Z-check-1c7ea2ed` passed **96/96 iOS tests**, with zero failures, skips or expected failures, on clean `2d142eba19c400dcce73098c5a56ae677adfb965`; its **34 command-contract tests**, Swift parsing and design-role guard also passed. That result describes the pre-correction revision only. One independent comparison returned a conditional pass with C-M1 and P-S1; both corrections now have passing assertions and inspected images, with a fresh comparison of the final combined evidence still required. The later failed runs and diagnostic reruns remain recorded separately below.

The Relationship-only Ask entry opens the reference's name/relation/context form. Name and one of Partner, Crush, Ex, Family, Friend or Colleague are required, and relation starts unselected. The disabled action explains what is missing; the enabled action names the person. No birth details are collected.

The existing draft, pick and saved-reading path now carries optional person details. Their presence identifies a distinct `namedPerson` reading type with You, Them and The Connection positions. Older records remain ordinary question readings without a database migration. Saved snapshots carry the original person context and the three dedicated position meanings; annotations remain separate. The note and any question are checked against the bundled crisis phrases before picking and again before composition.

## Verification coverage

- Engine tests cover all six relations, whitespace-only names, missing-field labels, named-person positions, selection without replacement, dedicated meanings in both orientations, deterministic composition, name inclusion, Relationship tagging, immutable encoding, invalid inputs, older snapshots and crisis matches in either input.
- `testNamedPersonFormDraftPickAndSavedReadingEvidence` exercises the actual app: area-specific entry, initial form, required values, saved context, background/relaunch, locked picks, completed reading, reopening after a library change, the latest Relationship reading, and reopening the unchanged named-person snapshot through the Relationship History filter.
- `testNamedPersonDraftKeepsRelationshipWhenAreaIsHidden` preserves a partially picked named-person draft through hiding Relationship and relaunch, saves it with the correct Relationship tag, and finds it again after the area is shown.
- `testNamedPersonCrisisNoteClearsDraftAndBackDiscardsDetails` exercises note-triggered support before a pick, failed draft removal followed by relaunch/retry, no saved reading, and clearing person details on Back to Ask.
- `testNamedPersonLargestTextAndKeyboardEvidence` captures the form, keyboard, each relation, named-person pick, completed pick and full reading at the largest text size, with actions reachable. Pick captures disable motion using the existing Debug Reduce Motion option.
- The standard-size screen test runs the existing strict accessibility audit on the form, Ask entry, both pick states and reading scroll stops. The existing suite continues to verify fonts, source design roles and unchanged question-reading screens.

A separate macOS command-line smoke run exercised 72 named-person compositions across all six starter cards, both orientations and all six relations, plus snapshot/draft decoding, crisis rejection and legacy draft compatibility. It used the actual engine sources and bundled JSON without a simulator. This supplements, but does not replace, the required full harness pass.

## Visual evidence

The form is governed by `07-about-someone`; Ask, pick and reading retain their existing references. Manifest §11h documents the named-person variants, large-text reflow, keyboard behaviour and draft states. The shared chip minimum also touches ordinary Ask/composer suggestions and reading feedback. The shared note field is checked in the existing reading-note editor.

`./scripts/harness evidence --run .harness/runs/20261017T205214.525756Z-check-1c7ea2ed` was read and its `design-comparison.html` opened with `chrome-devtools-axi`. The final exported images were inspected against the references: Ask's named-person entry, empty/filled form and its bottom, both named pick states, the named reading's opening/position/lens/bottom stops, their largest-text variants, both form keyboards, and the shared composer and note-editor states. At largest text, the six relation labels remain whole, name and context are readable, and Draw, Read my spread, Done and Save note remain reachable. Scroll-boundary cropping is accompanied by overlapping stops; no internal text truncation was found in the inspected states.

The full run retains normal and largest-text captures for all affected screens, and Reduce Motion captures for the named pick. Draw and Reveal are unchanged, with their existing Reduce Motion and largest-text evidence retained. The comparison page matches 13 of 15 main references; the missing first-day reminder and History screens belong to #21 and #19, outside this ticket.

The form (empty, filled and bottom) and both named pick audits reported no issues. Ask's off-screen context was deferred through the existing overlapping-stop coverage. Fully visible plain reading text received the existing measured-contrast treatment, with retained ratios **9.0610:1–9.0624:1**, above 4.5:1. Every audit category remains enabled, and every deferred element must become fully visible. No audit helper or lexical design guard was changed. `testBundledTypefacesDoNotFallBack` passed for the bundled fonts.

### Accepted visible differences in the pre-History review

These are the author's dispositions for the independently reviewed `1c7ea2ed` images. History has since landed: the next evidence will have three tabs and “Saved to History” metadata. The historical two-tab and phone-only wording rows below do not describe the rebased interface.

| Difference from reference | Reason |
| --- | --- |
| Native status indicators, heavier system navigation symbols, grain, text metrics, line breaks and small vertical-spacing differences | The references are web artboards; the app uses native safe areas, bundled type roles and shared 44-point navigation. The 20-point page guides and hierarchy are retained. |
| Name and context borders are dark ink, rather than the reference's pale outline | Manifest §5 requires the main-entry field's 1.5-point ink border. This matches the established question and note fields. |
| The name field and context box are taller; the context keeps its reserved space after entering a short note | The shared field roles use a 60-point name minimum and padded multiline editor. Reserving the full placeholder height keeps the example readable at the largest text size and prevents layout jumps on typing. |
| “Anything specific? (optional)” is one label rather than a separate right-aligned Optional label | A single label preserves the relationship between the field and its optional status when text wraps. |
| Relation, question, status and feedback chips use a 48-point minimum rather than 44 | Fractional scroll coordinates had exposed a height just below 44. The design-system minimum leaves room above that accessibility floor, without weakening the assertion. |
| Ask's entry helper wraps to two lines at ordinary size; at accessibility sizes it is a separate text region inside the same surface panel | The existing body/metadata roles remain readable, and the navigation target can fit fully within the scroll viewport. All helper copy is retained. |
| Ask uses the saved card context, question-form suggestions, stacked status choices and conditional recent-reading row | Existing manifest §11b behaviour uses actual saved data and keeps all status choices readable. The reference's example history row is absent for a fresh store. |
| Ask has two tabs with a dark selected pill | History remains #19. The existing high-contrast selected treatment is specified in §5. |
| Named pick and reading use “You and Sam”, You / Them / The Connection, dedicated passage text and a named connecting passage | These are the required named-person reading semantics, replacing the ordinary-question examples in the shared references. “The Connection” uses the issue's capitalisation consistently. |
| The fixture shows The Star, The Sun and The Fool, with orientation labels on all cards and different geometric card faces | The fixture uses the installed starter library and existing full-deck card grammar. Both upright and reversed are stated explicitly; cards are never replaced merely to match an illustration. |
| Night fan geometry, spacing and disc placement differ slightly | The established reusable fan and night layout are preserved; this ticket changes the prompt and position labels. |
| Reading metadata says “Saved on this phone”; Done and the disclaimer stay pinned at ordinary sizes | These are the established local-store wording and reading layout, documented in §§11a–11c. The content scrolls above the footer. |
| Largest text stacks relation choices and cards, wraps headings/actions and moves footer actions inline | The shared accessibility layout keeps complete labels and reachable controls instead of shrinking text. Keyboard controls keep native iOS styling. |
| The note editor has no separate reference image | Its inherited appearance is specified in §11a; the shared placeholder change retains the same field and Save note flow at both text sizes. |

### Verification history and remaining gate

The earlier full check `20261017T132432.746532Z-check-11d23d53` had two failures: a fractional 44-point status-chip frame and an oscillating scroll attempt around the largest-text combined entry. The 48-point minimum and separate accessible helper resolved both; `20261017T144832.549176Z-check-ea841f82` passed 89/89 before the Settings rebase. The final 96/96 run additionally covers retaining a named-person draft's Relationship tag while the visible area changes. The interrupted first run was affected by another simulator user and is not verification evidence.

Final review material is copied outside the worktree into the task's `final-evidence` directory: the exact design manifest, references, exported screenshots, comparison page and a screen/state handoff. The first independent comparison is now recorded below. No no-mistakes run has started.

## Independent review and corrections

A fresh agent session reviewed only the supplied manifest and images on 18 October 2026: seven references and 142 built screenshots. Its verdict was **pass after C-M1**, with P-S1 recommended as well. The [review record](ask-about-someone-design-review.md) preserves every accepted visual difference and its reason; its image-only verdict does not replace the full harness/accessibility results.

| Finding | Disposition and validation status |
| --- | --- |
| **C-M1**, must fix: the ordinary empty composer's main and bottom screenshots both cut the last suggestion's lower rounded edge at the pinned footer | The standard empty-state test now deliberately scrolls to the content bottom, waits for the chip to settle, asserts its complete frame is visible and checks at least eight points of separation from the footer before retaining the bottom screenshot. The 48-point chip and existing footer/content spacing are unchanged. The assertions passed in full run `2abbf3ae`; the exported `06-composer--bottom` image was opened and shows the complete final chip above the footer. No app layout change was needed. |
| **P-S1**, should fix: “Choose your You card” is awkward | Changed all three prompts to “Choose a card for you”, “Choose a card for them” and “Choose a card for the connection”. UI tests assert each actual displayed instruction and retain the intermediate normal-size and all three largest-text prompt captures. Manifest §11h states the wording. All three largest-text prompt assertions passed and their complete wraps were inspected in `2abbf3ae`. The standard prompts passed in `b26ad179`; its Them and Connection captures were inspected with the correct one/two filled slots and complete fan. |

All other reviewed differences were accepted with the manifest-based reasons in the review record. The reviewer found no must-fix form, named reading, completed-pick, largest-text or settled Reduce Motion issue. The supplied static images do not certify motion timing, actual accessibility semantics, or font/contrast measurements; those remain covered by their corresponding automated evidence and stated limits.

## Post-review validation

- Full check `20261018T115654.007175Z-check-2abbf3ae` on clean `93e7065` passed **104/105 tests**, with zero skips. The named-person test expected Them after restoring a draft, but its first plain tap immediately after an audit had not selected a card. The failure recording shows all slots still empty before Back; the old assertion compared an empty slot to an empty slot. The test now uses the existing settled-tap helper and requires a filled You slot and the Them prompt before testing restoration.
- Replay `20261018T171819.792733Z-test-b26ad179` on `5b1f5a9` ran **all 57 UI tests** because the initial temporary scheme selector was ignored. The named-person method passed in 380.753 seconds, including draft restoration, the three prompts, saved-library immutability and the History round trip. Its normal prompt and reading top/bottom images were inspected. The run passed **56/57**, with only the card-face fixture's final Start again tap failing.
- The card-face method and fixture were unchanged from the landed base and had passed in both preceding full runs. Its failed recording shows the last page still visible after another immediate post-audit tap. Firstmate authorised using the existing settled-tap helper, preserving one tap, every face/audit assertion and the five-second return bound. Corrected one-method replay `20261018T192029.553182Z-test-3910bc2b` on `f4a0837` passed **1/1**, zero failures or skips, with Xcode exit 0. The harness correctly returned exit 1 because one test is below its unchanged four-test minimum. This is diagnostic evidence, not a full-check pass.
- Both replay schemes were restored byte-for-byte. The second used the scheme's `useTestSelectionWhitelist` and `SelectedTests` fields; no selector or harness change is committed. After rebasing onto `9974dae`, the one authorised combined full check remains pending.

## Limits

The six-card content remains original draft writing for editorial review. Crisis detection is the existing finite phrase list, with its existing provisional support resources; it is not semantic assessment. Real-device behaviour and VoiceOver reading order still require a manual pass.
