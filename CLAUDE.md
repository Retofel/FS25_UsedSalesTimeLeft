# FS25_UsedSalesTimeLeft

## What this mod does
A Farming Simulator 25 (PC) script mod that displays the remaining time (in hours) for each item listed in the in-game **used vehicle sales shop**. The game stores these items in `sales.xml` (per save), each with a `timeLeft` attribute representing hours before the item is removed from the shop.

## Current status
Work in progress. The mod loads but the hook into the shop UI is not yet working.

## Project structure
- `FS25_UsedSalesTimeLeft/` — the actual mod folder (this gets zipped for distribution)
  - `modDesc.xml` — mod descriptor (descVersion must match current FS25 version, currently `106`)
  - `scripts/UsedSalesTimeLeft.lua` — main mod script
  - `icon_UsedSalesTimeLeft.dds` — mod icon (256x256 DDS)
- `Examples/` — reference mods for learning patterns
- `sales.xml` — example of the game's sales data file

## FS25 modding patterns
- Mods hook into game classes using `Utils.appendedFunction`, `Utils.prependedFunction`, or `Utils.overwrittenFunction`
- `addModEventListener(mod)` registers lifecycle events (`loadMap`, `deleteMap`, `update`, etc.)
- Global objects: `g_currentMission`, `g_modManager`, `g_currentModDirectory`, `g_currentModName`
- Shop item display uses `ShopItemsFrame.populateCellForItemInSection` — this is the function to hook for modifying how items appear in the shop list
- Cell attributes available: `modDlc`, `priceTag`, `value` (accessed via `cell:getAttribute("name")`)
- Display items accessed via `self.displayItems[index]`
- Hooks can be placed at script top level (runs on load) or inside `loadMap` (runs when save loads)
- Game log file: `log.txt` in the FS25 user profile folder

## Packaging
To create the mod zip: select the **contents** of `FS25_UsedSalesTimeLeft/` (not the folder itself) and zip them. The zip must be named `FS25_UsedSalesTimeLeft.zip` and placed in the game's `mods` folder.

## Language
Lua (FS25 scripting language)
