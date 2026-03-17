--
-- UsedSalesTimeLeft
-- Shows remaining time (in hours) for items in the used vehicle shop.
--
-- Author: Retofel
--

UsedSalesTimeLeft = {}
UsedSalesTimeLeft.TEXT_FORMAT = "%dh left" -- Format string for the time left label (%d = hours remaining)
UsedSalesTimeLeft.FONT_SIZE_FACTOR = 0.7 -- Font size as a fraction of the value cell's text size
UsedSalesTimeLeft.IS_DEBUG = false -- Set to true to enable debug logging

function UsedSalesTimeLeft.debugLog(message)
    if UsedSalesTimeLeft.IS_DEBUG then
        print("USTL: " .. message)
    end
end

function UsedSalesTimeLeft.errorLog(message)
    print("USTL ERROR: " .. message)
end

function UsedSalesTimeLeft.debugLogSaleItem(section, index, sale)
    UsedSalesTimeLeft.debugLog(string.format(
        "USED SALE ITEM - section=%d index=%d id=%s xmlFilename=%s timeLeft=%s price=%d age=%s wear=%.2f damage=%.2f",
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

--- FS25 mod lifecycle callback — called when a save game is loaded.
-- Sets up our hook into the shop UI to display time remaining on used sale items.
function UsedSalesTimeLeft:loadMap(filename)
    UsedSalesTimeLeft.debugLog("loadMap called")

    -- Hook into ShopItemsFrame.populateCellForItemInSection
    -- This runs for each item displayed in the shop list
    if ShopItemsFrame ~= nil then
        ShopItemsFrame.populateCellForItemInSection = Utils.overwrittenFunction(
            ShopItemsFrame.populateCellForItemInSection,
            -- superFunc is the original function — FS25's overwrittenFunction pattern
            -- passes it as the second arg so we can call the base implementation first.
            function(self, superFunc, list, section, index, cell, ...)
                -- Always run the original function first, unprotected
                local returnValue = superFunc(self, list, section, index, cell, ...)

                -- Wrap all mod logic in pcall so errors never crash the game
                local ok, err = pcall(function()
                    local displayItem = self.displayItems[index]
                    if displayItem ~= nil and displayItem.saleItem ~= nil then
                        local sale = displayItem.saleItem
                        UsedSalesTimeLeft.debugLogSaleItem(section, index, sale)

                        -- Add or update the time left display
                        local valueCell = cell:getAttribute("value")
                        local priceTagCell = cell:getAttribute("priceTag")
                        if cell.ustlTimeLeft == nil then
                            -- Clone valueCell to inherit its font family, style, and rendering properties
                            local timeLeftElement = valueCell:clone()
                            timeLeftElement.name = "ustlTimeLeft"
                            timeLeftElement.textUpperCase = false
                            timeLeftElement.textAlignment = RenderText.ALIGN_LEFT
                            -- setText() internally resets textSize to defaultTextSize, so we must set both
                            -- to prevent the cloned original size from overriding our scaled-down size
                            local desiredSize = valueCell.textSize * UsedSalesTimeLeft.FONT_SIZE_FACTOR
                            timeLeftElement.defaultTextSize = desiredSize
                            timeLeftElement.textSize = desiredSize
                            -- Position at bottom-left, same vertical as priceTag
                            local pos = priceTagCell.position
                            timeLeftElement:setPosition(0, pos[2]) -- left edge, same Y as priceTag
                            cell:addElement(timeLeftElement)
                            cell.ustlTimeLeft = timeLeftElement
                        end
                        cell.ustlTimeLeft:setTextColor(1, 1, 1, 1) -- white, full opacity (RGBA)
                        cell.ustlTimeLeft:setText(string.format(UsedSalesTimeLeft.TEXT_FORMAT, math.floor(sale.timeLeft)))
                    else
                        -- Cell is recycled for a non-sale item, hide our element if it exists
                        if cell.ustlTimeLeft ~= nil then
                            cell.ustlTimeLeft:setText("")
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
    else
        UsedSalesTimeLeft.debugLog("ShopItemsFrame is nil!")
    end
end

--- FS25 mod lifecycle callback — called when the map is unloaded. Required by addModEventListener.
function UsedSalesTimeLeft:deleteMap()
end

-- Register with FS25's mod event system to receive loadMap/deleteMap lifecycle callbacks
addModEventListener(UsedSalesTimeLeft)
