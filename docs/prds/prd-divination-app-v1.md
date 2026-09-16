# PRD — Divination App (Tarot V1)

> Version: V0.1
> Date: 2026-09-09
> Author: zoe.zhang@acorn.works
> Related: No Problem Framing / SRD exists — key conclusions from those layers are summarized inline in §2 and §5.

---

## Contents

| § | Section |
|---|---------|
| [1](#1-revision-history) | Revision History |
| [2](#2-background) | Background — the problem, the three areas, why V1 is free |
| [3](#3-summary) | Summary — platform, screens, metric, monetization |
| [4.0](#40-user-flow-overview) | User Flow Overview |
| [4.1](#41-frontend-requirements) | Frontend Requirements — 13 screens, §4.1.1–4.1.13 |
| [4.2](#42-data--business-logic) | Data / Business Logic — §4.2.1–4.2.14 |
| [4.3](#43-cms--admin-requirements) | CMS / Admin Requirements |
| [4.4](#44-backend--api-requirements) | Backend / API Requirements |
| [4.5](#45-localization) | Localization (not activated in V1) |
| [5](#5-data-requirements) | Data Requirements — analytics, A/B, business target |
| [6](#6-non-functional-requirements) | Non-Functional — performance, fallback, ADA, security |
| [7](#7-launch-strategy) | Launch Strategy |
| [8](#8-phasing) | Phasing — V1 · V1.5 · V2 |
| [9](#9-open-risks) | Open Risks |
| [10](#10-visual-direction) | Visual Direction — Soft Dawn |
| [11](#11-decision-record) | **Decision Record** — settled positions and open questions |
| [12](#12-responsibility-matrix) | Responsibility Matrix |

**Screen index (§4.1):** 1 intro · 2 birth data · 3 about you · 4 shuffle & pick · 5 card reveal · 6 daily summary · 7 area detail · 8 question composer · 9 three-card pick · 10 relationship input · 11 reading detail · 12 history · 13 paywall *(built, unreachable)*

---

## 1. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| V0.8 | 2026-09-09 | zoe.zhang@acorn.works | **Structural pass, no scope change.** §4.1 split from one 230-line block into 13 numbered per-screen sections, each with its own acceptance criteria — several criteria had drifted onto the wrong screen, and the shuffle-and-pick screen had none of its own. §4.2.11–14 reordered into sequence. §4.2.4 retitled *Area scores*. Stale paywall criteria removed from the composer. Added a Contents and a **Decision Record** (§11) consolidating settled positions and open questions. Confirmed the three-card pick covers **all three areas** (§4.1.9, §4.2.11). |
| V0.7 | 2026-09-09 | zoe.zhang@acorn.works | Deep readings now involve **three separate card picks**, one per spread position, with shuffling allowed before each (§4.1.9, §4.2.11). Unlike the daily card, these picks **genuinely determine** the cards drawn. Flags a new abandonment point between question and reading (§9). |
| V0.6 | 2026-09-09 | zoe.zhang@acorn.works | Added a full-screen **card reveal** between the pick and the daily summary (§4.1.5) — the turned card gets its own beat rather than appearing inside a panel stack. The same screen doubles as a card detail view, reopened by tapping the card art on the summary, and is the primary share surface. |
| V0.5 | 2026-09-09 | zoe.zhang@acorn.works | Home split into two screens: **shuffle & pick**, then a **daily summary** which is the landing screen once the day's card is drawn (§4.1.6). Added a shuffle sequence before the pick, with a Reduce Motion path (§4.1.4, §6.3). **Reverted the V0.4 merge** — the area score panel returns as its own block, separate from the per-area suggestion rows. Daily extras promoted onto the summary alongside per-area suggestions (§4.2.12). |
| V0.4 | 2026-09-09 | zoe.zhang@acorn.works | **Single-focus selection removed.** Home shows all three areas at once; onboarding instead offers a multi-select with all three pre-checked (§4.2.9). Onboarding reordered to birth data first, then about-you, and reduced to two screens; relationship status is now **optional** (§4.1.3). Added **daily extras** — colour, object, best hour — authored in the library, so the daily card needs no LLM call (§4.2.12). Returning users open directly on the card pick (§4.2.13). Three-card draw recorded as a V2 candidate with a naming constraint (§8). |
| V0.3 | 2026-09-09 | zoe.zhang@acorn.works | **Everything free at launch** — subscription and paywall are built but ship disabled behind a feature flag (§4.2.8). Daily draw becomes a **five-card pick** (§4.2.2). Onboarding adds gender (optional) and relationship status (required), grouped onto one screen (§4.1.3). The three area lenses are redefined: Career is advisory about work, Relationship concerns the user's own relationship, Social concerns **how the people around them treat them** (§4.2.5). Added an LLM cost guard (§4.2.14), now that generation is unmonetized. |
| V0.2 | 2026-09-09 | zoe.zhang@acorn.works | Restructured around three focus areas (Career / Relationship / Social). Fortune scores reduced from four dimensions to three, matching the areas. Focus-area selection added to onboarding. Home entry points replaced: the cold "Analyse a relationship" CTA is removed in favour of three always-visible area cards. Relationship reading is now reached from inside the Relationship area. Visual direction settled (see §10). |
| V0.1 | 2026-09-09 | zoe.zhang@acorn.works | Initial draft |

---

## 2. Background

The tarot and astrology app category is crowded but shallow. Existing apps serve the same pre-written interpretation to every user, so readings stop feeling credible after a few sessions — the text is visibly not about you. Users churn not because they lose interest in divination, but because the product runs out of things to say.

This product's wedge is a **hybrid interpretation engine**: a curated content library supplies canonical meanings for every card, and an AI layer stitches those meanings into a narrative around the individual user's question and context. Personalization becomes real rather than cosmetic, while the library keeps the AI grounded and prevents invented card meanings.

**The product is organized around three life areas: Career, Relationship, and Social.** These are not a content taxonomy bolted on top — they are the spine. All three are present on the daily card: three scores, and a one-line read of today's card through each area's lens. Deep readings are entered through the areas, and History is filterable by them.

**There is no single "focus" the user must choose.** V0.2 and V0.3 asked for one at onboarding. That was removed in V0.4: Home displays all three areas anyway, so forcing a choice upfront hid two-thirds of the product behind a question asked before the user knew what they were choosing between. Onboarding now offers a multi-select with all three pre-checked (§4.2.9) — a screen most users pass through untouched, which still captures a real signal from the minority who remove one.

The three lenses, precisely:

- **Career** — advisory about the user's work. Practical suggestions, decisions, timing, what to do on a given day.
- **Relationship** — the user's own romantic relationship, or their lack of one. This is why relationship status is collected at onboarding (§4.1.3): dating and searching is a different reading from navigating something that already exists.
- **Social** — **how the people around the user treat them.** Not how the user performs socially, but what they receive: whether they're seen, included, taken seriously, given the same care they give. This is the area least served by any competitor.

**V1 is free.** Everything above — all three daily areas, all deep readings, relationship readings, and full history — is free at launch. The subscription and paywall are built, but ship disabled behind a feature flag (§4.2.8). V1 exists to answer whether people come back; a paywall in that funnel only adds friction to the thing being measured.

V1 covers **tarot only** — daily recommendation, and deep readings within the three areas. Astrology (natal chart 一生 + annual forecast 流年 + synastry 合盘) is deliberately deferred to V2 because it requires an ephemeris calculation engine, the single heaviest piece of engineering in the roadmap. Shipping tarot first tests the core retention bet cheaply, before that investment is committed. See §8 for phasing.

---

## 3. Summary

| Item | Content |
|------|---------|
| Related requirement | — (this is the originating document) |
| Design files | > ⚠️ TBD — no Figma files yet |
| Platform | **iOS native** (V1 only; no Android / web / Mini Program) |
| Language | **English** only (US / global market). No i18n in V1 — see §4.5 note |
| Screens | Onboarding (birth data · about you), Home — shuffle & pick, Card reveal, Home — daily summary, Area detail, Question composer, Three-card pick, Reading detail, Relationship input, History, Settings. Paywall built but unreachable in V1 |
| Areas | **Career · Relationship · Social** — the organizing spine (§4.0), all three shown together |
| Launch screen | Onboarded users open **directly on the card pick** (§4.2.13) |
| Core function | A daily tarot ritual reading today's card through all three areas, plus deeper readings within each |
| Target user | Curious casual users — treat divination as entertainment and light self-reflection |
| Monetization | **None at launch.** Everything free; subscription built and flag-disabled (§4.2.8). Placeholder pricing retained for the dark paywall |
| Primary metric | D7 / D30 retention |

---

## 4. Product Requirements

### 4.0 User Flow Overview

V1 is a cross-page funnel: a low-friction daily habit loop, with a conversion path branching off it at the moment of highest intent.

**Primary loop (free, daily):**
`Push notification → Home (card pick) → pick one of five → view core read, three area lines + scores, and today's extras → (optional) save note → exit`

**Deep path (also free in V1):**
`Home → tap an area card (Career / Relationship / Social) → Area detail → composer → reading generated → saved to History`

**There is no gate anywhere in V1.** Nothing in the shipped funnel mentions price, locks, or subscription. The paywall exists in the codebase for V1.5 (§4.2.8) and is unreachable. See §11 for how this position was arrived at.

| Flow node | Screen | User action | Key metric | Branch condition |
|-----------|--------|-------------|-----------|------------------|
| 1. First open | Onboarding | Accepts intro | Intro completion | — |
| 2. Birth data | Onboarding | Enters birth date / time / place | Per-step drop-off | Skips birth time or place → proceed with partial profile (§4.2.7) |
| 3. About you | Onboarding | Confirms areas (pre-checked); optionally status and gender | Per-field completion | All three fields skippable or pre-filled — this screen can be passed through with one tap |
| 4. Shuffle | Home — pick | Watches the shuffle, or taps through it | `pick_during_shuffle`, `shuffle_replayed` | Reduce Motion → fan is immediately tappable |
| 5. First pick | Home — pick | **Picks one of five face-down cards**, then "Turn it over" | First-draw completion | Already drawn today → opens on the summary, fan unreachable |
| 6. Reveal | Card reveal | Sits with the turned card, advances when ready | `reveal_dwell_ms`, `reveal_shared` | Never auto-advances. Reopenable later from the summary |
| 7. Daily read | Home — summary | Reads core interpretation, extras, area scores, per-area suggestions | Daily card open rate | Free, and needs no LLM call (§4.2.12) |
| 8. Area intent | Area detail | Taps a suggestion row — Career / Relationship / Social | **Area entry rate, by area** | Relationship area → also offers "about someone specific" (§4.1.7) |
| 9. Deep intent | Question composer | Types a question, submits | Composer submit rate | Free. Cost guard may throttle at extreme volume (§4.2.14) |
| 10. Draw the spread | Three-card pick | Shuffles and picks three cards, one per position | **`spread_abandoned{picks_made}`** | New abandonment point — see §9 |
| 11. Deep reading | Reading detail | Reads AI reading | Readings per user, by area | LLM failure → library-only fallback (§6.2) |
| 12. Return | History | Browses past readings, filters by area | History revisit rate | Empty state on first visit (§4.1.12) |
| 13. Next day | Push → Home | Returns for new card | **D7 / D30 retention** | Notification disabled → no re-entry trigger |

**Cross-screen data passing:**

- Onboarding → Home: `active_areas` (a non-empty subset of the three, defaulting to all three) — used immediately by V1 — plus `relationship_status` (optional), `gender` (optional), and `user_profile` (birth date, birth time?, birth place?), stored for V2 chart calculation
- Home → Area detail: `area`, plus the day's `reading_id` for context continuity
- Home → Reading detail: `reading_id`, `card_id`, `orientation`, `date_key`
- Area detail → Composer: `area` — every deep reading carries its area, which selects the prompt lens (§4.2.5) and tags the reading for History filtering
- Composer → Three-card pick: `area`, `question`. Both must survive the three pick rounds and app backgrounding — a user who leaves mid-spread returns to their question and the picks already made (§4.1.9)
- Composer → Reading detail: `area`, `question`. The draft must survive app backgrounding, so a user interrupted mid-question does not lose it
- Any reading → History: `reading_id`, `area` (readings are persisted at generation time, not on exit, so an app kill mid-read does not lose the reading)

---

### 4.1 Frontend Requirements

Platform is **iOS native only** in V1 (§3). There are no PC, Android, or H5 variants, so no cross-platform difference table applies. Each screen below is specified with its own acceptance criteria.

Screen order follows the two rituals: onboarding (§4.1.1–4.1.3), the morning ritual (§4.1.4–4.1.6), and the deep-reading ritual (§4.1.7–4.1.11).

#### 4.1.1 Onboarding — intro

- 3 intro screens: what the app is, how the daily ritual works, and the entertainment-purpose disclaimer (required for App Store review — §6.5)
- Notification permission is **not** requested here. It appears after the first card is drawn (§4.1.5) — asking before delivering value depresses opt-in, and the daily push is the primary retention lever

**Acceptance criteria:**
- [ ] The entertainment-purpose disclaimer is shown at least once before the first reading and is re-accessible from Settings
- [ ] No notification permission prompt appears during onboarding

#### 4.1.2 Onboarding — birth data

Step 1 of 2.

- Birth date (date picker, **required**)
- Birth time (time picker, optional, with an explicit **"I don't know my birth time"** affordance — a real button, not fine print)
- Birth place (city search with autocomplete, optional)
- Copy must explain *why* this is collected, since V1 does not use it: "This unlocks your full birth chart when astrology launches."

> ⚠️ **None of these three fields is used by V1.** This is a known, accepted cost (§9), and the §5.2 A/B test exists to quantify it. The standing recommendation is to defer all three to V2.

**Acceptance criteria:**
- [ ] Birth date is required; Continue is disabled until a date is selected
- [ ] Tapping "I don't know my birth time" proceeds and stores `birth_time = null`
- [ ] Birth place accepts free text; if no city is resolved, Continue is still enabled and stores `birth_place = null`
- [ ] Every V1 feature functions with `birth_time` and `birth_place` both null (§4.2.7)

#### 4.1.3 Onboarding — about you

Step 2 of 2. Three groups, **none of them blocking** — the screen can be completed with a single Continue tap.

- **Areas** — multi-select, **all three pre-checked**: "Which of these matter to you?" Deselecting one keeps it off Home; at least one must remain. Most users pass this through untouched, which is the point: it captures a signal from the minority who deselect without taxing everyone else (§4.2.9)
- **Relationship status** — optional: Single / In a relationship / It's complicated / Prefer not to say. Selects the Relationship lens variant (§4.2.5). The screen must state what answering buys, since skipping yields the vaguest variant
- **Gender** — optional: Woman / Man / Non-binary / Prefer not to say. Four options rather than two: this is an English-language US launch, and a two-option field both excludes real users and reliably draws App Store review comments in this category. Used only for pronoun choice; no reading content is gated on it

**Acceptance criteria:**
- [ ] All three areas are pre-selected on first appearance
- [ ] Continue is enabled on arrival — nothing on this screen is required
- [ ] The last remaining area cannot be deselected
- [ ] A deselected area is absent from the daily summary and cannot be entered (§4.2.9)
- [ ] Relationship status can be skipped, storing `null`, without blocking Continue
- [ ] Gender can be skipped, storing `null`, without blocking Continue
- [ ] With `gender = null`, reading text uses they/them and no reading fails to generate
- [ ] With `relationship_status` null or `prefer_not_to_say`, Relationship readings generate in status-neutral framing

#### 4.1.4 Home — shuffle & pick

The landing screen every morning before the day's card is drawn (§4.2.13). Nothing sits in front of it.

- **Shuffle sequence on entry.** The cards arrive stacked and are visibly washed before settling into the fan. Roughly 1.5–2 seconds, and it must never block interaction: a user who taps mid-shuffle picks a card and the sequence resolves immediately
- Implemented as **native or Lottie animation, not a video file.** A video cannot respond to Reduce Motion, adds bundle weight, and cannot be interrupted by an early tap
- Caption crossfades with the motion: "Washing the cards…" → "Pick the one that pulls at you"
- **Five face-down cards**, fanned, each individually tappable. Tap regions at least 44pt wide despite the overlap
- A **"shuffle again"** affordance is available before a pick. It re-runs the animation only. Copy must state that it does not change the card — "shuffling changes the order, not your card" — or a replay reads as a reroll and undoes the once-a-day integrity in §4.2.2
- The pick is **ceremonial**: the day's card is resolved before the pick (§4.2.2), and any of the five positions reveals it. The chosen position is recorded for analytics only
- The chosen card lifts, the other four fade back, and "Turn it over" advances to the card reveal
- **Reduce Motion:** no riffle or rotation; the five cards cross-fade into place and the fan is tappable on first paint (§6.3)

**Acceptance criteria:**
- [ ] When no card has been drawn for the current local date, the shuffle plays and five face-down cards become independently tappable
- [ ] Tapping during the shuffle registers a pick and resolves the animation immediately
- [ ] "Shuffle again" replays the animation and does not change the resulting card
- [ ] Each of the five tap regions is at least 44pt wide
- [ ] Tapping any of the five positions reveals the same card for a given user and date
- [ ] The chosen position index (1–5) is recorded with the draw event
- [ ] When a card has already been drawn for the current local date, this screen is not reachable and the app opens on the daily summary
- [ ] With Reduce Motion on, no riffle or rotation plays and the fan is tappable on first paint

#### 4.1.5 Card reveal

A full-screen beat between the pick and the summary. Its whole job is to let the card land before anything is asked of the user.

- The card occupies most of the screen — substantially larger than anywhere else in the app
- Entry: the card **flips from back to front** in place (~1s), then name, orientation and keywords fade in behind it
- Content is deliberately sparse: card art, name, orientation, arcana label, 3–4 keywords, and which position was picked. **No interpretation text** — that is the summary's job, and putting it here collapses the two screens back into one
- Advancing is **user-initiated, never a timeout**
- **This screen doubles as the card detail view.** Tapping the card art on the daily summary reopens it, so the largest view of the card is not visible once and then unreachable
- It is the **primary share surface** — a card at full size with its name makes a better share image than a panel stack. Share must include the entertainment-purpose disclaimer
- **Notification permission is requested once, after this screen is first reached** (§4.1.1)
- **Reduce Motion:** the card cross-fades in at final orientation, all content present on first paint (§6.3)

**Acceptance criteria:**
- [ ] The reveal appears after "Turn it over" and before the summary, every time a card is drawn
- [ ] Advancing requires a user action; the screen never auto-advances on a timer
- [ ] No interpretation or advice text appears on this screen
- [ ] Tapping the card art on the daily summary reopens this view at any point in the day
- [ ] Share produces an image containing the card art, name, and the disclaimer
- [ ] Notification permission is requested only after this screen has been reached at least once
- [ ] With Reduce Motion on, no flip or rotation plays and all content is present on first paint

#### 4.1.6 Home — daily summary

The screen a user lands on for the rest of the day once the card is drawn (§4.2.13). It is the app's home, not a result page — someone opening at 9pm sees this, not a spent draw screen.

Content, in order:

1. **The drawn card** — art, name, orientation, arcana label. **Tapping the art reopens the card reveal** (§4.1.5)
2. **Core interpretation** — 2–3 sentences, area-neutral
3. **Today's extras** — colour, object, best hour (§4.2.12), as a distinct panel, above the fold
4. **Area scores** — a dedicated panel showing every active area's score for today
5. **Per-area suggestions** — one row per active area: its one-line read through that area's lens, and the tap target into Area detail
6. **History entry point**

- Items 4 and 5 are **separate components** covering the same areas on purpose: the panel answers "how is today", the rows answer "what should I do about it"
- Only `active_areas` appear, in items 4 and 5 both (§4.2.9)
- All content is read from the content library. **No LLM call is made** (§4.2.12)
- Revisiting shows the same card and values, with no draw affordance
- The screen scrolls; items 1–3 must clear the fold on a 390×844 viewport
- Nothing on it carries a price, lock icon, or subscription language

**Acceptance criteria:**
- [ ] The scores panel lists every active area with a value between 0 and 100
- [ ] One suggestion row appears per active area, each with a one-line read and a tap target into Area detail
- [ ] The one-line reads differ from one another for the same card
- [ ] Today's extras render a colour, an object and an hour for every card and orientation, and clear the fold
- [ ] Tapping the card art opens the card reveal (§4.1.5)
- [ ] A deselected area appears in neither the scores panel nor the suggestion rows
- [ ] The screen renders fully with no network request beyond the cached content library
- [ ] Force-quitting and reopening on the same day shows the identical card, orientation, interpretation, scores and extras
- [ ] Reinstalling and signing back in on the same day shows the identical card, scores and extras
- [ ] With all three areas active, items 1–3 are visible without scrolling on a 390×844 viewport
- [ ] No paywall, price or lock affordance appears anywhere on this screen

#### 4.1.7 Area detail

Reached by tapping a suggestion row on the summary. Its job is to give the area a reason to exist beyond a button, and to collect intent.

- Header: area name, today's score for that area, and how the day's card reads *through* that area's lens
- Prompt suggestion chips specific to the area, 3–4 of them. Career: "a decision I keep circling", "asking for more", "whether to move on". Relationship: "where this is going", "a conversation I'm avoiding". Social: "an event I'm dreading", "speaking up in a group"
- Primary action: "Ask about this" → Question composer, carrying `area`
- **Relationship area only:** an additional "About someone specific" entry → Relationship input (§4.1.10)
- If the user has past readings in this area, show the most recent, openable

**Acceptance criteria:**
- [ ] Each of the three areas renders its own suggestion chips; no chip text is shared across areas
- [ ] The "About someone specific" entry appears only in the Relationship area
- [ ] Past readings in this area are listed and openable
- [ ] No paywall, price or lock affordance appears on this screen

#### 4.1.8 Question composer

- Always entered with an `area` already set — the header names it ("About your career")
- Free-text input, 300 character limit with live counter
- Suggestion chips carried through from the area (§4.1.7), so the user can submit without typing
- The area can be changed from the header, which swaps the chips and the prompt lens without losing typed text
- **Submit does not generate a reading.** It advances to the three-card pick (§4.1.9), previewing the three empty positions so the user knows what is coming
- When the paywall flag is on (§4.2.8), the gate appears **on submit, before the picks** — never after. Asking someone to draw three cards and then charging them is a bait

**Acceptance criteria:**
- [ ] The screen cannot be reached without an `area` set
- [ ] Submit is disabled when input is empty or whitespace-only
- [ ] Tapping a suggestion chip populates the input and enables Submit
- [ ] Changing the area preserves any typed text
- [ ] At 300 characters further input is rejected and the counter renders in an error state
- [ ] Submit advances to the three-card pick and generates nothing
- [ ] Backgrounding the app and returning restores the typed question
- [ ] With the paywall flag off, no price, lock or subscription language appears on this screen

#### 4.1.9 Three-card pick

Reached from the question composer (§4.1.8) and from the relationship input (§4.1.10). **Every deep reading in every area uses this screen** — Career, Relationship and Social alike. The user draws their own spread rather than being handed one.

- Three position slots are shown **from the start**, labelled and in order, so the user always knows how many draws remain and what each is for. Three rounds with no visible end is where people quit
- **Position labels by reading type:**

| Reading | Position 1 | Position 2 | Position 3 |
|---------|-----------|-----------|-----------|
| Career question | Situation | Action | Outcome |
| Relationship question | Situation | Action | Outcome |
| Social question | Situation | Action | Outcome |
| Relationship — named person | You | Them | The Connection |

  > **Proposal, not yet decided:** per-area position sets instead of one shared triple — Relationship as *Where you are / What's unsaid / Where it leads*, Social as *How you're read / What you're missing / What would shift it*. This would differentiate the areas as sharply as their lenses already are (§4.2.5), at the cost of authoring three more position sets (78 × 2 × 6 additional units). Defaulting to Situation / Action / Outcome for all three until decided, since it is the standard tarot three-card spread and works for any question.

- Five face-down cards per round, washed with the same motion as the daily pick (§4.1.4)
- **One pick per position, three rounds.** Each pick fills the current slot, reveals that card, and the deck reshuffles for the next round
- A **shuffle affordance before every pick**, not just the first. Shuffling never consumes a pick
- A card already drawn in this spread **cannot appear again** in it — the deck is drawn from, not sampled with replacement
- A filled position is **locked**. No re-picking one the user dislikes — the same integrity rule as the daily no-redraw (§4.2.2)
- The user's question stays visible throughout. Three rounds is long enough to forget what you asked
- After the third pick, one action generates the reading
- **Reduce Motion:** no riffle; cards cross-fade and are tappable on first paint (§6.3)

**Acceptance criteria:**
- [ ] All three position slots and their labels are visible before the first pick
- [ ] Position labels match the reading type per the table above
- [ ] The flow is identical for Career, Relationship and Social questions
- [ ] Exactly three picks are required, one per position, filling in order
- [ ] The same card cannot be drawn twice within one spread
- [ ] A filled position cannot be re-picked
- [ ] Shuffle is available before each of the three picks and does not consume a pick
- [ ] The user's question remains visible through all three rounds
- [ ] Generation starts only after the third pick
- [ ] Abandoning mid-pick preserves the question and the picks already made
- [ ] With Reduce Motion on, no riffle plays and the fan is tappable on first paint

#### 4.1.10 Relationship input

Reached only from inside the Relationship area (§4.1.7), never from the summary. The user has already chosen to think about relationships before being asked to name anyone.

- Inputs: the other person's name or label (**required**), and relationship type (partner / crush / ex / family / friend / colleague, **required**)
- An optional free-text field for anything specific
- Advances to the three-card pick (§4.1.9) with the **You / Them / The Connection** positions
- V1 uses the **tarot** relationship spread only. **No birth data is requested for the other person** — stated up front on the screen. This is intentional, and becomes the fallback path in V2 when synastry birth data is unavailable (§8)

**Acceptance criteria:**
- [ ] This screen is unreachable from the daily summary; the only entry point is the Relationship area
- [ ] Name/label is required; relationship type defaults to unselected and is required
- [ ] No birth data is requested for the other person anywhere in this flow
- [ ] The screen states that no birth details are needed
- [ ] The generated reading references the supplied name/label at least once

#### 4.1.11 Reading detail

- Streaming text render, so the first words appear before generation completes
- Card art, position labels, and per-position meanings
- Ends on a reflective prompt rather than a verdict (§4.2.6)
- An optional "did this land?" response, feeding `resonance_prompt_answered` (§5.1)
- Actions: save note, share as image, delete
- Crisis-routing interstitial replaces the reading entirely when triggered (§4.2.6)

**Acceptance criteria:**
- [ ] Reading text renders incrementally rather than appearing only on completion
- [ ] A loading state is shown from the third pick until the first token arrives
- [ ] Share produces an image containing the card art and reading, with the disclaimer included
- [ ] Delete removes the reading from History and requires a confirmation step
- [ ] When crisis routing fires, no card interpretation is delivered and crisis resources are shown instead

#### 4.1.12 History

- Calendar view of daily cards plus a chronological list of all readings
- Filterable by **area** (Career / Relationship / Social) and by type (daily / question / relationship)
- Empty state before any reading exists, naming the payoff that accrues over time rather than apologising
- Tapping any entry opens the original reading unchanged

**Acceptance criteria:**
- [ ] Every daily card and every reading appears in History immediately after generation
- [ ] A past reading opens with its original text, cards and scores — never regenerated
- [ ] The calendar visually distinguishes days with a drawn card from days without
- [ ] Area filters return only readings tagged with that area
- [ ] Empty state renders when the user has zero readings
- [ ] History remains fully readable regardless of entitlement state (§4.2.8)

#### 4.1.13 Paywall — built, unreachable in V1

> **Everything is free at launch** (§4.2.8). This screen ships behind a disabled feature flag so monetization can be switched on in V1.5 without an App Store release. It is specified because it is being built, not because users will see it.

- Presents subscription options and names exactly what unlocks: deep readings across all three areas, plus readings about a named person
- Must state that the daily card, scores and extras remain free
- When enabled, reached only from the composer on submit (§4.1.8) — never from the summary or Area detail
- Price placeholder **$9.99/month** — must be confirmed before the flag is ever enabled (§5.3)
- Restore Purchases required (App Store rule)

**Acceptance criteria:**
- [ ] With the flag off, this screen is unreachable from every V1 entry point, and no price, lock or subscription language appears anywhere in the app
- [ ] With the flag on, the full purchase flow works without an app update
- [ ] Restore Purchases is present and functional
- [ ] Subscription terms, price, renewal period and cancellation policy are displayed before purchase
- [ ] After a successful purchase the user returns to their pending reading and the flow continues
- [ ] Entitlement persists across reinstall via Restore Purchases

---

### 4.2 Data / Business Logic

#### 4.2.1 Deck model

- 78-card Rider–Waite-structure deck; each card exists in **upright** and **reversed** orientation
- Per card, the content library stores: name, arcana/suit, art asset, keywords, upright meaning, reversed meaning, and per-position meaning variants for the three spread positions in use
- Total authored interpretation units: 78 × 2 orientations × (1 daily + 3 question positions + 3 relationship positions) = **1,092 units**
- **Deep-reading position meanings are NOT authored per area.** Area framing for deep readings is applied by the AI layer through three prompt lenses (§4.2.5). Authoring those per area would take the library past 3,000 units for no quality gain the grounded engine cannot deliver
- **The daily card IS authored per area**, and deliberately so. Three one-line reads per card per orientation (78 × 2 × 3 = 468 units) is the price of a daily screen that needs no LLM call — and the daily screen is the one every user hits every day. See §4.2.12
- **Authoring totals:** 936 deep-reading position units + 468 daily area lines = **1,404 interpretation units**, plus 468 area score values (§4.2.4) and 468 extras values (§4.2.12)

#### 4.2.2 Daily card selection — deterministic

- Selection is **server-authoritative** and deterministic: `seed = hash(user_id + date_key)`, mapped to a card index (0–77) and an orientation bit
- The same user on the same `date_key` always resolves to the same card and orientation, on any device, after any reinstall
- **The five-card pick does not enter the seed.** The card is resolved before the user picks, which is what allows it to be computed server-side ahead of time — so the morning push notification can be composed with knowledge of the card, and the reveal needs no network round trip
- **This is a deliberate small fiction, and it is recorded as one.** An alternative was considered where the chosen position feeds the seed (`hash(user_id + date_key + position)`), making the choice genuinely determinative while preserving every other property. It was not chosen. If user research ever suggests the pick feels hollow, switching is a backend change with no UI impact
- **No redraw.** There is no purchasable or ad-gated reroll in V1 — the locked card is what makes the daily return meaningful
- Repeat avoidance: a card drawn within the previous **14 days** is re-rolled with a salted seed, up to 3 attempts, then accepted. (Proposed rule — confirm; without it, users will see repeats often enough to notice)

#### 4.2.3 Date key and reset

- `date_key` is the user's **local calendar date**, derived from device timezone
- Reset occurs at **local midnight**
- Once a card is drawn for a `date_key`, that assignment is persisted and **never recomputed** — a user who changes timezone does not lose or regenerate an already-drawn card
- Edge case: a user crossing a date line forward may reach a new `date_key` in under 24 hours, and will get a new card. Accepted as-is in V1

#### 4.2.4 Area scores — deterministic

- Each card stores an authored score set per orientation: `{career, relationship, social}`, each an integer 0–100
- **Three dimensions, matching the three areas exactly.** V0.1 specified four (Love / Work / Money / Luck); Money and Luck are removed. They were the two least actionable dimensions, they had no corresponding reading area — users would have asked why Money is scored but cannot be asked about — and the mismatch would have read as sloppy
- Scores are **read from the library, not generated** — the same card always yields the same numbers, which matters as soon as users screenshot and compare
- Reversed score sets are authored explicitly. They may be seeded from the upright set via `100 − x` during content production, but the stored value is authoritative and editable per card
- Total authored score values: 78 × 2 × 3 = **468**
- No per-day or per-user variation in V1. Deselecting an area hides its score; it never changes another area's value

#### 4.2.5 AI reading generation — grounded hybrid

- Prompt assembly: canonical library meanings for the drawn cards and their positions + **the area prompt lens** + the user's question + relationship context (if any) + tone and framing instructions
- **Three area lenses**, managed as prompt templates (§4.3), one per area. A lens tells the model what kind of material to draw out of the same canonical meaning:
  - **Career — advisory.** Practical suggestions about the user's work: what to do today, when to act, how to read a situation, what to stop tolerating. This lens is more directive in register than the other two, and should produce something the user could act on before the day ends
  - **Relationship — the user's own relationship, or the absence of one.** Framed by `relationship_status`: for *single*, the material is about wanting, patterns, and readiness — a first-class case, not a gap, and plausibly the most engaged audience for relationship readings; for *in a relationship*, about honesty, reciprocity, and what is unsaid; for *it's complicated*, about ambiguity and what the user is actually choosing; for *prefer not to say* **or null**, status-neutral framing that assumes nothing
  - **Social — how the people around the user treat them.** Deliberately about what the user *receives*, not how they perform: whether they are seen, included, taken seriously, given the care they give. This is the lens with no real competitor equivalent, and the one most likely to surface distress — crisis routing (§4.2.6) applies with particular force here
- **The lenses apply to deep readings only.** The daily card's three area lines are authored, not generated (§4.2.12) — the lenses inform how that copy is *written*, but no model runs at draw time
- Every deep reading, in every area, arrives with three user-picked cards and their positions (§4.1.9, §4.2.11). The lens governs interpretation; the spread governs structure
- The model may **narrate and connect** the supplied meanings; it must not introduce card meanings absent from the library. Library text is the authority
- Output constraints: length bounds, second person, reflective framing (§4.2.6)
- Readings are persisted at generation time and never regenerated on subsequent views

#### 4.2.6 Content guardrails

Applied as prompt constraints **and** as an output filter:

- **Crisis routing** — if the user's question signals self-harm, abuse, or acute distress, the reading frame is broken entirely and crisis resources are surfaced instead. No card interpretation is delivered. This overrides all other behavior
- **No health or medical predictions** — no illness, pregnancy, death, or treatment guidance. *Included as a baseline compliance requirement: this is the category's primary liability exposure and an explicit App Store rejection trigger*
- **Reflection, not fact** — readings are phrased as prompts for the user's own thinking, not as statements about what will happen. *Included as a baseline compliance requirement: this is the framing App Store review expects for divination apps, and it reduces liability across every other topic*
- **No financial or investment advice** > ⚠️ TBD — not selected; flagged as a recommended addition
- Prompt-injection defense: user question text is treated as untrusted input and cannot alter system instructions (§6.5)

#### 4.2.7 Partial birth profiles

- V1 requires **none** of the birth data to function — tarot needs no chart. The only profile fields V1 uses are `active_areas` and `relationship_status`
- `birth_time = null` and `birth_place = null` are valid states and must not block any V1 flow
- These fields exist to seed V2 astrology. Users with incomplete profiles will be re-prompted at V2 launch, not in V1

#### 4.2.8 Subscription entitlement

> **V1 ships with the paywall flag OFF. Every feature is free.** The following describes the built-but-disabled behaviour, for V1.5.

- Monetization is controlled by a single server-driven feature flag. With it off, every entitlement check returns entitled, no purchase surface is reachable, and no price appears anywhere in the app
- Turning the flag on must require **no App Store release**
- StoreKit 2, auto-renewing subscription; server-side receipt validation
- Entitlement gates only: question readings and relationship readings
- Daily card, fortune scores, and full History remain accessible to lapsed subscribers — **including readings generated while subscribed.** Do not lock previously purchased readings behind an expired subscription
- Grace period and billing-retry states treated as entitled
- **Users who used the app for free before monetization is enabled must not lose access to readings they already generated.** History stays fully readable regardless of entitlement, forever

#### 4.2.9 Active areas

- `active_areas` is a **non-empty subset** of `{career, relationship, social}`, defaulting to all three
- Set at onboarding via a pre-checked multi-select (§4.1.3) and editable from Settings. The last remaining area cannot be deselected
- A deselected area is hidden from Home — no score, no line, no area card — and cannot be entered. It is **not** deleted: readings already made in that area stay in History, and re-selecting the area restores it intact
- **Deselection does not change today's card or any score value.** The card is locked for the day (§4.2.2); hiding an area removes it from view only
- Deep readings are tagged with the area they were entered from. History filters on the reading's own tag
- Areas are **not** inferred or auto-adjusted from behaviour in V1. If someone never opens Social, that is a signal for a later release, not a silent change
- **Why this replaced single-focus selection:** asking a user to pick one area before they had seen the product hid two-thirds of it behind a question they could not yet answer. Home was always going to show all three. A pre-checked multi-select costs nothing to pass through and still captures the deselection signal, which is the only part of the original question that carried information

#### 4.2.10 Profile fields: gender and relationship status

| Field | Required | Values | Used by V1 for |
|-------|:--------:|--------|----------------|
| `relationship_status` | **No** (nullable) | `single` · `in_relationship` · `complicated` · `prefer_not_to_say` · `null` | Selecting the Relationship lens variant (§4.2.5) |
| `gender` | No (nullable) | `woman` · `man` · `non_binary` · `prefer_not_to_say` · `null` | Pronoun choice in reading text only |

- Both are editable from Settings at any time. Relationship status in particular **will** change, and a stale value makes readings feel wrong in a way users notice
- `gender = null` and `gender = prefer_not_to_say` are treated identically: reading text uses they/them. **No reading content is gated on gender** — if the field is empty, nothing degrades except pronouns
- `relationship_status = prefer_not_to_say` and `null` both select the status-neutral Relationship lens. The difference is only that one was chosen and one was skipped; analytics distinguishes them (§5.1), reading generation does not
- Since the field is optional, the about-you screen must state what answering buys — status-neutral readings are the vaguest of the four variants, in the area being made free and central. This is a copy requirement, not a nudge to make the field required
- V1 does **not** re-prompt for either field on a schedule. Detecting a stale relationship status is a V1.5 candidate, and needs care — an automated "are you still together?" prompt can land very badly

#### 4.2.11 Deep-reading card selection

**Applies to every deep reading in every area** — a Career question, a Relationship question, a Social question, and a reading about a named person all use the same three-pick mechanic (§4.1.9). Deliberately different from the daily card (§4.2.2).

- The three cards are **genuinely determined by the user's picks.** Each pick resolves a card server-side at the moment it is made
- **Why this differs from the daily card:** the daily card is resolved ahead of the pick so it can be precomputed for the morning push notification. A deep reading has no equivalent need — nothing is precomputed and the reading is generated after all three picks — so there is no reason for the pick to be ceremonial here. Where honesty is free, take it
- Drawn **without replacement** within a spread: no card repeats across the three positions
- Orientation (upright / reversed) is resolved per pick alongside the card
- Once resolved, a position is immutable. The spread is persisted with the reading (§4.2.5) and never regenerated on later views
- Shuffling between picks affects the presentation order of the five face-down cards only. It does not pre-resolve or re-resolve anything, and the UI must not imply it improves the draw

#### 4.2.12 Daily extras — colour, object, best hour

A small ritual detail shown between the core read and the area scores.

- Three values per card per orientation, authored in the content library: **a colour**, **an object to carry or notice**, and **a best hour** of the day
- Framed as ritual, not fortune: "wear something sage today", "keep something metal in your pocket", "the good hour is after three". Not a prediction, and phrased so it cannot be read as one (§4.2.6)
- **Placement: on the daily summary, above the fold**, between the core interpretation and the area scores (§4.1.6). This is the most screenshot-able element on the screen and the one that gives the share image something concrete, so it does not belong below the areas
- **Deterministic**, read from the library exactly like the scores (§4.2.4). The same card always yields the same three values
- Total authored values: 78 × 2 × 3 = **468**
- Colour must be stored as both a name and a hex value, so the UI can render a swatch and a screen reader can announce the name (§6.3)

**No lucky numbers.** This was considered and rejected. The pattern is common in the category — apps in this space pair a daily card draw with numbers "for your country's lottery format" — but it creates App Store gambling-category adjacency, and a number presented as lucky is a prediction claim of exactly the kind §4.2.6 forbids. Colour and object carry neither problem.

**Why authored rather than generated:** the daily card is the one screen every user opens every day. Authoring the three area lines (§4.2.1) and these three extras means the entire daily experience is a content lookup with **zero LLM cost**. Generation spend then scales only with deep readings, which are opt-in. For an unmonetized V1 (§5.3) this is the difference between cost that tracks DAU and cost that tracks intent.

#### 4.2.13 Launch screen for returning users

- An onboarded user opens **directly on Home**: the **shuffle & pick** screen if today's card is undrawn, or the **daily summary** if it is already drawn. No splash, no interstitial, no re-entry through onboarding
- The shuffle and fan are the first thing a returning user sees each morning. That is the ritual, and nothing should sit in front of it
- The summary is the app's home for the rest of the day. A user opening the app at 9pm sees their card, extras, scores and suggestions — not a spent draw screen
- Because the daily card needs no generation (§4.2.12) and the library is cached (§6.2), the pick should be interactive before any network call completes

#### 4.2.14 LLM cost guard

Necessary because V1 is unmonetized: generation has a real per-reading cost and no offsetting revenue.

- A per-user daily generation cap, enforced server-side. Set generously — the intent is **abuse and runaway-cost prevention, not a product limit**
- Proposed ceiling: 10 deep readings per user per day. A normal user will never see it; the P99 will
- The cap is **not surfaced as a product mechanic.** No "3 readings left today" counter, no upsell on hitting it. A user who somehow reaches it sees a soft "let's pick this up tomorrow" message
- Additional controls: per-reading token ceilings, request timeouts, and prompt caching on the shared library content, which is identical across users and is the bulk of every prompt
- **Aggregate spend must be monitored with an alert threshold from day one.** An unmonetized product with unbounded generation is the one way V1 can cause real financial damage

---

### 4.3 CMS / Admin Requirements

The content library is the product's quality floor and must be editable without an app release.

**Card content management:**

| Field | Type | Notes |
|-------|------|-------|
| card_id | fixed | 78 cards, immutable |
| name, arcana, suit | text | |
| art asset | image | Licensing status > ⚠️ TBD |
| keywords | tag list | Feeds prompt assembly |
| upright meaning / reversed meaning | rich text | Daily interpretation base |
| position meanings | rich text × 6 | Question ×3, Relationship ×3, per orientation |
| daily area lines | short text × 3 per orientation | One-line read per area for the daily card (§4.2.1) |
| daily extras | colour name + hex, object, best hour, per orientation | §4.2.12 |
| area scores | 3 × int 0–100 per orientation (career / relationship / social) | §4.2.4 |

**Required admin capability:**

- Edit and publish card content without an app release; client caches with version invalidation
- Content versioning with rollback — a bad content push must be revertible
- **Feature flag control**, including the monetization flag (§4.2.8) and the cost-guard ceiling (§4.2.14), changeable without an app release
- Prompt template management: edit tone, length, and framing instructions as configuration, not code
- **Area lens management:** the three area prompt lenses (§4.2.5) are first-class, separately editable, and independently previewable. Since area framing is the product's differentiator and lives entirely in these three templates, iterating on them without an app release is a core requirement, not a convenience
- Guardrail keyword/pattern list for crisis routing, editable without release
- Preview: render a reading with current content and prompt templates before publishing

---

### 4.4 Backend / API Requirements

**PM layer — business summary**

This is a greenfield backend. Required capabilities:

1. **Authentication** — Sign in with Apple (required by App Store when any third-party sign-in exists) plus email. Anonymous-to-registered upgrade path is *not* needed, since onboarding collects a profile upfront
2. **User profile** — store `active_areas` (non-empty subset, defaults to all three), `relationship_status` (nullable), `gender` (nullable), plus birth date, birth time (nullable), birth place (nullable). Birth data, relationship status and gender are all sensitive PII; see §6.5
3. **Content library service** — serve versioned card content, area scores, and prompt templates (including the three area lenses) to clients; support client-side caching and invalidation
4. **Daily draw service** — server-authoritative deterministic card assignment (§4.2.2), persisted per user per `date_key`
5. **Reading generation service** — LLM proxy handling prompt assembly, library grounding, output filtering, crisis detection, and cost controls (token caps, timeouts, per-user rate limits)
6. **Reading persistence** — store every reading immutably with its card, orientation, scores, `area` tag, and generated text; serve History with area filtering
7. **Subscription service** — StoreKit 2 receipt validation, entitlement resolution, renewal/lapse webhook handling. **Built but flag-disabled in V1** (§4.2.8); the flag itself is server-driven
8. **Feature flag + cost guard service** — serves the monetization flag and enforces the per-user daily generation cap and token ceilings (§4.2.14)
9. **Push notification scheduling** — one daily send per user (§4.2 / §5.1). The daily card is resolved ahead of the send (§4.2.2), so the notification may reference it
10. **Analytics pipeline** — event ingestion for §5.1

Performance expectations: see §6.1. **Cost expectation: per-reading LLM spend must be bounded, monitored, and alerted on from day one — V1 has no revenue to offset it** (§4.2.14).

**Dev layer — technical detail**

> ⚠️ 以下内容由开发 lead 补充 — to be completed by the engineering lead
>
> - API design (paths, request/response contracts, protocol)
> - Technology selection: the backend stack is an open decision. A managed BaaS was considered and not chosen; greenfield build confirmed
> - LLM provider, model selection, and prompt-caching strategy
> - Content library storage and CDN strategy for card art
> - Caching: content library, entitlement, daily draw
> - Rate limiting and abuse prevention on the generation endpoint
> - Data retention and deletion implementation for birth data (§6.5)

---

### 4.5 Localization

Not activated. V1 is English-only for the US / global market.

> Note for planning: the hybrid engine requires curated canonical text per card, per orientation, per position — so adding a language multiplies content authoring cost, not just string translation. If a Chinese-market version is anticipated, the content model should be built language-keyed from the start even though V1 ships one language.

---

## 5. Data Requirements

### 5.1 Analytics Events

**Primary metric: D7 / D30 retention.**

Observation metrics and the events required to compute them:

| Metric | Events needed |
|--------|--------------|
| Daily card open rate | `push_sent`, `push_opened`, `home_viewed`, `daily_card_drawn{position}`, `daily_card_viewed` |
| Onboarding completion / drop-off by step | `onboarding_started`, `onboarding_step_viewed{step}`, `onboarding_step_completed{step}`, `area_deselected{area}`, `relationship_status_selected{value}`, `relationship_status_skipped`, `gender_selected{value}`, `gender_skipped`, `birth_time_unknown_tapped`, `onboarding_completed`, `onboarding_abandoned{step}` |
| Deep-reading funnel (no paywall in V1) | `area_card_tapped{area}`, `area_detail_viewed{area}`, `suggestion_chip_tapped{area}`, `composer_opened{area, type}`, `question_submitted{area}` |
| Readings per user + history revisits | `reading_generated{area, type}`, `reading_viewed{area, type, is_historical}`, `history_opened`, `history_filtered{area}`, `history_entry_opened`, `note_saved`, `reading_shared` |
| Retention (primary) | `session_start` with user identity, install date, and current `active_areas` |

Additional events worth capturing from day one:

- `reading_generation_failed{reason}` — feeds the §6.2 fallback rate
- `fallback_reading_served` — how often users get library-only text instead of AI
- `crisis_routing_triggered{area}` — safety monitoring; **must not log the user's question text.** Expected to fire disproportionately in the Social area (§4.2.5)
- `cost_guard_hit` — how often the daily generation cap is reached (§4.2.14). Should be near zero; a non-trivial rate means either the ceiling is wrong or something is being abused
- `card_position_picked{position}` — which of the five positions users choose. Purely observational, but if the distribution is heavily skewed the fan layout is biasing the choice
- `resonance_prompt_answered{value, area}` — an optional post-reading "did this resonate?" tap, the only direct read on whether the personalization wedge is working. Recommended for V1, and **segmented by area** so a weak lens can be identified and rewritten (§4.3) without an app release
- `areas_changed{active_areas, surface}` — when someone adds or removes an area. A high deselection rate on one area is the clearest possible signal that the three-way cut is wrong
- `extras_viewed` and `extras_shared` — whether the colour / object / hour panel earns its space or is scrolled past. If it is ignored, 468 authored values are dead weight and should be cut in V1.5
- `shuffle_replayed` — how often users re-shuffle before picking. A high rate means the fan feels arbitrary and the pick is not landing as a choice
- `pick_during_shuffle` — how often users tap before the animation finishes. If high, the sequence is too long
- `reveal_dwell_ms` — how long users stay on the card reveal before advancing. The clearest signal of whether the beat is earning its place: a median near zero means it reads as an interstitial to dismiss, not a moment
- `reveal_reopened` — how often the card is reopened from the summary during the day
- `reveal_shared` — shares originating from the reveal, versus from a reading
- `spread_pick_made{area, reading_type, position, index}` and `spread_shuffled{area, position}` — progress through the three rounds, segmented by area so a ritual that works for Career but not Social is visible
- `spread_abandoned{area, picks_made}` — **the most important metric added in V0.7.** Someone who typed a question is at peak intent; three picks now stand between that and their answer. If abandonment clusters at one or two picks made, the ritual is costing more than it adds

**Onboarding step granularity is non-negotiable.** Full birth data upfront is the highest-risk decision in this spec (§9 risks) and onboarding is now four steps; per-field drop-off is the only way to quantify its cost.

**With no paywall in V1, engagement depth carries the weight monetization metrics would have.** `readings_per_user`, per-area entry rates, and the resonance prompt are the only signals of value V1 produces. Instrument them properly.

**Area segmentation is non-negotiable too.** Almost every metric above carries an `area` dimension. The three-area structure is the central product bet of V0.2 — if one area drives most engagement, or one lens consistently fails the resonance prompt, that is the most actionable finding V1 can produce.

### 5.2 A/B Testing

| Item | Content |
|------|---------|
| Test Owner | zoe.zhang@acorn.works |
| Background | Onboarding is two screens. The about-you screen is pre-filled and fully optional, so the real cost is the birth-data screen: three fields V1 does not use at all. Exact birth time is the highest-drop-off field in this category; many users do not know it |
| Hypothesis | Deferring all three birth fields until the V2 astrology launch will increase onboarding completion, with no measurable cost to V1 retention |
| Trigger point | First app open, at onboarding start |
| Groups | **V0 (control):** birth data + about-you, as specified. **V1 (variant):** about-you only; all birth data deferred to V2 |
| Metrics (primary) | Onboarding completion rate |
| Observation metrics | D7 retention, first-draw completion rate, share of profiles with complete birth data, paywall conversion |

> **Still the highest-priority experiment in V1**, though the case is now narrower and cleaner. V0.4 removed the focus question and made the about-you fields optional, so onboarding is two screens instead of four steps. What remains is a single unambiguous question: does asking for birth data, for a release that never reads it, cost signups?
>
> The variant defers **all** birth data. The recommendation on record is to ship the variant as the default; it is specified as the experiment arm because the control was an explicit product decision.

**Second candidate test (queued, not V1):** fixed-time daily push vs. user-chosen send time. Send time is the cheapest available lever on the primary retention metric, and V1 ships the fixed-time version for build simplicity.

### 5.3 Business Target

**V1 has no revenue and no revenue target, by decision.** Everything is free; the subscription ships disabled (§4.2.8). V1 is scoped purely as a retention experiment, and pricing is set once D30 is known.

Consequences to hold in view:

- **Cost without offset.** Every reading costs money and earns none. §4.2.14 is the control; the spend alert is not optional
- **No willingness-to-pay signal at all.** V1 cannot tell you whether anyone would have paid. The nearest proxies are readings per user and the resonance prompt
- **Placeholder price.** The dark paywall carries **$9.99/month**, matching category norm. It must be confirmed before the flag is ever enabled — not before submission, since users cannot reach it in V1
- **Annual plan.** Out of V1 scope, but the standard lever in this category, and worth deciding before monetization is switched on: annual plans offset the weak early retention typical of casual-user products

---

## 6. Non-Functional Requirements

### 6.1 Performance

- App cold start to interactive Home: **< 2s**
- Daily card render from cached content: **< 1s**
- AI reading — first token visible: **< 3s**; full generation complete: **< 15s**
- Card art must be bundled or pre-cached; the daily draw must not block on a network image fetch
- History list scroll must remain smooth with 365+ entries

### 6.2 Fallback and Fault Tolerance

The hybrid engine's main structural advantage is that it degrades gracefully — this must be built, not assumed.

- **LLM failure or timeout** → serve the library-only interpretation for the drawn cards. The user gets a real, coherent reading; it is simply less personalized. Never show an error in place of a reading
- **Content library fetch failure** → fall back to the version bundled with the app build. The app must be fully functional for the daily card while offline
- **Daily draw service unreachable** → the deterministic seed permits client-side computation as a last resort; reconcile with the server on reconnect. The daily ritual must not be breakable by a backend outage
- **Receipt validation failure** → fail open to entitled for a bounded grace window rather than locking out a paying user. In V1 this is moot: every check returns entitled (§4.2.8)
- **Cost guard reached** → a soft "let's pick this up tomorrow" message, never an error or an upsell (§4.2.14)
- **Reading generation fails** → retry, and preserve the question. Never lose typed input

### 6.3 Accessibility (ADA)

Required — this is a US-facing product.

- VoiceOver labels for all card art, including card name and orientation ("The Star, reversed")
- The three area scores must be readable by screen reader as labeled values ("Career, 64 out of 100"), not conveyed by color, bar length, or shape alone
- The daily colour must be announced by **name**, never conveyed by the swatch alone (§4.2.12) — a colour swatch with no text label is invisible to a screen reader and to anyone with a colour-vision deficiency
- Dynamic Type support throughout; reading text must reflow rather than truncate
- Reduce Motion: the shuffle sequence, the reveal's card flip, and all draw animations are replaced with cross-fades. The five-card fan must be tappable on first paint, and the reveal's content must be fully present on first paint, with no waiting period
- Minimum 4.5:1 contrast for all reading and score text. Atmospheric, low-contrast design is a real risk in this category and must not compromise legibility

### 6.4 SEO

Not applicable — iOS native app, no web surface in V1. App Store listing optimization is a marketing concern outside this document.

### 6.5 Security and Privacy

- **Birth data is sensitive PII.** Date, exact time, and place of birth are quasi-identifiers and, in combination, close to uniquely identifying. Encrypt at rest, transmit over TLS only, and never share with third parties or include in analytics payloads
- **Gender and relationship status are sensitive personal data in their own right** and are treated the same way: encrypted at rest, never shared, never sent to third-party analytics or advertising SDKs. Analytics may record that a value was *selected* (§5.1) but must aggregate, never attach either field to an identified user profile in a third-party tool. Both must be editable and deletable by the user at any time
- User question text is highly sensitive — people ask about health, relationships, and money. Never log question text to analytics. Retention policy for question text > ⚠️ TBD, and needs a decision before launch
- **Prompt-injection defense:** user question text is untrusted input. It must not be able to override system instructions, extract prompt templates, or bypass the §4.2.6 guardrails. Treat guardrails as an output filter as well as a prompt constraint — prompt instructions alone are not a control
- Account deletion must delete birth data, gender, relationship status, and all readings, per App Store requirements
- The App Store privacy manifest must declare gender and relationship status as collected data types alongside the birth fields
- App Store review framing: the app must present divination as entertainment and self-reflection. The disclaimer in §4.1.1 and §4.1.5 and the reflection-not-fact framing in §4.2.6 exist for this reason

---

## 7. Launch Strategy

| Item | Content |
|------|---------|
| Release method | TestFlight beta → App Store phased release (staged rollout over 7 days) |
| Dependencies | Content library fully authored: **1,404 interpretation units** (936 deep-reading positions + 468 daily area lines), **468 area score values**, **468 extras values** (§4.2.12); **three area prompt lenses written and quality-tested, including the four relationship-status variants**; card art licensed; LLM provider contracted; **cost alerting live** (§4.2.14). App Store subscription products can be configured after launch, since the paywall ships disabled |
| Rollback plan | Content and prompt templates are server-controlled and revertible without a release (§4.3) — this covers reading-quality regressions. Binary issues require an expedited App Store review, so the phased rollout is the primary safety mechanism |
| Launch date | > ⚠️ TBD |
| A/B dependency | None at launch. The §5.2 onboarding test is a fast-follow |

**Pre-submission checklist specific to this category:**

- [ ] Entertainment-purpose disclaimer present and accessible
- [ ] No health, medical, or death predictions reachable from any prompt
- [ ] Crisis routing verified against a red-team prompt set, run separately for each of the three area lenses
- [ ] Each area lens produces visibly different readings from the same card
- [ ] No lucky numbers, lottery references, or numeric predictions appear anywhere (§4.2.12)
- [ ] Daily extras read as ritual suggestions, not predictions
- [ ] **No price, lock, or subscription language is reachable anywhere in the app with the flag off**
- [ ] Subscription terms, price, and cancellation policy displayed pre-purchase (verified with the flag on, before V1.5)
- [ ] Restore Purchases functional
- [ ] Account deletion removes birth data, gender, relationship status, and readings
- [ ] Privacy manifest declares gender and relationship status
- [ ] Per-user generation cap enforced and cost alerting confirmed firing

---

## 8. Phasing

V1 is deliberately a slice. The full product concept spans two divination systems; the phase boundary is drawn where the engineering cost jumps.

| Phase | Scope | Rationale |
|-------|-------|-----------|
| **V1 (this PRD)** | Tarot across three areas: five-card pick, daily card with core read + three area lines + scores + extras, deep readings per area, relationship spread, history with area filtering. All free | Tests the retention bet with no calculation engine. Content set is finite and fully authorable, and the daily screen costs nothing to serve |
| **V1.5** | **Monetization flag switched on** (§4.2.8); onboarding A/B result applied; user-chosen notification time; annual subscription plan; area lens iteration based on `resonance_prompt_answered{area}`; stale relationship-status handling | All of it server-side or flag-driven — no App Store release needed to start charging |
| **V2** | Astrology: natal chart (一生), annual forecast (流年), synastry (合盘) — **surfaced inside the same three areas**, not as a separate section | Requires an ephemeris / calculation engine — planetary positions, houses, aspects, transit timing. Cannot be approximated with content alone. Justified only once V1 proves users return |

**V2 candidate — the three-card daily draw.** Pick three cards instead of one, read as a spread. Recorded here rather than scoped, pending V1 retention data.

- **The mechanic is authentic.** Three-card spreads are the most common form in tarot after the single card — past/present/future, situation/action/outcome — and the meaning genuinely comes from the relationships *between* the cards, not just from having more of them
- **Naming constraint, non-negotiable: it must not be sold as "more accurate."** Tarot has no accuracy to be greater or lesser, so the claim is false in a way practitioners will call out; more importantly it is a prediction claim, which breaks the reflection framing that §4.2.6 and App Store review both depend on. Use **"a deeper read"** or **"a fuller picture"** — honest, since three cards do give more material, and it sells the upgrade just as well
- Business model deliberately undecided. It is the most obvious candidate for what a subscription unlocks when the flag turns on (§4.2.8), but that decision waits for D30

**The three areas are the integration point for V2.** Astrology enters as added depth within Career / Relationship / Social — "what your chart says about this year at work" sits inside the Career area alongside the tarot readings — rather than as a second app bolted beside the first. This is the main structural benefit of the V0.2 restructure: it gives V2 somewhere to land.

**The tarot relationship spread is the designed fallback for V2 synastry.** Most users will not know their partner's exact birth time, which would otherwise dead-end the synastry flow. Because the tarot relationship reading requires no birth data at all, V2 can offer it instead of failing — this is why it belongs in V1 rather than being deferred alongside the rest of relationship analysis.

---

## 9. Open Risks

| Risk | Severity | Mitigation |
|------|:--------:|-----------|
| **Nobody comes back** — the daily card is pleasant but not compelling, and D7 collapses. *Identified as the top concern.* | High | This is the core product bet, and the reason for tarot-first phasing: it is answered in weeks rather than after the astrology engine is built. Mitigations in scope: locked-card ritual integrity, daily push, history and look-back. Mitigations queued: user-chosen send time, streak mechanics. **If D7 fails, V2 should not be built as specified** |
| **Onboarding drop-off** — full birth data before any value, in a release that does not use it | High | "I don't know" affordance on birth time; copy explaining why it's collected; per-step analytics (§5.1); A/B test queued (§5.2). *Accepted knowingly* |
| **App Store rejection** — divination content with paid subscriptions | Medium | Entertainment framing, disclaimer, guardrails, pre-submission checklist (§7). Fully mitigable if addressed before submission rather than at it |
| **AI quality and cost** — bland, contradictory, or expensive readings undermine both the wedge and the margin | Medium | Library grounding constrains output; prompt templates are server-editable without release; token caps and per-user rate limits; `resonance_prompt_answered` gives a direct quality signal; library-only fallback bounds the worst case |
| **Unmonetized generation cost** — every reading costs money, none earns any, and V1 has no revenue target | High | New in V0.3. §4.2.14 is the control: server-side per-user daily cap, token ceilings, prompt caching on shared library content, and a spend alert live before launch. The cap is a cost guard, not a product limit, and is invisible to normal users |
| **Onboarding has grown at every revision** — six fields now, two of them used by V1 | High | Gender and relationship status share one screen so the field count grew without the step count. Gender is skippable. The §5.2 A/B test is now the top-priority experiment and defers all birth data. The standing recommendation is to ship the deferred variant |
| **Three picks stand between a question and its answer** — new in V0.7. The user is at peak intent when they submit a question, and now has three shuffle-and-pick rounds before any reading | Medium | Instrumented via `spread_abandoned{picks_made}` (§5.1). Mitigations already in spec: the question stays on screen, slots show remaining draws, and abandoning preserves progress. **Recommended fast-follow if abandonment is material: a "draw all three for me" shortcut** that fills the spread in one action. Not built in V1 |
| **The card pick is theatre** — five cards are offered, the outcome is predetermined | Low | Accepted deliberately (§4.2.2), and documented as a fiction rather than left implicit. The honest alternative — chosen position feeds the seed — is a backend-only change with no UI impact, available at any time if the pick starts to feel hollow |
| **The extras panel is dead weight** — 468 authored values for a colour, object and hour nobody reads | Low | New in V0.4. Instrumented via `extras_viewed` / `extras_shared` (§5.1). If ignored, it is cut in V1.5 at no cost beyond the authoring already spent. Deliberately excludes lucky numbers, which would have carried App Store gambling adjacency (§4.2.12) |
| **Status-neutral relationship readings are vague** — relationship status is optional, and skippers get the least specific of the four lens variants in a central free area | Medium | New in V0.4, a direct consequence of making the field optional. Mitigated by copy on the about-you screen stating what answering buys, and measurable via per-area resonance segmented by status (§5.1) |
| **The three areas are the wrong cut** — users don't recognize their concerns in Career / Relationship / Social, or one area carries all the engagement and the other two are dead weight | Medium | New to V0.2 and untested. Instrumented via `area_card_tapped{area}`, `focus_changed`, and per-area resonance (§5.1). Cheap to correct: the areas live in content and prompt templates, so renaming, merging, or replacing one needs no app release |
| **Content authoring is underestimated** — 1,092 authored interpretation units plus 468 area score values before launch | Medium | Not yet resourced. Content production is a launch dependency (§7) and needs an owner and timeline. Note the three areas add three prompt lenses, **not** 3× the library (§4.2.1) — this was a deliberate choice to keep the number tractable. > ⚠️ TBD |
| **Area lens quality** — the three lenses are where the personalization promise is actually kept, and they are three text templates | Medium | Server-editable without release (§4.3); per-area resonance metric (§5.1); pre-submission check that lenses produce visibly different output (§7) |
| **Card art licensing** | Medium | > ⚠️ TBD — must be resolved before submission |

---

## 10. Visual Direction

Settled 2026-09-09 from four candidate directions: **Soft dawn.**

| Element | Decision |
|---------|----------|
| Ground | Dusty rose / warm off-pink, with visible risograph grain |
| Ink | Warm brown-black (`#43302b`), not pure black |
| Accents | Clay `#b0654a`, dusty blue `#6f8ca2`, ochre `#c79a3f`, sage `#7d8f6a` — one per area score, shared chroma |
| Display type | Gabarito |
| Body type | Hanken Grotesk |
| Card art | Layered flat pastel shapes with ink linework; abstract rather than illustrative |
| Score treatment | Soft rounded bars with numerals, one accent hue per area |
| Shape language | Generous radii, arch-topped cards, rounded 50px controls |

**Why this over the alternatives:** it reads as the calm morning minute the daily ritual is meant to be, it is distinctive in a category dominated by midnight-and-gold mysticism, and its warm palette clears the §6.3 contrast requirement comfortably — which the celestial-dark alternative did not.

**Known tradeoff to watch:** the direction reads closer to a wellness app than a tarot app. App Store screenshots and the icon carry more of the "this is tarot" signal than usual, and should be designed with that job in mind.

Rejected directions, kept for reference: Warm editorial (paper and ink), Celestial dark (midnight and gold), Field notes (brutalist mono).

> ⚠️ Card art licensing remains TBD (§9). The abstract direction chosen here reduces but does not remove the need for a commissioned set.

---

## 11. Decision Record

Positions that were argued and settled. Recorded so they are not silently re-litigated — and so that if one is revisited, it is revisited knowing why it was decided.

| Decision | Settled | Rejected alternative | Why |
|----------|---------|---------------------|-----|
| Three areas: Career · Relationship · Social | V0.2 | A single undifferentiated daily reading | The areas are the spine — they score the day, organize deep readings, and give V2 astrology somewhere to land (§8) |
| Three scores, not four | V0.2 | Love / Work / Money / Luck | Money and Luck had no corresponding reading area. Users would have asked why Money is scored but cannot be asked about (§4.2.4) |
| No gate on the daily card or Area detail | V0.2 | "Analyse a relationship" as a Home CTA | It asked the user to name a specific person before the app had earned anything, and pitched the paid tier in the same breath as the free ritual |
| Everything free at launch | V0.3 | Freemium with deep readings gated | V1 is a retention experiment with no revenue target (§5.3). A paywall only adds friction to the thing being measured |
| Gender: four options, optional | V0.3 | Two options, required | English-language US launch. A two-option field excludes real users and reliably draws App Store review comments in this category (§4.1.3) |
| No single "focus area" question | V0.4 | Pick one of three at onboarding | Home shows all three anyway, so the question hid two-thirds of the product behind a choice the user could not yet make (§4.2.9) |
| Relationship status: optional | V0.4 | Required | Cost of a required field outweighed the benefit; "prefer not to say" and `null` both resolve to a status-neutral lens (§4.2.10) |
| Daily content authored, not generated | V0.4 | AI-generate the daily area lines | The daily screen is the one every user opens every day. Authoring it makes V1's cost scale with intent rather than with DAU (§4.2.12) |
| No lucky numbers | V0.4 | Colour + number + item, the familiar horoscope panel | Lottery-adjacency is an App Store category risk, and a "lucky number" is a prediction claim of exactly the kind §4.2.6 forbids |
| Scores panel separate from suggestion rows | V0.5 | Merged into one per-area row (tried in V0.4) | Two different questions — "how is today" and "what do I do about it". Merging buried the at-a-glance read (§4.1.6) |
| Shuffle as native/Lottie animation | V0.5 | A short video file | A video cannot respond to Reduce Motion, adds bundle weight, and cannot be interrupted by an early tap (§4.1.4) |
| Card reveal as its own screen | V0.6 | Card shown inside the summary | Dropping straight into a panel stack buries the thing the user just chose (§4.1.5) |
| Daily pick is ceremonial; deep-reading picks are not | V0.2 / V0.7 | Both ceremonial, or both determinative | The daily card is resolved early so it can be precomputed for the morning push. A deep reading has no such need, so honesty there is free (§4.2.2, §4.2.11) |
| Three-card draw named "a deeper read" | V0.6 | "More accurate" | Tarot has no accuracy to be greater or lesser, and an accuracy claim breaks the reflection framing App Store review depends on (§8) |

**Still open**, carried forward rather than settled:

- **Per-area spread positions** — whether Relationship and Social get their own position triples instead of sharing Situation / Action / Outcome (§4.1.9)
- **Library-fallback copy** — whether the degraded-reading framing is honest enough or too apologetic (§6.2)
- **Card art licensing** and **content authoring ownership** — the two unowned launch blockers (§9)
- **Question-text retention policy** (§6.5)
- **Final subscription price** — before the flag is ever enabled (§5.3)

---

## 12. Responsibility Matrix

| Section | PM | Design | Dev |
|---------|:--:|:------:|:---:|
| 1. Revision history | R | — | — |
| 2. Background | R | C | I |
| 3. Summary | R | C | I |
| 4.0 User flow | R | C | C |
| 4.1 Frontend | R | R | C |
| 4.2 Data / business logic | R | I | C |
| 4.3 CMS | R | C | C |
| 4.4 Backend (business layer) | R | I | C |
| 4.4 Backend (technical layer) | I | I | R |
| 5.1 Analytics events | R | I | C |
| 5.2 A/B testing | R | I | C |
| 6.1 Performance | C | I | R |
| 6.2 Fallback | C | I | R |
| 6.3 ADA | C | R | C |
| 6.5 Security & privacy | C | I | R |
| 7. Launch strategy | R | I | C |
| 8. Phasing | R | C | C |
| 9. Open risks | R | C | C |
| 10. Visual direction | C | R | I |
| 11. Decision record | R | C | C |

R = owns · C = reviews · I = informed
