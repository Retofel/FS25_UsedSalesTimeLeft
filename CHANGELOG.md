# Changelog

## v0.0.2.1:
- Updated mod icon with new higher-resolution branding in the correct GIANTS format + background
- Some tidying up of project folders.

## v0.0.2.0:
- Extract configuration constants (TEXT_FORMAT, FONT_SIZE_FACTOR, IS_DEBUG) to top-level for easy customization
- Wrap shop hook logic in pcall to prevent mod errors from crashing the game
- Add structured logging with debugLog/errorLog helpers (debug off by default)
- Increase font size factor from 0.6 to 0.7 for better readability
- Shorten time left label from "Time left: Xh" to "Xh left"
- Add code comments throughout for maintainability
- Fixed: Issue #2 - Text would overlap when in store while an hour passes and the store updates. https://github.com/Retofel/FS25_UsedSalesTimeLeft/issues/2

## v0.0.1.0:
- Display "Time left" with reduced font size on used sale items in the shop
- Fix text size not applying by setting defaultTextSize on cloned UI element

## v0.0.0.1:
- WIP
- Super basic implementation of displaying the time left for each item in the used sales shop.