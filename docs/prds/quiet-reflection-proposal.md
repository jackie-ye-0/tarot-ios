# A little perspective

13 September 2026 · Draft visual proposal, not approved product requirements.

[Open the two-screen visual proposal](assets/quiet-reflection.svg).

## Evidence and audience

The [market assessment](../research/market-opportunity.md) records Jackie's confirmed English-speaking audience, with no launch country selected. It recommends customer validation before a product commitment. Its competitor and demographic companion documents are absent. No user interviews, preferred aesthetic, teacher partnership or approved deck are established here.

Working hypothesis: an English-speaking tarot beginner seeking a brief reflective pause. The core experience proposed is one card, a concise interpretation and one question to carry away. This is a design hypothesis, not evidence of demand or repeat use. No current market claims have been reverified for this proposal.

## Interface assessment and direction

The current `HarnessShell/ContentView.swift` is a native navigation stack and form with a counter. Its labels explain the technical test clearly; it contains no reading flow or established visual identity. This is source inspection, not a fresh simulator visual assessment.

Use an editorial reading experience: warm paper, deep green interaction colour, dark ink and generous space around one card. Serif display headings and system body/control text balance character with native legibility. The attached vector composition is a static design artefact, not a simulator screenshot. Geometric card placeholders are original and do not imply a selected or licensed deck.

Begin with a single invitation and “Draw a card”. Push to a card detail containing the card name, a short interpretation and a reflection question. “Finish reflection” returns to the beginning. These transitions are proposed only. No history, streak, account, notification, pricing or AI conversation is needed to evaluate this concept. Return value would have to come from useful reflection; it has not been tested.

## Native implementation criteria, if authorised

Use system navigation and preserve edge-swipe Back. Keep controls at least 44 points, use semantic Dynamic Type styles and adaptive colour assets. The SVG's coordinates describe composition only; implementation must scroll and reflow rather than fix screen heights. At accessibility text sizes, shrink or omit decorative card space, let text wrap and keep the main action reachable. Check light/dark appearance, increased contrast, VoiceOver reading order and Reduce Motion. Decorative geometry is hidden from accessibility; the card name remains readable text.

For a bounded prototype, one synthetic card and fixed copy are sufficient. Prevent repeated taps during navigation; preserve the current card when returning from detail. Finishing clears only in-memory prototype state. A production draw, card selection rules, interpretation provenance, persistence and any failure/loading states need separate requirements. No fake network loading is proposed.

## Consequential decision

Confirm the primary experience: reflective beginner practice, learning card meanings, or entertainment/prediction. The proposal assumes the first. Then approve or revise this visual direction and explicitly authorise a fixed-content native prototype before replacing the technical shell. [Current scope](../decisions.md) excludes production UI and product behaviour; this draft does not amend that decision.

## Validation

Show Jackie the two screens and ask what feels inviting or unclear. With an approved prototype, observe whether people can begin, understand the card and finish without assistance; ask what the reading helped them do. Repeat-use value requires follow-up observation, not aesthetic approval. Test compact iPhone layouts, large Dynamic Type, dark appearance and VoiceOver through a separate accessibility pass.

Initial default doctor failed because full Xcode was not selected. A retry with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` reached simulator discovery but failed. Current native verification is unavailable in this session; historical passes in `docs/verification.md` do not verify this proposal.

The post-documentation `harness check` failed at simulator discovery: CoreSimulatorService connection invalid/refused, with a log-file permission error. Evidence: `.harness/runs/20260913T025016.038126Z-check-f1c24c0f/`. No native tests or fresh exported screenshot were produced. SVG XML parsing passed; local `sips` could not rasterise it, so rendered visual inspection remains pending.
