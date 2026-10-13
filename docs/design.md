# Design manifest

11 October 2026 · Adopted by Jackie as the visual and interaction direction for the tarot app. This is the single source of truth for how the app looks and behaves on screen. Follow it for any design or UI work; change the app's look by changing this file first. Updated 12 October 2026: Settings matches the build spec, and the reference images and design check (§12) were added.

**What this does not do.** It does not approve building product features. [Decisions and scope](decisions.md) still governs what may be implemented. Issue #7 implements Draw, Reveal and a basic Today; later screens remain reference designs.

**Sources.** The reference screens are the eleven artboards (01 Welcome to 11 Settings) and the flow map on the [design canvas](https://claude.ai/artifact/3H8wh1JXA8eg4xQMdDqUw6), a private link. The canvas holds one design; earlier drafts are only in its version history. Because the link is private, a picture of every screen is kept in [design-reference/](design-reference/README.md); use those when you cannot open the canvas. The starting point was the [V1 PRD](prds/prd-divination-app-v1.md) §10 "Soft dawn". Where the two disagree, this file wins. It changes §10 in two ways: cards are tall rounded rectangles, not arch-topped, and the screens before a card is turned use a deep indigo night palette.

## 1. Principles

Apply these before any specific rule below. When a case is not covered, decide by them.

1. **Value before asks.** The first card comes before any form, permission or sign-up. Ask for something only at the moment it visibly helps.
2. **One primary action per screen.** It is always the same shape, in the same place, in the same colour for that light.
3. **A button does exactly what its label says.** "See what it means today" shows the meaning, never a permission request.
4. **Always show where you are and what is next.** Three labelled tabs; titles that say what to do.
5. **Hierarchy from type and space, not boxes.** The tarot card is the only "card". Do not wrap sections in bordered panels to separate them.
6. **One world, two lights.** Deep indigo night before a card turns, rose dawn after. The change of light is the app's one dramatic moment.

## 2. Colour

Never use pure black or pure white. Every colour below is a named role; use the role, do not invent neighbours.

### Dawn (light) screens

Used once a card is face up: reveal, Today, Ask, composer, reading, History.

| Role | Hex | Use |
|---|---|---|
| Ground | `#f3e4dc` | Screen background |
| Surface | `#fbf4ef` | Text fields, tab bar, list groups, card faces |
| Ink | `#43302b` | Primary text, icons, primary button fill |
| Secondary ink | `#6b524b` | Supporting text |
| Placeholder | `#7a5f57` | Input placeholder text |
| Hairline | `#e3cdc3` | Dividers on ground (`#efe2dc` inside a surface) |
| Control track | `#ead6cd` | Segmented control background |
| Control border | `#e0c9bf` | Unselected chips and outlined pills |
| Disabled | `#dcc6bc` fill, `#5f4740` text | Disabled primary button |
| Destructive | `#a3331f` | Delete, only inside a menu |

### Night (dark) screens

Used before a card is turned: welcome, draw, three-card pick.

| Role | Hex | Use |
|---|---|---|
| Ground | `#1b1430` | Screen background |
| Disc | `#2b2050` | One large soft circle behind the cards |
| Card back | `#2b1f47` | Face-down card fill |
| Gold | `#e2b65c` | Card back linework, slot numbers, link underline. Night only. |
| Cream | `#f6ecdf` | Primary text, primary button fill |
| Secondary text | `#c9bcd8` | Supporting text (`#d8cce4` for a full paragraph) |

### Accents and the three areas

Each area owns one accent, used the same way everywhere. Raw accents fail contrast as text (2.1 to 3.5:1), so they are for bars, dots, tints and card art only. Text uses the darker partner.

| Area | Accent (fills) | Label on ground | Tint panel | Text on tint |
|---|---|---|---|---|
| Career | Blue `#6f8ca2` | `#4f6b80` | `#dfe5ea` | `#3f596d` |
| Relationship | Clay `#b0654a` | `#9a543b` | `#f0d6cb` | `#8a4a33` |
| Social | Sage `#7d8f6a` | `#566847` | `#e2e6d9` | `#4d5e3d` |

Ochre `#c79a3f` belongs to the cards themselves: card art, the sunrise glow, and the "card drawn" mark in the History calendar. It is not a fourth area.

### Texture

Every screen carries a fine risograph-style grain over the ground: about 16% strength multiplied on dawn screens, 10% screened on night screens. It is decoration; nothing may depend on it.

### Contrast

Text must reach at least 4.5:1 against what it sits on. Measured pairs: ink on ground 10.0, secondary on ground 5.8, placeholder 5.4, disabled label 5.2, area labels 4.5 to 4.9, cream on night 15.1, secondary on night 9.8. Re-measure any new pair before using it.

## 3. Typography

Two families, both open licence (SIL OFL): **Gabarito** for display and buttons, **Hanken Grotesk** for everything else. The approved build spec bundles both variable font files with their SIL OFL licences. Font roles use Dynamic Type; the font-loading test rejects system fallback.

| Role | Family, weight | Size | Notes |
|---|---|---|---|
| Display | Gabarito 700 | 40 to 44 | Card name, welcome headline. Tracking -0.02em, line height 1.0 to 1.05 |
| Screen title | Gabarito 600 | 30 | Tracking -0.01em, line height 1.15 |
| Section title | Gabarito 600 | 20 to 24 | |
| Button | Gabarito 600 | 18 | |
| Body | Hanken Grotesk 400 | 16 to 17 | Line height 1.5 |
| Secondary | Hanken Grotesk 400 | 15 | |
| Label | Hanken Grotesk 600 | 14 | |
| Caption | Hanken Grotesk 400 | 13 | Disclaimers, helper lines |
| Tab label | Hanken Grotesk 600 | 12 | Smallest size allowed, tab bar only |

Card names use Display: 44 on Reveal and 40 beside the Today thumbnail. Card orientation/arcana uses the 16-point body scale with weight 600; Reveal keywords use 16-point regular body text. The standard interpretation has approximately 1.5 line height.

Sizes are the default-size reference in points. In SwiftUI map each role to a Dynamic Type text style so it scales with the user's setting; never fix a size that cannot grow. Emphasis comes from weight 600, not colour. No all-caps labels.

## 4. Shape, spacing and layout

- **Tarot card.** A tall rounded rectangle, about 5 wide to 8 tall, corner radius about one-tenth of the card's width. Every card uses this one shape at every size: face-down backs, face-up fronts, empty slots, thumbnails, calendar marks and the Today tab icon. No arch tops.
- **Controls are fully rounded.** Height 56 gives radius 28; height 44 gives radius 22.
- **Surfaces** (grouped lists, the reminder card, multi-line text fields) use radius 20 to 22.
- **Tap targets** are at least 44 by 44 points, including text links and icon buttons.
- **Screen padding** is 20 at the sides (24 on the night ritual screens), 56 above the first row, 28 to 32 below the last.
- **Base unit 4.** Common gaps: 8 within a group, 12 to 16 between related items, 24 to 28 between sections.
- Lay out for a 390 by 844 point iPhone as the reference, but screens must scroll and reflow. Never fix a screen's height or draw a fake status bar.

## 5. Components

- **Primary button.** Full width, 56 high, radius 28, Gabarito 18/600, pinned at the bottom of the screen. Dawn: ink fill, surface-coloured text. Night: cream fill, night-ground text. One per screen. Disabled state uses the disabled colours and a label that says what is missing ("Write or pick a question").
- **Quiet action.** Second-rank actions are text only: an underlined link (gold underline on night) or a plain text button, 44 high. Never a second filled button beside the primary. The one exception is a paired choice inside an invite card ("Remind me" / "Not now"), where the decline is an outlined pill.
- **Tab bar.** Today, Ask, History. Icon plus label, always both. Surface background with a hairline above. The selected tab has a tinted pill behind its icon and ink text. Shown on dawn screens at rest; hidden on ritual screens (draw, reveal, three-card pick) and in the composer and reading.
- **Area selector.** A three-part segmented control showing Career, Relationship and Social at once, 44 high segments on the control track, selected segment in surface colour. Never a single pill that cycles.
- **Chips.** 44 high, radius 22. Selected: ink fill, surface text. Unselected: surface fill, control border.
- **Text field.** Surface fill with a 1.5 ink border when it is the main entry on the screen. A single-line entry is a 60 high pill; a multi-line one uses radius 20. It must look like a field, with placeholder text and a character count where there is a limit.
- **Card back.** Card-back fill, gold outline, a thinner inner frame and a half-sun-on-horizon motif. Identical everywhere.
- **Card front.** Surface fill with an ink outline (gold outline when shown on night). Art is layered flat pastel shapes with ink linework, abstract rather than illustrative. Reversed cards are rotated 180 degrees and say "reversed" in text as well.
- **Empty slot.** Dashed outline in the card shape with its number. The slot being filled has a gold outline and a slow pulse.
- **Score strip.** The three area scores sit in one row: area label, numeral, and a 6 point rounded bar in the area's accent on a neutral track. Numbers are always shown as text; the bar never carries the value alone.
- **List rows.** 60 to 76 high inside a surface group, hairline between rows, chevron at the right when the row navigates.
- **Destructive actions** live inside a More menu, never beside Share or Done.

## 6. Navigation and flow

- First open reaches a turned card in three screens: welcome, draw, reveal.
- The entertainment disclaimer is on the welcome screen itself and repeated quietly under the reveal. It cannot be skipped.
- Night screens show only what the ritual needs: a title that says what to do, the cards, and one quiet alternative (shuffle).
- Top-left is a 44 point back chevron or close cross when there is somewhere to go back to. Share sits top-right.
- A reading ends on its reflection question, then one optional follow-up and Done.
- Optional invitations (the morning reminder) appear as an inline card after value has been delivered, with an equal-effort decline. Never as a full-screen gate.

## 7. Motion

- One orchestrated moment: the reveal. The ground warms from night to dawn (about 1.6s), a sun glow rises, and the card flips (about 1.1s). Text follows in short staggered rises.
- Entrances ease out with `cubic-bezier(.16, 1, .3, 1)` over 0.6 to 0.7s. Shuffles run 1.3 to 1.8s and can be repeated.
- Motion explains a change of state. No looping decoration other than a gentle float on the welcome card and the pulse on the active slot.
- With Reduce Motion on, every animation is removed and the final state is shown immediately.

Issue #10 uses a 1.7s shuffle: two 0.45s washes, then a 0.8s opening into the fan. Its title is “Washing the cards…” until “Pick the one that pulls at you”. All five fixed tap lanes remain live; picking during a wash cancels it and immediately shows the chosen state. A settled pick/undo uses a 0.65s ease-out lift. “Shuffle again” is a quiet action below the fan, with “Shuffling changes the order, not your card.” beneath it. It reorders only the five decorative backs; it cannot change the daily result. Choosing a different card restores the fan without replaying the wash.

Reveal flips over 1.1s, warms the whole ground over 1.6s and raises a soft ochre glow behind the card. Name, orientation and keywords rise 12 points with 80ms staggering, starting at 0.85s. The meaning action and disclaimer are present throughout; no timer advances the screen. These intermediate states use the existing card, type and colour roles, and have no separate reference. Reduce Motion and the Debug animation-off configuration draw the final fan, face, glow and all text on their first paint, without scheduling these sequences.

## 8. Words

- Plain, calm, second person. Titles are instructions or statements ("Pick the one that pulls at you"), not feature names.
- Readings reflect, they do not predict. Use "may", "tends to", "notice"; avoid promises about outcomes.
- Buttons name the result: "Turn it over", "Read my spread", "See what it means today".
- Australian/British spelling ("colour"). No emoji. No exclamation marks in interface copy.
- Suggested questions are written as questions, so they can be drawn as they are.

## 9. Accessibility floor

- Contrast as in §2. State is never shown by colour or motion alone: selected items also change fill or weight, reversed cards say so in words.
- Real buttons and links with clear labels. Face-down cards announce their position ("Card 3 of 5"); card art announces its name and orientation; decorative shapes are hidden from VoiceOver.
- 44 point targets, visible focus, Dynamic Type, Reduce Motion (§7).
- Check light appearance, large text sizes and VoiceOver order before calling a screen done. A dark-appearance variant of the dawn screens has not been designed.

## 10. Departures from the PRD

The reference screens also change the flow, not only the look. Jackie adopted them on 11 October 2026 when the canvas was merged into a single design. The PRD itself has not been amended, so where it disagrees with this table, this table is the design to follow. Building any of it still needs scope approval.

| Change | PRD position |
|---|---|
| No birth-data or about-you forms before the first card. Birth details are not collected in the first build; relationship status is asked on Ask and can be changed in Settings | Onboarding screens 2 and 3 come before the first card |
| The area detail screen is replaced by the Ask tab | Each area opens its own detail screen from the daily summary |
| A three-tab bar with Ask as its own tab | Ask is reached from an area row on the daily summary |
| The morning reminder is an inline card on Today, on day one only | A full-screen reminder ask follows the reveal |
| Composer prompts are phrased as questions | Prompts are topic phrases |

## 11. Foundation slice and states without references

Issue #7 starts directly at Draw. It implements the static fan and selection, explicit Reveal and a basic Today containing the card, name, orientation, keywords and core interpretation. Issue #10 adds shuffle/reveal motion (§7). Welcome, History, Share, Settings, tabs, Today extras and Ask are later slices; their controls are omitted rather than made inert. The unselected Draw footer now offers the shuffle action and helper (§7). The five non-overlapping tap lanes remain available when a card is selected. At standard size the two Draw states share the same disc/fan anchor; the chosen card grows and rises inside it. The title reserves the two-line instruction’s space so selecting a card does not shift the whole composition. This minimum does not cap larger text. At accessibility text sizes, Today stacks its card above its details. Every screen scrolls. The shared reading-screen layout pins its footer only at standard text sizes; at accessibility sizes it places the action and helper/disclaimer text inline after the content, so they remain reachable without taking space from the reading. Text is never capped or shrunk to fit. This rule also applies to any later screen using a pinned footer.

A storage-open failure uses dawn ground, a screen title explaining that readings could not be opened, body copy saying nothing has been replaced, and a "Try again" primary action. A save failure leaves the chosen card in place and shows a native alert explaining how to retry; it never silently switches to a temporary store or deletes saved data.

## 11a. Not yet designed

A birth-details entry form (not in the first build; Settings does not link to one), the paywall, and all empty, loading and error states. Settings and "About someone" keep their original layouts with this manifest's colours and controls applied; they have not had a full design pass. Tab icons are placeholders. When designing these, reuse the roles and components above rather than adding new ones; if a new one is truly needed, add it here in the same change.

## 12. Design check

Run this on any change that adds or alters a screen, before asking for review. Passing tests show a screen works; this shows it looks as intended.

1. **Capture.** A UI test opens each screen the change touches in the fixed test state and attaches a kept screenshot named after its reference image (`04-today`, `02-draw-card-chosen`). If the content scrolls, capture the top and the bottom.
2. **Compare.** Open the run's `design-comparison.html` (path printed by `./scripts/harness evidence`): the [design reference](design-reference/README.md) is on the left and the built screen on the right. Follow the [capture naming contract](../README.md#screenshot-names-and-design-comparison) for largest-text, Reduce Motion and bottom-of-scroll variants; these never count as the main screenshot. Check, in this order: what is on the screen and in what order; the primary action and where it sits; colour roles; typefaces and weights; card shape; spacing and alignment; wording. The references are web renderings, so small differences in text rendering are expected. Anything a person would notice at a glance is a difference.
3. **Automated checks.** The test tools' built-in accessibility audit passes on each screen touched (contrast, 44 point targets, clipped text, text scaling). A test fails if either bundled typeface falls back to the system font. A check fails if a colour, font or corner radius is written outside the design system.
4. **Large text and Reduce Motion.** Capture each screen touched at the largest text size: nothing is clipped or overlapping and the primary action can be reached. Capture Draw, Reveal and the three-card pick once with Reduce Motion on.
5. **Independent look.** Someone who did not write the code (a fresh agent session given only the two sets of images and this file, or Jackie) repeats step 2.
6. **Report.** The pull request lists, screen by screen, each difference found and whether it was fixed or accepted, with the reason. Jackie looks at the pairs before approving a merge.

A screen or state with no reference image (empty, loading and error states, confirmations) is checked against the rules in this file instead, and described here in the same change.

## Maintaining this file

Keep it to rules another agent can apply without seeing the canvas. Record a rule once, in the section it belongs to. When a design decision changes, update this file, the canvas and the affected reference image together and note the date at the top.
