# Bundled fonts

Unmodified variable TTFs from the Google Fonts repository, fetched 13 October 2026. Distributed under the adjacent SIL Open Font Licence files and bundled in the app resources.

- Gabarito: https://github.com/google/fonts/tree/main/ofl/gabarito. Source `Gabarito[wght].ttf`, Git blob `f048f3b6527b2aff1adb92bd682acb1d8adcdc9c`.
- Hanken Grotesk: https://github.com/google/fonts/tree/main/ofl/hankengrotesk. Source `HankenGrotesk[wght].ttf`, Git blob `ed6efac663fab76e550a2c994d95ca143587da18`.

Files are renamed only to simplify bundle registration. `Info.plist` registers both at launch. `Design.TypeRole` chooses their weights and Dynamic Type scales. The font test requires the actual expected UIFont family and PostScript names; system fallback fails it.
