--
-- UsedSalesTimeLeft
-- Shows remaining time (in hours) for items in the used vehicle shop.
--
-- Author: Retofel
--

UsedSalesTimeLeft = {}
UsedSalesTimeLeft.TEXT_FORMAT = "%dh left" -- Format string for the time left label (%d = hours remaining)
UsedSalesTimeLeft.IS_DEBUG = false -- Set to true to enable debug logging

--- Prints a debug message to the game log when IS_DEBUG is enabled.
-- @param string message The message to print
function UsedSalesTimeLeft.debugLog(message)
    if UsedSalesTimeLeft.IS_DEBUG then
        print("USTL: " .. message)
    end
end

--- Prints an error message to the game log (always, regardless of IS_DEBUG).
-- @param string message The error message to print
function UsedSalesTimeLeft.errorLog(message)
    print("USTL ERROR: " .. message)
end

--- Logs details of a used sale item for debugging.
-- @param integer section The shop list section index
-- @param integer index The item index within the section
-- @param table sale The saleItem table containing item data
function UsedSalesTimeLeft.debugLogSaleItem(section, index, sale)
    UsedSalesTimeLeft.debugLog(string.format(
        "USTL ITEM - section=%d index=%d id=%s xmlFilename=%s timeLeft=%s price=%d age=%s wear=%.2f damage=%.2f",
        section, index,
        tostring(sale.id),
        tostring(sale.xmlFilename),
        tostring(sale.timeLeft),
        math.floor(sale.price or 0),
        tostring(sale.age),
        sale.wear or 0,
        sale.damage or 0
    ))
end

--- Logs all attributes of a shop list cell for debugging (names, child counts, overlay colors).
-- Only runs when IS_DEBUG is enabled. Used to discover cell attribute names.
-- @param table cell The ListItemElement cell to inspect
function UsedSalesTimeLeft.debugLogCellAttributes(cell)
    if not UsedSalesTimeLeft.IS_DEBUG then
        return
    end
    for name, element in pairs(cell.attributes) do
        local colorInfo = ""
        if element.overlay ~= nil and element.overlay.color ~= nil then
            local c = element.overlay.color
            colorInfo = string.format(" overlayColor=%.2f,%.2f,%.2f,%.2f", c[1], c[2], c[3], c[4])
        end
        UsedSalesTimeLeft.debugLog(string.format(
            "Cell attr: name=%s children=%d%s",
            tostring(name), #element.elements, colorInfo
        ))
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
    UsedSalesTimeLeft.debugLogSaleItem(section, index, sale)

    local discountElement = cell:getAttribute("priceTag")
    if discountElement == nil then
        return
    end

    if cell.ustlTimeLeft == nil then
        UsedSalesTimeLeft.createTimeLeftBox(discountElement, cell)
    end

    cell.ustlTimeLeft:setVisible(true)
    -- Set text on the child TextElement (ThreePartBitmap has no setText)
    local timeText = string.format(UsedSalesTimeLeft.TEXT_FORMAT, math.floor(sale.timeLeft))
    cell.ustlTimeLeft.ustlText = timeText -- store for draw override auto-sizing
    local textChild = cell.ustlTimeLeft.elements[1]
    if textChild ~= nil then
        textChild:setText(timeText)
    end
    UsedSalesTimeLeft.debugLog(string.format(
        "timeLeft absPos=%.4f,%.4f absSize=%.4f,%.4f cellAbsPos=%.4f",
        cell.ustlTimeLeft.absPosition[1], cell.ustlTimeLeft.absPosition[2],
        cell.ustlTimeLeft.absSize[1], cell.ustlTimeLeft.absSize[2],
        cell.absPosition[1]
    ))
end

--- FS25 mod lifecycle callback — called when a save game is loaded.
-- Hooks into ShopItemsFrame.populateCellForItemInSection to display
-- time remaining on used sale items in the shop UI.
function UsedSalesTimeLeft:loadMap(filename)
    UsedSalesTimeLeft.debugLog("loadMap called")

    if ShopItemsFrame == nil then
        UsedSalesTimeLeft.debugLog("ShopItemsFrame is nil!")
        return
    end

    ShopItemsFrame.populateCellForItemInSection = Utils.overwrittenFunction(
        ShopItemsFrame.populateCellForItemInSection,
        function(self, superFunc, list, section, index, cell, ...)
            local returnValue = superFunc(self, list, section, index, cell, ...)

            local ok, err = pcall(function()
                local displayItem = self.displayItems[index]
                UsedSalesTimeLeft.debugLogCellAttributes(cell)

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
                UsedSalesTimeLeft.errorLog(tostring(err))
            end

            return returnValue
        end
    )
    UsedSalesTimeLeft.debugLog("Hooked into ShopItemsFrame.populateCellForItemInSection")
end

--- FS25 mod lifecycle callback — called when the map is unloaded. Required by addModEventListener.
function UsedSalesTimeLeft:deleteMap()
end

-- Register with FS25's mod event system to receive loadMap/deleteMap lifecycle callbacks
addModEventListener(UsedSalesTimeLeft)
