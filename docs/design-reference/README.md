# Design reference images

12 October 2026 · A picture of every screen in the [design manifest](../design.md), exported from the private design canvas so that any agent or reviewer can see the target. Use them for the manifest's design check (§12).

| Screen | Image | State shown |
|---|---|---|
| Flow map | [00-flow-map.png](00-flow-map.png) | How the eleven screens connect |
| 01 Welcome | [01-welcome.jpg](01-welcome.jpg) | First open |
| 02 Draw today's card | [02-draw.jpg](02-draw.jpg) | Five cards dealt, none chosen |
| | [02-draw-card-chosen.jpg](02-draw-card-chosen.jpg) | Third card chosen |
| 03 Card reveal | [03-reveal.jpg](03-reveal.jpg) | After the card has turned |
| 04 Today | [04-today-first-day.jpg](04-today-first-day.jpg) | Day one, with the reminder invitation |
| | [04-today.jpg](04-today.jpg) | Any later day |
| 05 Ask | [05-ask.jpg](05-ask.jpg) | Relationship area, status not yet answered |
| 06 Ask a question | [06-composer.jpg](06-composer.jpg) | Empty, button disabled |
| | [06-composer-question-entered.jpg](06-composer-question-entered.jpg) | Question entered, button enabled |
| 07 About someone | [07-about-someone.jpg](07-about-someone.jpg) | Empty |
| 08 Three-card pick | [08-three-card-pick.jpg](08-three-card-pick.jpg) | Choosing the first card |
| | [08-three-card-pick-complete.jpg](08-three-card-pick-complete.jpg) | All three drawn |
| 09 Your reading | [09-reading.jpg](09-reading.jpg) | A relationship reading |
| 10 History | [10-history.jpg](10-history.jpg) | All areas |
| 11 Settings | [11-settings.jpg](11-settings.jpg) | All areas on, reminder on |

## How to read them

- Each image is 390 points wide at two pixels per point. Today, Ask, Your reading, History and Settings scroll, so their images show the whole length of the screen; on a phone only the first 844 points are visible at once and the tab bar stays pinned to the bottom.
- They are web renderings of a mock-up, not screenshots of the app. Text rendering and exact pixel positions will differ slightly in SwiftUI. Compare structure, order, colour, type, shape, spacing and wording; do not expect a pixel match.
- The dates, cards, questions and names shown are invented examples.
- Where an image and the manifest disagree, the manifest wins. Menus, confirmations and empty, loading and error states have no image; build those from the manifest's rules.
- The images are JPEGs to keep the repository small, so do not sample colours from them. Take colour values from the manifest.

## Keeping them current

When a screen changes on the canvas, re-export that screen at 390 points wide and replace its image in the same change as the manifest update. The exports were made by rendering each canvas artboard in a headless browser after its animations had finished.
