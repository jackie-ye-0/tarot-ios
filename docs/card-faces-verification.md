# Full-deck card faces (#12)

The artwork catalogue supplies 22 unsuited Major Arcana (ranks 0–21) and four suits of 14 Minor Arcana (Ace through King). `TarotCardView` renders from suit and rank through shared paths, discs, stars, crowns and linework in the design system. Each Major has its own emblem; Minor pip counts and court framing distinguish ranks without depending on colour. The existing Star landscape is preserved.

Artwork identity is separate from interpretation content. Existing `TarotCard` snapshots expose their identity without a schema change. The six-card reading pool, its order, saved readings and daily hash remain unchanged; original interpretations for the remaining cards belong to #24–#26. There is no new production navigation, dependency, service or bundled raster artwork.

## Acceptance evidence

- **78 identities:** the engine test checks unique IDs/names, all 22 Major ranks, exactly 14 ranks per suit, court names and agreement with every bundled reading card's identity.
- **156 rendered faces:** the real-app Debug gallery test visits all 26 pages, checks every name/orientation accessibility label and visible face frame, captures non-empty distinct face images, and keeps a screenshot of every page. The reversed pairs visibly rotate the artwork 180 degrees and retain upright, scalable “Reversed” text outside it. Canvas decoration is hidden and each card exposes one accessibility label.
- **Sizes:** the real-app size proof checks 214, 120, 84 and 36-point widths. Samples cover the Star, Ten of Wands, Page of Cups, Ten of Swords and Queen of Pentacles. The gallery covers the remaining identities at 72 points. These prove the shared component's spread/thumbnail sizes; this ticket does not build the later spread or History screens.
- **Accessibility and fonts:** unfiltered audits run on Reveal, Today and the proof screens, plus the unchanged Draw/error regression states. Audits run after ritual animations settle. The existing font test verifies both families and PostScript names. The source guard passes with all colour/font/radius primitives in `DesignSystem.swift`.
- **Large text and motion:** retained largest-text captures cover Reveal, Today and both proof screens, including reachable final actions and overlapping scroll positions. Existing Draw/Reveal Reduce Motion captures remain. Three-card pick is outside this ticket. The proof screens have no animation.
- **No raster card art:** the app resource build phase contains the existing reading JSON and fonts/licences; faces are Canvas paths. Test PNGs and design references are evidence, not app resources.

## Author image comparison

The generated `design-comparison.html` was opened with chrome-devtools-axi. All 26 gallery pages, all four size captures for five samples, and the touched screens' normal, reversed, largest-text and Reduce Motion captures were inspected. The first inspection found touching/overlapping pips on Ten cards, especially sword tips and hilts. Their scale was reduced to leave gaps, and Ten of Swords replaced the sword court sample in the size proof. The final confirmation pass inspected all 82 retained images and confirmed the separated Ten-card pips at every captured width.

| Screen/state | Accepted difference and reason |
| --- | --- |
| Draw / chosen (unchanged regression captures) | The real status bar, correct Sunday date, slightly lower shared disc/fan anchor, original ray/grain contours and native-safe-area footer remain the foundation differences. They preserve separate five-card tap lanes and the shared large-text layout. History navigation is outside this ticket and remains omitted under manifest §11. Shuffle/washing and Reduce Motion follow §7. |
| Reveal (`03-reveal`) | The original Star's precise star, hills, waves and dot contours differ slightly from the reference. They retain the previously accepted original code drawing and manifest palette, proportions and ink linework. The new renderer preserves this face. |
| Reveal | Native status indicators/home indicator, small font-metric differences, a 5:8 card and native safe-area button position remain. These follow the manifest's native layout and type roles rather than a fake status bar or fixed web artboard. Share is absent because #23 owns it. |
| Today (`04-today`) | Same Star drawing and native typography/inset differences. Sunday is correct for the injected 11 October 2026. The reference's Saturday is not copied. The 120-point, 5:8 thumbnail remains slightly more compact than the web reference. |
| Today | The original draft interpretation differs from the mock paragraph. Extras, scores, area lines and card expansion belong to #9; Settings belongs to #20. Tabs and other full-app navigation remain the explicit foundation omissions in manifest §11. These controls and the lower reference sections are outside #12. The midnight caption follows the current reading content, as §11 requires, leaving the existing open space below. |
| Largest text | Today stacks artwork above metadata and ritual/proof actions move inline after scroll content. Text grows and wraps without a cap. These are the manifest's shared large-text rules, rather than the standard-size reference composition. |
| Reversed / Reduce Motion | Reversed artwork is upside down with visible orientation text and an appropriate separate meaning on Today. Reduce Motion shows the final static state. Neither needs a new reference layout. |
| Face gallery / size proof | These Debug-only evidence states have no reference images. Their layout and the complete original face grammar are documented in manifest §5, using its existing roles and shared scrolling layout. The remaining 77 faces are original geometric compositions, not copies of the Star picture. |

## Validation and review status

`./scripts/harness check` passed in `.harness/runs/20261013T221131.878092Z-check-04fe02be/`: 34 command-contract tests, the design-role guard, and 28 iOS tests (13 engine/font and 15 UI), with zero failures, skips or expected failures. Xcode 27.0 (27A266a), iPhone 17e, iOS 26.5. `./scripts/harness evidence` and all 82 exported screenshots were inspected, including the generated comparison page and the complete 78-face gallery. Missing main captures in the summary are the later product screens outside this ticket.

Initial checks found shorthand font roles in the proof view, a Debug override that prevented the audit from increasing text size, and a test swipe over the proof screen’s pinned footer. These were corrected without changing the source guard or filtering audits. One unchanged five-position Draw test missed a tap in the first iOS run; its retained hierarchy was inspected and it passed unchanged in both subsequent complete runs. The first all-green run then exposed the Ten-card pip-spacing defect during image inspection; the final run above includes that correction.

Independent image comparison is pending Firstmate's fresh-session review of the final evidence packet. This document does not claim that independent approval. A physical-device and manual VoiceOver reading-order pass remain release limitations, as in the foundation slice; automated label/audit coverage is recorded above.
