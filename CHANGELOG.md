# Changelog

## v0.1.0.0:
- Added color coded time left boxes that change based on the time remaining for each sale item. See modDesc.xml for the thresholds.
- Updated mod description in modDesc.xml with color threshold details
### Internal changes:
- Added color constants (`COLOR_GREEN`, `COLOR_ORANGE`, `COLOR_RED`) and time threshold constants (`MIN_THRESHOLD_GREEN/ORANGE/RED`) as top-level configuration
- Added `getColorForTimeLeft()` to select color based on hours remaining
- Added `applyBoxColor()` to set box background and text colors across all GUI states (normal, focused, selected, highlighted) with inverted colors when selected
- Added `debugLogColors()` for inspecting overlay and text color state values
- Added `GuiOverlay` to `.luarc.json` globals
- Added v0.1.0.0 screenshots as assets.

## v0.0.3.0:
- Styled time-left display as a green box matching the game's discount tag (cloned from `priceTag` ThreePartBitmapElement)
- Updated mod description in modDesc.xml with link to GitHub for bug reports and feature requests
### Internal changes:
- Box inherits game's state-dependent colors (green normally, black when selected/highlighted)
- Box auto-sizes width to fit text content using draw() override
- Reliable left-side positioning via draw() override (bypasses layout system)
- Refactored mod logic into dedicated functions (`createTimeLeftBox`, `updateTimeLeftDisplay`, `debugLogCellAttributes`)
- Hide time-left box with `setVisible(false)` instead of clearing text on recycled cells

## v0.0.2.1:
- Updated mod icon with new higher-resolution branding in the correct GIANTS format + background
### Internal changes:
- Some tidying up of project folders.

## v0.0.2.0:
### Internal changes:
- Extract configuration constants (TEXT_FORMAT, FONT_SIZE_FACTOR, IS_DEBUG) to top-level for easy customization
- Wrap shop hook logic in pcall to prevent mod errors from crashing the game
- Add structured logging with debugLog/errorLog helpers (debug off by default)
- Increase font size factor from 0.6 to 0.7 for better readability
- Shorten time left label from "Time left: Xh" to "Xh left"
- Add code comments throughout for maintainability
- Fixed: Issue #2 - Text would overlap when in store while an hour passes and the store updates. https://github.com/Retofel/FS25_UsedSalesTimeLeft/issues/2

## v0.0.1.0:
- Display "Time left" with reduced font size on used sale items in the shop
### Internal changes:
- Fix text size not applying by setting defaultTextSize on cloned UI element

## v0.0.0.1:
- WIP
- Super basic implementation of displaying the time left for each item in the used sales shop.