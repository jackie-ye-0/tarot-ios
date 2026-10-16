# Design manifest

11 October 2026 · Adopted by Jackie as the visual and interaction direction for the tarot app. This is the single source of truth for how the app looks and behaves on screen. Follow it for any design or UI work; change the app's look by changing this file first. Updated 12 October 2026: Settings matches the build spec, and the reference images and design check (§12) were added. Updated 13 October 2026: §11 describes full Today, reopened Reveal and earlier snapshots for issue #9. Updated 14 October 2026: shuffle/reveal motion (§7), completed Reduce Motion states, local-day routing, the Today midnight footer (§11), full-deck face grammar (§5), the Ask foundation states, accessibility-size controls, keyboard behaviour and measured contrast audit rules are documented. Updated 15 October 2026: full Ask and composer states for issue #14 and the unoccluded-scroll-viewport clarification in §12 are documented.

Updated 17 October 2026: §11c describes local image sharing, its document layout and the Reveal/Reading Share controls.

**What this does not do.** It does not approve building product features. [Decisions and scope](decisions.md) still governs what may be implemented. Issue #7 implements Draw, Reveal and a basic Today; issue #9 fills Today and makes its card reopen Reveal; issue #13 adds the first complete Ask path; issue #14 adds full Ask context and composer safeguards. Other screens remain reference designs.

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
| Error / destructive | `#a3331f` | Character-limit feedback; delete only inside a menu |

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
| Career | Blue `#6f8ca2` | `#415c70` | `#dfe5ea` | `#3f596d` |
| Relationship | Clay `#b0654a` | `#88452f` | `#f0d6cb` | `#8a4a33` |
| Social | Sage `#7d8f6a` | `#4b5b3e` | `#e2e6d9` | `#4d5e3d` |

On the textured native screens, area labels use the existing **Text on tint** partners, including on ground and surface. The flatter reference label colours have too little contrast margin once the grain is rendered; the darker partners preserve the area hues and pass the 4.5:1 floor. Accent fills stay unchanged.

Ochre `#c79a3f` belongs to the cards themselves: card art, the sunrise glow, and the "card drawn" mark in the History calendar. It is not a fourth area.

### Texture

Every screen carries a fine risograph-style grain over the ground: about 16% strength multiplied on dawn screens, 10% screened on night screens. It is decoration; nothing may depend on it.

### Contrast

Text must reach at least 4.5:1 against what it sits on. Measured pairs: ink on ground 10.0, secondary on ground 5.8, placeholder 5.4, disabled label 5.2, area labels 5.7 to 5.9, cream on night 15.1, secondary on night 9.8. The area labels retain their hues but are darker than the reference labels: their previous 4.5 to 4.9 ratios left too little headroom for grain, and the reading's native contrast audit rejected the relationship heading. Re-measure any new pair before using it.

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
- **Tab bar.** Today, Ask, History. Icon plus label, always both. Surface background with a hairline above. The selected tab has an ink-filled pill with a surface-coloured icon and ink label text. This high-contrast treatment replaces the reference tint after the native accessibility audit rejected the selected tint, including with an ink outline. Shown on dawn screens at rest; hidden on ritual screens (draw, reveal, three-card pick) and in the composer and reading.
- **Area selector.** A three-part segmented control showing Career, Relationship and Social at once, 44 high segments on the control track, selected segment in surface colour. Never a single pill that cycles.
- **Chips.** 44 high, radius 22. Selected: ink fill, surface text. Unselected: surface fill, control border.
- **Text field.** Surface fill with a 1.5 ink border when it is the main entry on the screen. A single-line entry is a 60 high pill; a multi-line one uses radius 20. It must look like a field, with placeholder text and a character count where there is a limit.
- **Card back.** Card-back fill, gold outline, a thinner inner frame and a half-sun-on-horizon motif. Identical everywhere.
- **Card front.** Surface fill with an ink outline (gold outline when shown on night). Art is layered flat pastel shapes with ink linework, abstract rather than illustrative. Reversed cards are rotated 180 degrees and say "reversed" in text as well.
- **Empty slot.** Night-ground fill, dashed outline in the card shape and a gold number. The explicit fill keeps the numeral's background consistent over the ritual disc. The slot being filled has a gold outline and a slow pulse.
- **Score strip.** The three area scores sit in one row: area label, numeral, and a 6 point rounded bar in the area's accent on a neutral track. Numbers are always shown as text; the bar never carries the value alone.
- **List rows.** 60 to 76 high inside a surface group, hairline between rows, chevron at the right when the row navigates.
- **Destructive actions** live inside a More menu, never beside Share or Done.

### Full-deck face grammar (#12)

All 78 faces share the 5:8 frame, an inset flat sky, a horizon and layered sage/clay ground. The Star retains the reference's four-point star, smaller light star and flowing landscape. The other Major Arcana each have a large rank-specific geometric emblem: the Fool's cliff and travelling staff; Magician's wand and infinity; Priestess's pillars and crescent; Empress's crown and grain; Emperor's square throne; Hierophant's crossed keys; Lovers' paired forms; Chariot's canopy and wheels; Strength's lion and infinity; Hermit's lantern; Wheel's spokes; Justice's scales; Hanged Man's inverted figure; Death's cut stem and new shoot; Temperance's pouring vessels; Devil's horns and chain; Tower's broken crown and bolt; Moon's crescent and twin towers; Sun's disc and rays; Judgement's trumpet; World's wreath.

Minor Arcana use four silhouettes, never colour alone: a leafy staff for Wands, a bowl and stem for Cups, a blade and crossguard for Swords, and a five-point star within a disc for Pentacles. Aces have one large emblem. Two through Ten have that many emblems in balanced columns, with an extra central emblem for odd ranks. Ten uses smaller emblems so its five rows remain separate, including sword tips and hilts. Courts retain a large suit emblem with rank-specific framing: Page's leaf, Knight's diagonal pennant, Queen's three-point crown and curved seat, King's five-point crown and square throne. Ink outlines keep the silhouettes readable at Reveal (214-point width), Today (120), spread (84) and thumbnail (36). Small faces omit no identity-bearing marks. Names and orientation are real, scalable text beside or below the artwork, never tiny text baked into it. Major Arcana are unsuited (`nil`); their ranks run 0–21, Minor ranks 1–14 (Ace through King).

The Debug-only card proof states have no reference image. The face gallery uses dawn ground, a title, three named pairs of upright/reversed cards per page, caption-role orientation labels and one next-page action. It scrolls and moves its action inline at accessibility sizes using the shared layout. The size proof is a scrolling stack of labelled faces at the four widths above; it is test evidence, not app navigation. Both use existing typography, spacing and colour roles.

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

The persistent selection header and disclaimer use a temporary one-point glyph halo in the matching ground role while the backdrop crosses mid-tones. The night and dawn text/halo pairs switch together, preserving their contrast rather than blending text through the ground colour. The halo is absent at rest and with Reduce Motion; no settled colours or layout change. Native status-bar appearance follows the ground's change from dark to light.

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
| No birth-data or about-you forms before the first card. Birth details are not collected in the first build; relationship status is asked on Ask, with Settings editing left to its assigned ticket | Onboarding screens 2 and 3 come before the first card |
| The area detail screen is replaced by the Ask tab | Each area opens its own detail screen from the daily summary |
| A three-tab bar with Ask as its own tab | Ask is reached from an area row on the daily summary |
| The morning reminder is an inline card on Today, on day one only | A full-screen reminder ask follows the reveal |
| Composer prompts are phrased as questions | Prompts are topic phrases |

## 11. Foundation slice and states without references

Issue #7 implements the static fan and selection, explicit Reveal and a basic Today containing the card, name, orientation, keywords and core interpretation. Issue #8 adds Welcome before Draw on first open; issue #10 adds shuffle/reveal motion (§7). History and Settings are later slices; their controls are omitted rather than made inert. The unselected Draw footer now offers the shuffle action and helper (§7). The five non-overlapping tap lanes remain available when a card is selected. At standard size the two Draw states share the same disc/fan anchor; the chosen card grows and rises inside it. The title reserves the two-line instruction’s space so selecting a card does not shift the whole composition. This minimum does not cap larger text. At accessibility text sizes, Today stacks its card above its details. Every screen scrolls. The shared reading-screen layout pins its footer only at standard text sizes; at accessibility sizes it places the action and helper/disclaimer text inline after the content, so they remain reachable without taking space from the reading. Text is never capped or shrunk to fit. This rule also applies to any later screen using a pinned footer.

Welcome uses the `01-welcome` reference: Daybreak, a decorative face-down card against one disc, “One card. Every morning.”, the supporting promise, one night primary action and the full entertainment-and-reflection disclaimer. The Daybreak wordmark takes the reference's cut, Gabarito 700 at the Section title's 20 points, and the Welcome card alone carries the reference's soft shadow; the Draw card backs stay flat. The card floats six points over a three-second ease-in-out half-cycle and is still with Reduce Motion or test animations disabled. Completion is saved only when “Draw my first card” is tapped; foreground and date changes never dismiss Welcome. At accessibility text sizes its action and disclaimer follow the content inline, following the shared layout rule above. If completion cannot be saved, Welcome stays in place and a native alert explains how to retry without changing saved cards; this error state has no reference image.

Issue #9 adds the reference Today extras, score strip and three area lines in that order. Extras use a hairline above and below, three columns at ordinary sizes, and a vertical stack at accessibility sizes. Scores stay in one row at ordinary sizes; at accessibility sizes each full-width score follows the previous one so labels and numerals are never squeezed. Area lines sit in one surface group with hairline separators and no chevrons until area navigation exists. Each is one short sentence that can wrap, never a truncated single display line. Decorative expansion and back icons keep their designed size at every text size; their interactive targets remain at least 44 points. The Today thumbnail has a bottom-right expansion mark and opens Reveal. A reopened Reveal has a 44-point back chevron labelled “Back to Today”; both that control and its existing primary action return to Today. The first-draw Reveal keeps its existing header. This reopened state uses the same Reveal reference with an added back control. Older saved draws without these fields keep their original content and show a quiet caption, “This earlier draw has no saved extras or area readings.” They are never backfilled from a newer library.

A storage-open failure uses dawn ground, a screen title explaining that readings could not be opened, body copy saying nothing has been replaced, and a "Try again" primary action. Dawn content and footers share the 20-point side guide, including short error copy; night footers keep 24 points. Dawn footers reserve a 12-point clear gap above their contents, including above the keyboard. A save failure leaves the chosen card in place and shows a native alert explaining how to retry; it never silently switches to a temporary store or deletes saved data.

Issue #11 refreshes the local date at midnight, after clock/time-zone changes and on foreground return. A new undrawn date opens an unselected Draw; a date with a saved card opens Today with that snapshot. A time-zone change within the same date leaves the current ritual in place. Today ends with the quiet, non-interactive caption “Your next card arrives at midnight”, centred in secondary ink after its reading content (after the last area row when the fuller Today lands). If the new day's saved card cannot be read, a native alert explains that saved cards are unchanged and offers “Try again”.

## 11a. Ask foundation slice (#13)

Today and Ask have two labelled tabs, with the selected icon on an ink-filled pill, using a surface-coloured symbol for a high-contrast selected state. History joins in #19. Today gains the “Ask the cards” entry. Ask shows all three areas in a segmented selector, an outlined field-shaped entry and three question chips for the chosen area. The context panel, recent reading and relationship-status prompt belong to #14; the named-person entry belongs to #18. Until those slices, the shorter Ask screen leaves open ground below its suggestions.

The composer uses the same area selector, a title naming the area, the guidance line, a large surface field and suggested questions. Its footer says that three cards come next and offers “Write or pick a question” (disabled) or “Draw my three cards”. The count, limit and empty-slot preview belong to #14. The keyboard’s native Done key dismisses it; no accessory toolbar is added. A question is one paragraph: a typed Return finishes editing, and pasted line-break runs become spaces. Focusing the field scrolls it to the top so the question stays visible above the keyboard. While the keyboard is open, content remains scrollable; at the largest text size, dismissing with Done returns the full scroll area for suggestions and the inline primary action. At accessibility sizes the selector becomes three vertically arranged segments, all visible together with whole-word labels; the back button moves to its own row. Multiline primary actions, question entries and chips use the existing 22-point surface radius so the corners do not cross the text. The entry arrow grows with its symbol and retains padding.

The pick shows the question, screen-centred progress beside a separate Back target, three labelled slots and a compact version of the existing five-card fan. Its tighter visual offsets and angles leave the five full-width tap lanes unchanged. One disc stays behind both the picking and completed states. Each tap immediately fills the next slot, and filled slots are not controls. Filled cards use a gold outline, with name and orientation in text. Issue #15 adds the daily draw's two washes and fan opening before each pick, with all five targets live throughout. The quiet footer offers “Shuffle” and “Shuffling never uses up a pick.” It changes only the decorative backs. The active empty slot has a gold dashed outline with a two-second ease-in-out pulse between full and 55% outline opacity; its number and position label stay still. Reduce Motion removes both shuffle and pulse on first paint. At completion the fan gives way to “Your spread is laid” and “Read my spread”. At accessibility sizes the slots stack vertically and every action follows the scrolling content. No state uses motion alone to communicate a pick.

An unfinished spread restores through the existing Ask entry after a relaunch; the daily launch/date rule remains unchanged. Back from the pick returns to the composer with the question and drawn cards retained. Continuing the composer keeps those cards locked. Back from the composer to Ask discards the spread draft. A completed reading and draft removal are saved together. These navigation states use the same references. A draft-save failure uses a native alert explaining that the latest changes are only in memory and offering “Try again”; a failed discard retains the composer until the discard can be saved. These error states have no separate reference.

The reading shows the question, area and “Saved on this phone”, the cards and positions, three position passages, “Read together”, a surface-contrast reflection panel and Done with the disclaimer. “Saved to History” is reserved until #19 makes History available. Share is described in §11c. Close and Done return to Today. The six-card starter reading library uses the full-deck face grammar from #12; the reference’s example cards and wording are not fixed results.

Issue #16 adds the reference's “Did this land?” prompt after the reflection: Yes, Somewhat and Not really are optional chips. The selected chip uses ink fill, surface text and the selected accessibility trait; tapping it again clears the response. At accessibility sizes the choices stack vertically. A saved note follows under “Your note” in body type. The header's 44-point More control opens a native menu with “Add a note” (or “Edit note”) and Delete. Done remains the reading's only primary action. Deletion requires a native “Delete this reading?” confirmation with Cancel and Delete, explaining that the reading and its note will be removed from this phone. Only successful deletion returns to Today. Ask’s recent-reading row reopens the saved response and note immediately after an edit. Deleting that reading reveals the previous reading for its area, or omits the row when none remains, using the existing Ask layout.

The note editor has no separate reference: it uses dawn ground, a quiet Cancel action, “Your note”, a surface multiline field with an ink border and existing 20-point field radius, and a single “Save note” primary action. The empty field shows “Write a note” in the placeholder role, disappearing on input; notes have no character limit. Focusing it scrolls the field into view using the composer’s focus behaviour. The keyboard has a secondary Done dismissal capsule in reserved bottom safe-area space, with a clear gap from the field and Save note. Scrolling while editing keeps the keyboard open; Done dismisses it. The shared layout moves Save note inline at accessibility sizes, where it remains scrollable above the dismissal control. Cancel leaves the saved note unchanged; saving an empty note clears it. A failed note save keeps the entered text. Feedback, note and deletion failures use a native alert explaining that saved data is unchanged and the action can be retried. These new states use the existing type/colour roles. Neither feedback nor note editing changes the original reading's text or cards.

The save-error alert says the spread could not be saved, retains all three cards and asks the user to retry “Read my spread”. The already composed snapshot is reused on retry. A blank or whitespace-only composer uses the disabled button; a new Ask has no empty recent-reading placeholder. These states use the existing dawn/night roles and native alert. Issue #15 persists a question and its picks once the spread starts, including edits after returning to the composer. Persistence before the first submission belongs to #14.

## 11b. Full Ask and composer (#14)

Ask places today's saved area line and score in the area's tint panel below the selector, headed by the daily card's name. This uses the bundled daily line instead of inventing a second interpretation or the reference's example “Open-handed” headline. Earlier snapshots without area content omit the panel. Below the suggestions, Relationship asks “Where are you, relationship-wise?” with four full-width question chips and a 44-point “Skip” quiet action. The single column keeps every choice readable at all text sizes. The optional helper explains why answering helps. Choosing or skipping removes the prompt permanently; Settings editing belongs to its assigned ticket. A divider precedes the latest reading, when present: three small saved card faces, the original question, date and an arrow. At accessibility sizes the cards sit above the question. With no past reading, omit the entire section.

The composer has a trailing live `0 / 300` count below the field. At 300, show “Limit reached” and the count in the error role (`#a3331f`, the existing destructive hue); text and VoiceOver convey the limit as well as colour. Further insertion at the limit is rejected, pasted text is capped by whole characters, and deleting text clears the error. The footer previews three small, empty, dashed dawn card outlines beside the existing next-step explanation; at accessibility sizes the preview sits above it. Each slot has a position label for VoiceOver. No new animation is introduced.

The draft's question and area are saved on every change, restored via the Ask entry after a relaunch, and kept when the app backgrounds. Back to Ask explicitly clears the draft, as does successfully creating a reading. A native save-error alert retains the words and offers a retry of the operation that failed; after a failed Back to Ask, retry clears the draft rather than saving it again. A failed status save leaves the prompt available and explains that the choice could not be saved. These states use the existing alert and dawn roles. Pick persistence remains #15.

Reading's saved-area metadata includes its decorative area-accent dot at standard text sizes. The three response choices share the available row width equally with centred labels at standard sizes; at accessibility sizes they keep the existing vertical stack.

## 11c. Sharing (#23)

Reveal adds the reference's trailing surface pill with the share symbol and “Share”; the reading header adds a share symbol in a 44-point tap target immediately before More. At accessibility text sizes, Reveal's selection text occupies its own row below the back/share controls so both remain readable. Share opens the native system share sheet above the current screen; dismissing it preserves the screen and its reading. A render failure uses a native alert with “Try again” and Cancel and does not change saved data.

Shared images have no separate reference. They use textured dawn ground, existing card faces, ink and secondary ink, Gabarito headings and Hanken Grotesk body/caption roles. The card image centres a 214-point face above its display name, orientation and “For entertainment and reflection”. The reading image shows the question, area, three labelled cards, all three position passages, “Read together”, the reflection panel and “For entertainment and reflection, not a prediction”, in that order. It shares the original reading, leaving the optional personal note and response on the phone. Both are PNG images with 20-point side margins and 28-point vertical margins. They are rendered at a 390-point document width and standard text scale, at double resolution, with natural height and no scrolling container or text truncation. Device text size changes the accessible screen controls, not the portable image's typesetting. There are no navigation controls in either image. The native share sheet retains system styling and system text scaling. Its preview uses the rendered image and a descriptive title: card name and orientation, or the reading’s area followed by “reading”. This preview is supplied locally, without fetching metadata. Native-sheet largest-text evidence uses the simulator’s actual largest accessibility text setting, rather than only the app’s Debug text-size override; the test restores the reference suite’s standard system text setting afterwards.

## 11d. Not yet designed

A birth-details entry form (not in the first build; Settings does not link to one), the paywall, and all empty, loading and error states. Settings and "About someone" keep their original layouts with this manifest's colours and controls applied; they have not had a full design pass. Tab icons are placeholders. When designing these, reuse the roles and components above rather than adding new ones; if a new one is truly needed, add it here in the same change.

## 12. Design check

Run this on any change that adds or alters a screen, before asking for review. Passing tests show a screen works; this shows it looks as intended.

1. **Capture.** A UI test opens each screen the change touches in the fixed test state and attaches a kept screenshot named after its reference image (`04-today`, `02-draw-card-chosen`). If the content scrolls, capture the top and the bottom.
2. **Compare.** Open the run's `design-comparison.html` (path printed by `./scripts/harness evidence`): the [design reference](design-reference/README.md) is on the left and the built screen on the right. Follow the [capture naming contract](../README.md#screenshot-names-and-design-comparison) for largest-text, Reduce Motion and bottom-of-scroll variants; these never count as the main screenshot. Check, in this order: what is on the screen and in what order; the primary action and where it sits; colour roles; typefaces and weights; card shape; spacing and alignment; wording. The references are web renderings, so small differences in text rendering are expected. Anything a person would notice at a glance is a difference.
3. **Automated checks.** Every accessibility audit category remains enabled and strict on each touched screen, including contrast, text detection, hit regions, clipped text and scaling. Run each category once per stop in this order: element detection, contrast, hit regions, sufficient element description, traits, text clipping, then Dynamic Type. The last two categories can disturb layout. Retain pre-resizing query frames for coverage and reading-scroll decisions, and wait for stable frames before navigating; do not use a post-resizing frame to choose the next gesture. Audit fixtures disable root animations with the existing Debug Reduce Motion switch and wait for expected elements to exist with unchanged frames across two reads. Debug test mode exposes the scroll layout’s actual safe-area viewport; scrolling content is bounded by the unoccluded scroll viewport, while actual pinned-footer descendants use the footer intersected with the safe area. Off-screen or partly clipped contrast issues are deferred and must be audited fully visible at another stop, or the test fails. A built-in contrast flag on a fully visible plain static-text element with no non-text descendants may be dismissed only when that element’s own screenshot measures at least 4.5:1 using WCAG relative luminance; every such dismissal records its identifier, label, image and measured ratio in kept evidence. The measurement self-checks known approximately 10:1 and 3:1 pairs, and no other audit category is dismissed. Per-screen checks compare every fully visible string at a representative scroll stop with its exposed accessibility label and retain the hierarchy, including below-the-fold content. Bundled typefaces must pass family/PostScript-name checks, and a check fails if a colour, font or corner radius is written outside the design system.
4. **Large text and Reduce Motion.** Capture each screen touched at the largest text size: nothing is clipped or overlapping and the primary action can be reached. Capture Draw, Reveal and the three-card pick once with Reduce Motion on.
5. **Independent look.** Someone who did not write the code (a fresh agent session given only the two sets of images and this file, or Jackie) repeats step 2.
6. **Report.** The pull request lists, screen by screen, each difference found and whether it was fixed or accepted, with the reason. Jackie looks at the pairs before approving a merge.

A screen or state with no reference image (empty, loading and error states, confirmations) is checked against the rules in this file instead, and described here in the same change.

## Maintaining this file

Keep it to rules another agent can apply without seeing the canvas. Record a rule once, in the section it belongs to. When a design decision changes, update this file, the canvas and the affected reference image together and note the date at the top.
