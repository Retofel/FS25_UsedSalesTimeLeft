--
-- UsedSalesTimeLeft
-- Shows remaining time (in hours) for items in the used vehicle shop.
--
-- Author: Retofel
--

UsedSalesTimeLeft = {}

function UsedSalesTimeLeft:loadMap(filename)
    if InGameMenuShopFrame ~= nil then
        InGameMenuShopFrame.onButtonUsedVehicles = Utils.appendedFunction(
            InGameMenuShopFrame.onButtonUsedVehicles,
            function()
                print("---------------------------------------Mod loaded")
            end
        )
    end
end

function UsedSalesTimeLeft:deleteMap()
end

addModEventListener(UsedSalesTimeLeft)
