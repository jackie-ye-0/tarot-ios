# Full Ask and composer verification (#14)

Status: implementation complete; iOS verification and independent image comparison pending.

## Behaviour and tests

| Requirement | Evidence |
| --- | --- |
| Today's line and score follow the selected area | `testAskContextStatusAndLatestSavedReading` checks all three saved lines and their spoken scores. Older snapshots without daily content omit the panel. |
| Latest reading opens unchanged, with no empty placeholder | The same test creates two Relationship readings an hour apart, reopens the newest after relaunch with revised content, compares every saved passage, and checks Social has no recent-reading section. |
| Live 300-character count and rejection | `testComposerLimitAreaChangeAndDraftRestoresAfterBackgroundAndRelaunch` types 301 characters, checks 300 remain and the limit label, then deletes one character and checks the ordinary count returns. `AskComposerRulesTests` covers emoji graphemes, long pasted text, insertion before existing words, Return and engine submission limits. |
| Disabled label identifies what is missing | The main Ask flow checks “Write or pick a question” on the disabled button; the existing whitespace test verifies that spaces alone cannot submit. |
| Area changes preserve text and replace suggestions | The draft test switches from Relationship to Career with a full question and compares both text and suggestions. |
| Preview of the next three slots | The main flow verifies Situation, Action and Outcome are announced as empty; composer captures show the three dawn outlines. |
| Draft survives backgrounding and relaunch | The draft test backgrounds and reactivates the real app, terminates it, relaunches the same isolated disk store and reopens the composer with the same question and area. It also proves Back to Ask clears the saved draft. Reading creation clears the draft in the same SwiftData save as the immutable reading. |
| Relationship prompt is optional, once only and stored | The status/latest test selects Single, verifies it remains selected for composition after relaunch and that the prompt stays absent. `testSkippedRelationshipStatusIsRememberedWithoutChoosingAStatus` verifies the separate skip path after relaunch and a neutral reading. |
| Correct status lens, with neutral fallback | Parameterised engine tests cover every status in every area, plus unset status, distinct texts and deterministic composition. UI tests prove Single and skipped status reach composition. |
| Targets at least 44 points | Status chips and the latest-reading target have geometry assertions; the inherited controls retain their 44-point minimums and native hit-region audits remain enabled. |

Persistence uses the existing local SwiftData container. No services, network calls or dependencies were added. Question and area save after every edit. A failed draft save retains the words and offers retry; a failed preference save retains the prompt. Card-pick persistence remains the separate #15 scope.

## Design check

Touched screens are Ask (`05-ask`) and the empty/filled composer (`06-composer`, `06-composer-question-entered`). The reading renderer and pick layout are unchanged; the existing flow continues to capture and audit them, including pick Reduce Motion evidence.

The tests retain top and bottom captures, Ask status and recent-reading states, the character-limit state, every relationship choice at largest text, composer keyboard states, and the inherited largest-text action checks. All native accessibility audit categories remain enabled in the existing settled-screen helper. Font loading is covered by the existing font-registration test; the lexical design-role guard is unchanged.

The new context, status, recent-reading, count, preview and error states are described in `design.md` §11b. Comparison results, final run details and the independent verdict will be recorded after verification.

## Development checks

The first full check, `20261014T091809.449753Z-check-d8528a11`, ran 52 tests: 50 passed, two failed, zero skipped and zero expected failures. All 34 command-contract tests and the design-role guard passed. The app was committed as `8fea110` while the run waited for the shared simulator; the harness's initial revision capture therefore records the earlier base plus a dirty worktree. App and test sources were unchanged from that commit throughout compilation and execution.

The failed UI cases were the main composer's footer audit and the character-limit test. The exported `06-composer` image was inspected and shows the footer fully visible; the helper had incorrectly required it to fit inside the separate scrolling viewport. The correction identifies actual footer descendants and audits them within the footer's intersection with the real safe area. Content behind that footer still uses the unoccluded scroll viewport. No audit category, contrast threshold or plain-static-text-only measurement rule changed. The field failure showed 301 characters in the native field despite the saved binding being capped at 300. A local native edit buffer now visibly rolls back rejected input before writing valid text to the draft binding.

The first run's Ask top, status prompt and recent-reading images were inspected, as was the empty composer. These inspections do not turn the failed run into verification. A new full check is required for both corrections.

The second check, `20261014T104334.763452Z-check-65b147a1`, built clean commit `2d7acf2` and passed 51/52 tests, with zero skips and expected failures. All command tests and the design-role guard passed. The original two failures were fixed: the full main Ask/composer/pick/reading audit passed (the pinned helper's own image measured 5.24:1), and the limit test passed rejection, area changes, backgrounding and disk restoration. Its later one-backspace assertion still reported 300 characters. That test had not established a character before the restored caret. The follow-up uses explicit [XCTest key events](https://developer.apple.com/documentation/xcuiautomation/xcuielement/typekey%28_%3Amodifierflags%3A%29-6gaoi): one right arrow, then Delete. It retains the 299-character counter assertion and adds an assertion on the native field's actual text. App code is unchanged. The second run's retained limit image was inspected; the count, field and primary action are legible. This run remains failed pending verification of the test correction.

## Release limits

The new lens variants are original draft writing requiring editorial review before release. Real-device behaviour and manual VoiceOver reading order are not established by simulator evidence. Named-person questions (#18), History (#19), Settings editing and data export/deletion remain assigned to other tickets.
