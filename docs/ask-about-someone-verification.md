# Ask about someone (#18)

Status: implemented; local UI verification and the independent image comparison are pending.

The Relationship-only Ask entry opens the reference's name/relation/context form. Name and one of Partner, Crush, Ex, Family, Friend or Colleague are required, and relation starts unselected. The disabled action explains what is missing; the enabled action names the person. No birth details are collected.

The existing draft, pick and saved-reading path now carries optional person details. Their presence identifies a distinct `namedPerson` reading type with You, Them and The Connection positions. Older records remain ordinary question readings without a database migration. Saved snapshots carry the original person context and the three dedicated position meanings; annotations remain separate. The note and any question are checked against the bundled crisis phrases before picking and again before composition.

## Verification coverage

- Engine tests cover all six relations, whitespace-only names, missing-field labels, named-person positions, selection without replacement, dedicated meanings in both orientations, deterministic composition, name inclusion, Relationship tagging, immutable encoding, invalid inputs, older snapshots and crisis matches in either input.
- `testNamedPersonFormDraftPickAndSavedReadingEvidence` exercises the actual app: area-specific entry, initial form, required values, saved context, background/relaunch, locked picks, completed reading, reopening after a library change and the latest Relationship reading.
- `testNamedPersonCrisisNoteClearsDraftAndBackDiscardsDetails` exercises note-triggered support before a pick, failed draft removal followed by relaunch/retry, no saved reading, and clearing person details on Back to Ask.
- `testNamedPersonLargestTextAndKeyboardEvidence` captures the form, keyboard, each relation, named-person pick, completed pick and full reading at the largest text size, with actions reachable. Pick captures disable motion using the existing Debug Reduce Motion option.
- The standard-size screen test runs the existing strict accessibility audit on the form, Ask entry, both pick states and reading scroll stops. The existing suite continues to verify fonts, source design roles and unchanged question-reading screens.

## Visual evidence

The form is governed by `07-about-someone`; Ask, pick and reading retain their existing references. Manifest §11e documents the named-person variants, large-text reflow, keyboard behaviour and draft states. Final run paths, inspected captures, accepted differences and independent-review dispositions will be recorded after verification.

## Limits

The six-card content remains original draft writing for editorial review. Crisis detection is the existing finite phrase list, with its existing provisional support resources; it is not semantic assessment. Real-device behaviour and VoiceOver reading order still require a manual pass.
