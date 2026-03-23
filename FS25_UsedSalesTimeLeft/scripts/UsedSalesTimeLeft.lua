--
-- UsedSalesTimeLeft
-- Shows remaining time (in hours) for items in the used vehicle shop.
--
-- Author: Retofel
--

UsedSalesTimeLeft = {}
UsedSalesTimeLeft.TEXT_FORMAT = "%dh left" -- Format string for the time left label (%d = hours remaining)

-- Box background colors (RGBA, 0-1 range)
UsedSalesTimeLeft.COLOR_GREEN = {0.22, 0.41, 0.00, 1.00}
UsedSalesTimeLeft.COLOR_YELLOW = {0.70, 0.40, 0.00, 1.00}
UsedSalesTimeLeft.COLOR_RED = {0.85, 0.08, 0.08, 1.00}

-- Time thresholds (hours) for color selection
UsedSalesTimeLeft.MIN_THRESHOLD_GREEN = 5   -- 5h+ = green
UsedSalesTimeLeft.MIN_THRESHOLD_ORANGE = 3  -- 3-4h = orange
UsedSalesTimeLeft.MIN_THRESHOLD_RED = 1     -- 1-2h = red

--- Returns the appropriate color for the given time left.
-- @param number timeLeft Hours remaining
-- @return table RGBA color table
function UsedSalesTimeLeft.getColorForTimeLeft(timeLeft)
    local hours = math.floor(timeLeft)
    if hours >= UsedSalesTimeLeft.MIN_THRESHOLD_GREEN then
        return UsedSalesTimeLeft.COLOR_GREEN
    elseif hours >= UsedSalesTimeLeft.MIN_THRESHOLD_ORANGE then
        return UsedSalesTimeLeft.COLOR_YELLOW
    else
        return UsedSalesTimeLeft.COLOR_RED
    end
end

--- Applies a color to the time-left box background and text for all GUI states.
-- Normal state: colored background with black text.
-- Selected/focused/highlighted states: black background with colored text (inverted).
-- @param table timeLeftBox The ThreePartBitmapElement to colorize
-- @param table color RGBA table {r, g, b, a} for the desired color
function UsedSalesTimeLeft.applyBoxColor(timeLeftBox, color)
    local r, g, b, a = color[1], color[2], color[3], color[4]

    -- Set box background color for each state
    -- Focused/highlighted fall back to normal (colored bg); only selected inverts to black
    timeLeftBox:setImageColor(GuiOverlay.STATE_NORMAL, r, g, b, a)
    timeLeftBox:setImageColor(GuiOverlay.STATE_FOCUSED, r, g, b, a)
    timeLeftBox:setImageColor(GuiOverlay.STATE_SELECTED, 0, 0, 0, 1)
    timeLeftBox:setImageColor(GuiOverlay.STATE_HIGHLIGHTED, r, g, b, a)

    -- Set text child colors to match: black text normally, colored text when selected
    local textChild = timeLeftBox.elements[1]
    if textChild ~= nil then
        textChild:setTextColor(0, 0, 0, 1)
        textChild:setTextSelectedColor(r, g, b, a)
        textChild:setTextFocusedColor(0, 0, 0, 1)
        textChild:setTextHighlightedColor(0, 0, 0, 1)
    end
end

--- Clones the discount box element and configures it as a time-left display.
-- Creates a ThreePartBitmapElement clone with the discount box's styled background,
-- font, and state-dependent colors. Installs a draw() override to force left-side
-- positioning and auto-size width to fit text content.
-- @param table discountElement The priceTag ThreePartBitmapElement to clone from
-- @param table cell The ListItemElement cell to attach the clone to
-- @return table The created time-left box element
function UsedSalesTimeLeft.createTimeLeftBox(discountElement, cell)
    local timeLeftBox = discountElement:clone()
    timeLeftBox.name = "ustlTimeLeft"

    DebugUtils.debugLogColors(timeLeftBox)

    -- Fix child text: disable percentage format, ensure center alignment
    local initChild = timeLeftBox.elements[1]
    if initChild ~= nil then
        initChild.format = 0 -- disable PERCENTAGE format
        initChild.textAlignment = RenderText.ALIGN_CENTER
    end

    -- Override draw() to force left-side positioning and auto-size
    -- width to fit text content at render time.
    local cellRef = cell
    local origDraw = timeLeftBox.draw
    timeLeftBox.draw = function(drawSelf, clipX1, clipY1, clipX2, clipY2)
        -- Auto-size width to fit text content
        local textChild = drawSelf.elements[1]
        if textChild ~= nil and drawSelf.ustlText ~= nil then
            setTextBold(textChild.textBold or false)
            local tw = getTextWidth(textChild.textSize or 0.01852, drawSelf.ustlText)
            setTextBold(false)
            local padding = 0.005
            drawSelf.absSize[1] = tw + padding
            textChild.absSize[1] = drawSelf.absSize[1]
        end

        -- Force position to left side of cell
        local desiredX = cellRef.absPosition[1] + 0.0130
        drawSelf.absPosition[1] = desiredX
        -- Align children to span full box width (ALIGN_CENTER centers text within absSize)
        for _, child in ipairs(drawSelf.elements) do
            child.absPosition[1] = desiredX
            child.absSize[1] = drawSelf.absSize[1]
        end
        origDraw(drawSelf, clipX1, clipY1, clipX2, clipY2)
    end

    cell:addElement(timeLeftBox)
    cell.ustlTimeLeft = timeLeftBox

    return timeLeftBox
end

--- Shows or updates the time-left box on a sale item cell.
-- Gets the priceTag discount element, creates the time-left box if it doesn't exist yet,
-- then sets the text to show hours remaining.
-- @param table cell The ListItemElement cell to update
-- @param table sale The saleItem table containing timeLeft data
-- @param integer section The shop list section index (for debug logging)
-- @param integer index The item index within the section (for debug logging)
function UsedSalesTimeLeft.updateTimeLeftDisplay(cell, sale, section, index)
    DebugUtils.debugLogSaleItem(section, index, sale)

    local discountElement = cell:getAttribute("priceTag")
    if discountElement == nil then
        return
    end

    if cell.ustlTimeLeft == nil then
        UsedSalesTimeLeft.createTimeLeftBox(discountElement, cell)
    end

    cell.ustlTimeLeft:setVisible(true)
    -- Apply color based on time remaining
    local color = UsedSalesTimeLeft.getColorForTimeLeft(sale.timeLeft)
    UsedSalesTimeLeft.applyBoxColor(cell.ustlTimeLeft, color)
    -- Set text on the child TextElement (ThreePartBitmap has no setText)
    local timeText = string.format(UsedSalesTimeLeft.TEXT_FORMAT, math.floor(sale.timeLeft))
    cell.ustlTimeLeft.ustlText = timeText -- store for draw override auto-sizing
    local textChild = cell.ustlTimeLeft.elements[1]
    if textChild ~= nil then
        textChild:setText(timeText)
    end
    DebugUtils.debugLog(string.format(
        "timeLeft absPos=%.4f,%.4f absSize=%.4f,%.4f cellAbsPos=%.4f",
        cell.ustlTimeLeft.absPosition[1], cell.ustlTimeLeft.absPosition[2],
        cell.ustlTimeLeft.absSize[1], cell.ustlTimeLeft.absSize[2],
        cell.absPosition[1]
    ))
end

--- FS25 mod lifecycle callback - called when a save game is loaded.
-- Hooks into ShopItemsFrame.populateCellForItemInSection to display
-- time remaining on used sale items in the shop UI.
function UsedSalesTimeLeft:loadMap(filename)
    DebugUtils.debugLog("loadMap called")

    if ShopItemsFrame == nil then
        DebugUtils.debugLog("ShopItemsFrame is nil!")
        return
    end

    ShopItemsFrame.populateCellForItemInSection = Utils.overwrittenFunction(
        ShopItemsFrame.populateCellForItemInSection,
        function(self, superFunc, list, section, index, cell, ...)
            local returnValue = superFunc(self, list, section, index, cell, ...)

            local ok, err = pcall(function()
                -- displayItems[index] maps 1:1 with list rows; saleItem is non-nil only for used-sale entries
                local displayItem = self.displayItems[index]
                DebugUtils.debugLogCellAttributes(cell)

                if displayItem ~= nil and displayItem.saleItem ~= nil then
                    UsedSalesTimeLeft.updateTimeLeftDisplay(cell, displayItem.saleItem, section, index)
                else
                    -- Cell is recycled for a non-sale item, hide our element if it exists
                    if cell.ustlTimeLeft ~= nil then
                        cell.ustlTimeLeft:setVisible(false)
                    end
                end
            end)

            if not ok then
                DebugUtils.errorLog(tostring(err))
            end

            return returnValue
        end
    )
    DebugUtils.debugLog("Hooked into ShopItemsFrame.populateCellForItemInSection")
end

--- FS25 mod lifecycle callback - called when the map is unloaded. Required by addModEventListener.
function UsedSalesTimeLeft:deleteMap()
end

-- Register with FS25's mod event system to receive loadMap/deleteMap lifecycle callbacks
addModEventListener(UsedSalesTimeLeft)
