# FS25_UsedSalesTimeLeft

## What this mod does
A Farming Simulator 25 (PC) script mod that displays the remaining time (in hours) for each item listed in the in-game **used vehicle sales shop**. The game stores these items in `sales.xml` (per save), each with a `timeLeft` attribute representing hours before the item is removed from the shop.

## Current status
Core functionality is implemented and working. The mod hooks into `ShopItemsFrame.populateCellForItemInSection` and displays hours remaining (e.g. "5h left") in a styled green box on each used sale item in the shop UI. The time-left box is cloned from the `priceTag` discount element (a `ThreePartBitmapElement`) so it inherits the game's green background, font, and state-dependent colors (green normally, black when selected/highlighted). The box is positioned at the bottom-left of each cell and auto-sizes its width to fit the text content. All mod logic is wrapped in `pcall` for error protection. Debug logging is available via `IS_DEBUG` flag (currently enabled for development).

## Project structure
- `FS25_UsedSalesTimeLeft/` — the actual mod folder (this gets zipped for distribution)
  - `modDesc.xml` — mod descriptor (descVersion must match current FS25 version, currently `106`)
  - `scripts/UsedSalesTimeLeft.lua` — main mod script
  - `icon_UsedSalesTimeLeft.dds` — mod icon (512x512 DDS, BC1 format, no mipmaps)
- `examples/` — reference mods for learning patterns
- `examples/sales.xml` — example of the game's sales data file

## FS25 modding patterns
- Mods hook into game classes using `Utils.appendedFunction`, `Utils.prependedFunction`, or `Utils.overwrittenFunction`
- `addModEventListener(mod)` registers lifecycle events (`loadMap`, `deleteMap`, `update`, etc.)
- Global objects: `g_currentMission`, `g_modManager`, `g_currentModDirectory`, `g_currentModName`
- Shop item display uses `ShopItemsFrame.populateCellForItemInSection` — this is the function to hook for modifying how items appear in the shop list
- Cell attributes available: `modDlc`, `priceTag`, `priceTagText`, `brandIcon`, `value`, `icon`, `title` (accessed via `cell:getAttribute("name")`)
- `priceTag` is the green discount box (`ThreePartBitmapElement`) with 1 child (`TextElement`), overlay color `0.22,0.41,0.00,1.00`
- Display items accessed via `self.displayItems[index]`
- Hooks can be placed at script top level (runs on load) or inside `loadMap` (runs when save loads)
- Game log file: `log.txt` in the FS25 user profile folder

## GUI element positioning & rendering knowledge (hard-won)
These lessons were discovered through iterative in-game testing. They are NOT documented in the FS25 API docs.

### Layout system overrides `setPosition()`
Setting `position` via `setPosition()` does NOT reliably control where elements render. The layout system computes `absPosition` from position+anchors+parent layout, and `absPosition` is what `draw()` uses. Even setting `layoutIgnore = true` didn't prevent this. **The only reliable way to control position of a cloned element is to override its `draw()` method** and set `absPosition` directly before calling the original draw.

### draw() override pattern for positioning and sizing
Override the instance's `draw()` method (not the class method) to intercept after layout but before rendering:
```lua
local origDraw = element.draw
element.draw = function(drawSelf, clipX1, clipY1, clipX2, clipY2)
    -- Modify drawSelf.absPosition and drawSelf.absSize here
    -- Also update children's absPosition/absSize to match
    origDraw(drawSelf, clipX1, clipY1, clipX2, clipY2)
end
```
This works because `draw()` is called after layout computation. By setting `absPosition`/`absSize` just before the original draw, you get the final say on where and how big the element renders.

### Auto-sizing ThreePartBitmapElement width
Use engine globals `getTextWidth(fontSize, text)` and `setTextBold(bool)` to measure text, then set `absSize[1]` to the measured width plus padding. Must also set child `TextElement.absSize[1]` to match. Store the text string on the element (e.g. `element.ustlText`) so the draw override can access it.

### Text alignment with ALIGN_CENTER
`RenderText.ALIGN_CENTER` centers text within the `TextElement`'s `absSize` width, starting from `absPosition[1]`. So to center text in a box:
- Set child `absPosition[1]` to the **left edge** of the box (NOT the midpoint)
- Set child `absSize[1]` to the full box width
- The engine centers the text within that span

Setting `absPosition[1]` to the midpoint with `ALIGN_CENTER` will render text starting from the midpoint, pushed to the right.

### TextElement format property
`format = 1` is PERCENTAGE format — it mangles non-percentage strings. Set `format = 0` for plain text display.

### ThreePartBitmapElement has no setText()
Text must be set on the child `TextElement` (at `element.elements[1]`), not on the ThreePartBitmap itself.

### Cell recycling
Cells are recycled as the user scrolls. Cloned elements persist on the cell, so use a flag (e.g. `cell.ustlTimeLeft`) to track whether the element has already been created. Hide with `setVisible(false)` when the cell shows a non-sale item.

## Used sale item data structure
Used sale items are identified by `displayItem.saleItem ~= nil`. The `saleItem` table contains:
- `id` — sale ID (integer)
- `xmlFilename` — vehicle XML path (string)
- `timeLeft` — hours remaining before removal (number) **← this is what we display**
- `price` — sale price (number)
- `age` — age in months (number)
- `wear` — wear level 0-1 (number)
- `damage` — damage level 0-1 (number)
- `operatingTime` — operating time in ms (number)
- `isGenerated` — whether auto-generated by the game (boolean)
- `boughtConfigurations` — table of configurations

The sale system is at `g_currentMission.vehicleSaleSystem` (items are empty at `loadMap` time — only populated later).

## Game source reference
Game Lua source is in `G:\Steam\steamapps\common\Farming Simulator 25\sdk\debugger\gameSource.zip`. Extracted to `Examples/gameSource/` for reference. Note: most function bodies are stripped/empty — only signatures and comments are visible.

## FS25 Community Lua Documentation (online) — **CHECK HERE FIRST for any FS25 Lua API questions**
Community-maintained API docs at: https://github.com/umbraprior/FS25-Community-LUADOC/tree/main/docs
This is the primary reference for FS25 Lua commands and classes. Always consult these docs before falling back to the knowledge base PDFs or other sources.

### How to fetch raw files
Base URL: `https://raw.githubusercontent.com/umbraprior/FS25-Community-LUADOC/main/docs/`
All files are `.md` format. Append the path after `docs/`.

**Examples:**
- `https://raw.githubusercontent.com/umbraprior/FS25-Community-LUADOC/main/docs/script/GUI/ShopItemsFrame.md`
- `https://raw.githubusercontent.com/umbraprior/FS25-Community-LUADOC/main/docs/script/Utils/Utils.md`
- `https://raw.githubusercontent.com/umbraprior/FS25-Community-LUADOC/main/docs/engine/General/General.md`

**Important:** Some folder names contain spaces (e.g., `Particle System`, `Text Rendering`, `Tire Track`). URL-encode spaces as `%20` when fetching raw files.

### How to discover files in a folder
Use the GitHub API to list folder contents before fetching:
`https://api.github.com/repos/umbraprior/FS25-Community-LUADOC/contents/docs/{folder_path}`
This returns JSON with all files/subfolders. Use this to find the correct filename before fetching raw content.

### `docs/engine/` — Engine-level APIs (32 folders)
Low-level GIANTS engine bindings:
Animation, Camera, Debug, Entity, Fillplanes, Foliage, General, I3D, Input, Lighting, Math, NavMesh, Network, Node, NoteNode, Overlays, Particle%20System, Physics, PointList2D, Precipitation, Rendering, ShallowWaterSimulation, Shape, Sound, Spline, String, Terrain%20Detail, Terrain, Text%20Rendering, Tire%20Track, VoiceChat, XML.

### `docs/foundation/` — Foundation layer (2 folders)
Mid-level framework: Input, Scenegraph.

### `docs/script/` — Game script classes (54 folders) — **most relevant**
High-level game systems. All folders (★ = most relevant to this mod):
- AI, Activatables, Animals, Animation, Base, Boatyard, Collections, Components, Configurations, Contracts, Data, Debug
- ★ **Economy** (2 files) — economy/pricing systems
- ★ **Elements** (4 files) — UI element classes
- Errors (29 files)
- ★ **Events** (100+ files) — network events
- Extensions, Farms, Ferry, Field, FillTypes, Fruits, Graphical, Graphics
- ★ **GUI** (92 files) — UI framework and screens (**ShopItemsFrame is here**, not in Shop/)
- GuidedTour, Handtools
- ★ **Hud** (7 files) — HUD overlay elements
- I3d, Input, Instances, Jobs, Materials
- ★ **Misc** (25 files) — miscellaneous helpers
- Missions, Networking, Objects, Parameters, Placeables, Placement, Player, Rollercoaster, Ship
- ★ **Shop** (5 files) — shop system classes (StoreManager, etc. — but **not** ShopItemsFrame)
- Sounds, Specialization, Specializations (140+ files), StateMachine, Tasks, Triggers
- ★ **Utils** (16 files) — utility functions
- ★ **Vehicles** (20 files) — vehicle system
- Weather, Wheels

### Key files for this mod
- `script/GUI/ShopItemsFrame.md` — the main class we hook into
- `script/GUI/GuiElement.md` — base UI element class
- `script/Shop/StoreManager.md` — store/shop management
- `script/Utils/Utils.md` — utility functions (appendedFunction, etc.)
- `script/Misc/` — miscellaneous helpers

## Packaging
To create the mod zip: select the **contents** of `FS25_UsedSalesTimeLeft/` (not the folder itself) and zip them. The zip must be named `FS25_UsedSalesTimeLeft.zip` and placed in the game's `mods` folder.

## Testing - To be done manually.
Before creating a release ready version of the mod, these must be completed:
- Disable IS_DEBUG in UsedSalesTimeLeft.lua
- Test on a fresh save, no other mods, make sure the time left appears for the items in the shop.
- Modify the sales.xml file manually to test the following:
 - Remove all sales, the save with no sales produces no errors.
 - Have at least one sale per color, the mod displays everything correctly, with no errors.
- Test on a save with these mods enabled, the mod should work correctly, with no errors.
 - Xtreme Used Sales Unlocker
 - Sales Plus
 - TidyShop: ModTitles

## Language
Lua (FS25 scripting language)

## Knowledge base (`knowledge_base/`)
PDF reference books for FS modding. To extract text from these, use `py -X utf8` with the `pypdf` library (installed globally).

### Book_ScriptingFarmingSimulatorWithLua.pdf (343 pages) — **HIGH relevance**
"Scripting Farming Simulator with Lua: Unlocking the Virtual Fields" by Zander Brumbaugh & Manuel Leithner (2024, GIANTS Software, Open Access CC-BY-4.0).
- Ch 2: GIANTS Editor setup
- Ch 3: Lua programming fundamentals (variables, tables, loops, functions, classes)
- Ch 4: GIANTS Studio and debugging
- Ch 5-7: Practical mod projects (Diner, Rotating Mower, Speed Trap Trailer)
- **Ch 8: Mileage Counter HUD Mod** — most relevant chapter; script-only HUD mod similar to ours
- Ch 9: Multibale Spawner Mod
- Ch 10: Money Cheat Mod
- Ch 11: Publishing on ModHub
- **Ch 12: API reference appendix** — transforms, entities, physics, networking, I3D loading

### FarmingSimulatorModding_en.pdf (252 pages) — **MEDIUM relevance**
"Farming Simulator Modding For Dummies" by Jason van Gumster & Christian Ammann (2014, Wiley). Covers FS13/15 era — APIs may be outdated.
- Ch 1-5: GIANTS Editor, maps, terrain, materials, particles (not relevant to script mods)
- **Ch 6: modDesc.xml setup** — relevant for mod descriptor structure
- Ch 7-10: 3D modeling, textures, sounds (not relevant)
- **Ch 12: Defining New Objects and Behaviors with Lua** — specializations, `Utils.lua` patterns
- Ch 13: Packaging and distribution

### moddersGuideToTheModHubEN_v2.pdf (15 pages) — **LOW relevance (for now)**
"Modder's Guide to the ModHub" by GIANTS Software. Short guide on planning, uploading to ModHub, testing, feedback, and monetization. Useful when ready to publish.

### [ModHub Guidelines - Farming Simulator 25](https://forum.giants-software.com/viewtopic.php?t=209169) (forum post) — 
Official GIANTS forum post covering ModHub submission guidelines: testing process (5 stages), metadata standards (icons, screenshots, filenames), console requirements, description templates, and modder rewards/compensation. Useful when preparing to publish on ModHub.

### How to read PDFs programmatically
```bash
py -X utf8 -c "
from pypdf import PdfReader
r = PdfReader('knowledge_base/FILENAME.pdf')
print(f'Pages: {len(r.pages)}')
for i in range(START_PAGE, END_PAGE):
    print(r.pages[i].extract_text())
"
```
Note: page indices are 0-based (page 1 = index 0).
