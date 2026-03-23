--
-- DebugUtils
-- Debug and logging utilities for UsedSalesTimeLeft.
--
-- Author: Retofel
--

DebugUtils = {}
DebugUtils.IS_DEBUG = false -- Set to true to enable debug logging

--- Prints a debug message to the game log when IS_DEBUG is enabled.
-- @param string message The message to print
function DebugUtils.debugLog(message)
    if DebugUtils.IS_DEBUG then
        print("USTL: " .. message)
    end
end

--- Prints an error message to the game log (always, regardless of IS_DEBUG).
-- @param string message The error message to print
function DebugUtils.errorLog(message)
    print("USTL ERROR: " .. message)
end

--- Logs details of a used sale item for debugging.
-- @param integer section The shop list section index
-- @param integer index The item index within the section
-- @param table sale The saleItem table containing item data
function DebugUtils.debugLogSaleItem(section, index, sale)
    DebugUtils.debugLog(string.format(
        "ITEM - section=%d index=%d id=%s xmlFilename=%s timeLeft=%s price=%d age=%s wear=%.2f damage=%.2f",
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
function DebugUtils.debugLogCellAttributes(cell)
    if not DebugUtils.IS_DEBUG then
        return
    end
    for name, element in pairs(cell.attributes) do
        local colorInfo = ""
        if element.overlay ~= nil and element.overlay.color ~= nil then
            local c = element.overlay.color
            colorInfo = string.format(" overlayColor=%.2f,%.2f,%.2f,%.2f", c[1], c[2], c[3], c[4])
        end
        DebugUtils.debugLog(string.format(
            "Cell attr: name=%s children=%d%s",
            tostring(name), #element.elements, colorInfo
        ))
    end
end

--- Logs all color state values of a cloned element for debugging.
-- @param table box The ThreePartBitmapElement to inspect
function DebugUtils.debugLogColors(box)
    if not DebugUtils.IS_DEBUG then
        return
    end
    local function fmtColor(c)
        if c == nil then return "nil" end
        return string.format("%.2f,%.2f,%.2f,%.2f", c[1], c[2], c[3], c[4])
    end
    if box.overlay then
        DebugUtils.debugLog("Box overlay.color: " .. fmtColor(box.overlay.color))
        DebugUtils.debugLog("Box overlay.colorFocused: " .. fmtColor(box.overlay.colorFocused))
        DebugUtils.debugLog("Box overlay.colorSelected: " .. fmtColor(box.overlay.colorSelected))
        DebugUtils.debugLog("Box overlay.colorHighlighted: " .. fmtColor(box.overlay.colorHighlighted))
    end
    local textChild = box.elements[1]
    if textChild then
        DebugUtils.debugLog("Text textColor: " .. fmtColor(textChild.textColor))
        DebugUtils.debugLog("Text textSelectedColor: " .. fmtColor(textChild.textSelectedColor))
        DebugUtils.debugLog("Text textFocusedColor: " .. fmtColor(textChild.textFocusedColor))
        DebugUtils.debugLog("Text textHighlightedColor: " .. fmtColor(textChild.textHighlightedColor))
    end
end
