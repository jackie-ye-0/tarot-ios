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

## Release limits

The new lens variants are original draft writing requiring editorial review before release. Real-device behaviour and manual VoiceOver reading order are not established by simulator evidence. Named-person questions (#18), History (#19), Settings editing and data export/deletion remain assigned to other tickets.
