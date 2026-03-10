--
-- UsedSalesTimeLeft
-- Shows remaining time (in hours) for items in the used vehicle shop.
--
-- Author: Retofel
--

UsedSalesTimeLeft = {}

function UsedSalesTimeLeft:loadMap(filename)
    print("USTL: loadMap called")

    -- Hook into ShopItemsFrame.populateCellForItemInSection
    -- This runs for each item displayed in the shop list
    if ShopItemsFrame ~= nil then
        ShopItemsFrame.populateCellForItemInSection = Utils.overwrittenFunction(
            ShopItemsFrame.populateCellForItemInSection,
            function(self, superFunc, list, section, index, cell, ...)
                local returnValue = superFunc(self, list, section, index, cell, ...)

                local displayItem = self.displayItems[index]
                if displayItem ~= nil and displayItem.saleItem ~= nil then
                    local sale = displayItem.saleItem
                    print(string.format(
                        "USTL: USED SALE ITEM - section=%d index=%d id=%s xmlFilename=%s timeLeft=%s price=%d age=%s wear=%.2f damage=%.2f",
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

                return returnValue
            end
        )
        print("USTL: Hooked into ShopItemsFrame.populateCellForItemInSection")
    else
        print("USTL: ShopItemsFrame is nil!")
    end
end

function UsedSalesTimeLeft:deleteMap()
end

addModEventListener(UsedSalesTimeLeft)
