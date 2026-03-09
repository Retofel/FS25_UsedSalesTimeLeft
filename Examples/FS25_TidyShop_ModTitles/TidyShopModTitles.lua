--[[
TidyShop: Mod Titles simply enhances the way mod titles is displayed in the store, making the title cleaner and more informative

Author:     w33zl
Version:    2.0.0
Modified:   2024-11-20

Changelog:
	2.0.0	FS25 Version
]]

TSModTitles = Mod:init()


ShopItemsFrame.populateCellForItemInSection = Utils.overwrittenFunction(ShopItemsFrame.populateCellForItemInSection, function(self, superFunc, list, section, index, cell, ...)
    -- Log:debug("ShopItemsFrame.populateCellForItemInSection")
    
    local returnValue = superFunc(self, list, section, index, cell, ...)
    if cell ~= nil then
        local displayItem = self.displayItems[index]
        local storeItem = displayItem.storeItem
        local modDlcCell = cell:getAttribute("modDlc")
        local priceTagCell = cell:getAttribute("priceTag")
        local valueCell = cell:getAttribute("value")
        local customEnvironment = storeItem.customEnvironment

        -- local modDlcCell2 = cell:getAttribute("modDlcCell2")
        -- if modDlcCell2 == nil then
        --     modDlcCell2 = modDlcCell:clone()
        --     modDlcCell2.name = "modDlcCell2"
        --     modDlcCell2:setPosition(0, 20)
        --     cell:addElement(modDlcCell2)
        -- end

        if not valueCell.isTidyShopOffset then
            valueCell.isTidyShopOffset = true

            local pos = valueCell.position
            valueCell:setPosition(pos[1], pos[2] - (g_pixelSizeY * 12))

            local pos2 = modDlcCell.position
            modDlcCell:setPosition(pos2[1], pos2[2] - (g_pixelSizeY * 3))
        end

        if storeItem.dlcTitle and storeItem.dlcTitle ~= "" and customEnvironment and customEnvironment ~= "" then
            local mod = g_modManager.nameToMod[customEnvironment]
            local author = mod.author or ""
            local version = mod.version or ""
            modDlcCell.textUpperCase = false
            modDlcCell:setText(string.format("%s\n[%s, %s]", storeItem.dlcTitle, version, author))
            -- local newSize = modDlcCell.textSize * 0.1
            -- modDlcCell:setTextSize(newSize)
            -- modDlcCell:updateSize()
            -- local z = getTextHeight(modDlcCell.textSize, "HHMMM")
        end
    end
    return returnValue
end)

-- ShopItemsFrame.onFrameOpen = Utils.overwrittenFunction(ShopItemsFrame.onFrameOpen, function(self, superFunc, ...)
--     Log:debug("ShopItemsFrame.onFrameOpen")
--     Log:table("elements", self.elements, 1)
--     return superFunc(self, ...)
-- end)

-- onStoreItemsReloaded

-- ShopController.load = Utils.overwrittenFunction(ShopController.load, function(self, superFunc, ...)
-- 	Log:debug("ShopController.load override")
-- 	superFunc(self, ...)	
-- end)