--
-- UsedSalesTimeLeftSync
-- Multiplayer synchronisation of saleItem.timeLeft.
--
-- The base game replicates every field of a used sale item to clients via VehicleSaleAddEvent
-- EXCEPT timeLeft, and VehicleSaleSystem:onHourChanged() only decrements it under
-- mission:getIsServer(). A client therefore has no value at all, and would still have a frozen
-- one if it were only sent once. This file closes both gaps:
--   1. timeLeft is appended to VehicleSaleAddEvent's stream, giving clients the initial value
--      when a sale is created and when they join.
--   2. UsedSalesTimeLeftSyncEvent re-broadcasts every sale's current value each in-game hour,
--      so client values keep counting down and any drift self-corrects within the hour.
--
-- Author: Retofel
-- Based on a code fix suggested by Hauklotz for issue #27 - https://github.com/Retofel/FS25_UsedSalesTimeLeft/issues/27
--

-- Wire format ceilings. Anything written to a stream must be sanitised against these first,
-- because an error thrown inside writeStream happens during packet assembly and truncates the
-- byte stream, desyncing every event packed after it.
UsedSalesTimeLeft.MAX_STREAM_HOURS = 65535 -- streamWriteUInt16 ceiling
UsedSalesTimeLeft.MAX_STREAM_ITEMS = 255   -- streamWriteUInt8 count ceiling
UsedSalesTimeLeft.MAX_SALE_ID = 255        -- streamWriteUInt8 id ceiling (matches BuyVehicleData)

--- Converts a timeLeft value into an integer streamWriteUInt16 will always accept.
-- Sale mods legitimately set very large values, so clamping is silent by design - never
-- log an error here, ModHub requires an error-free log.
-- @param any timeLeft The raw value, which may be nil, fractional, negative, NaN or huge
-- @return integer A value in the range 0..MAX_STREAM_HOURS
function UsedSalesTimeLeft.toStreamHours(timeLeft)
    -- timeLeft ~= timeLeft is only true for NaN
    if type(timeLeft) ~= "number" or timeLeft ~= timeLeft then
        return 0
    end
    if timeLeft < 0 then
        return 0
    end
    if timeLeft > UsedSalesTimeLeft.MAX_STREAM_HOURS then
        return UsedSalesTimeLeft.MAX_STREAM_HOURS
    end
    return math.floor(timeLeft)
end

---------------------------------------------------------------------------------------------------
-- Part 1: piggyback timeLeft onto VehicleSaleAddEvent
---------------------------------------------------------------------------------------------------

--- Appended to VehicleSaleAddEvent:writeStream. Writes exactly 2 bytes after the vanilla fields.
-- The value is sanitised here rather than at construction because the event is built by the
-- base game, not by us.
-- @param table event The VehicleSaleAddEvent instance
-- @param integer streamId The network stream id
-- @param table connection The connection being written to
function UsedSalesTimeLeft.onSaleAddWriteStream(event, streamId, connection)
    local timeLeft = nil
    if event.saleItem ~= nil then
        timeLeft = event.saleItem.timeLeft
    end
    streamWriteUInt16(streamId, UsedSalesTimeLeft.toStreamHours(timeLeft))
end

--- Appended to VehicleSaleAddEvent:readStream. Reads the 2 bytes written above.
-- The read is unconditional so it always mirrors the write; only the assignment is guarded.
-- saleItem is the same table the vanilla read already handed to the sale system, so assigning
-- to it here still reaches the stored item.
-- @param table event The VehicleSaleAddEvent instance
-- @param integer streamId The network stream id
-- @param table connection The connection being read from
function UsedSalesTimeLeft.onSaleAddReadStream(event, streamId, connection)
    local timeLeft = streamReadUInt16(streamId)
    if event.saleItem ~= nil then
        event.saleItem.timeLeft = timeLeft
    end
end

---------------------------------------------------------------------------------------------------
-- Part 2: hourly re-sync event
---------------------------------------------------------------------------------------------------

--- Broadcasts the current timeLeft of every sale item from the server to all clients.
-- Sent once per in-game hour, after VehicleSaleSystem:onHourChanged() has decremented them.
UsedSalesTimeLeftSyncEvent = {}
local UsedSalesTimeLeftSyncEvent_mt = Class(UsedSalesTimeLeftSyncEvent, Event)

-- Registered unconditionally so the event id is identical on server and client, whatever else
-- may be missing on either side.
InitEventClass(UsedSalesTimeLeftSyncEvent, "UsedSalesTimeLeftSyncEvent")

--- Creates an empty instance. Called by the network layer on the receiving side.
-- @return table The new event instance
function UsedSalesTimeLeftSyncEvent.emptyNew()
    local self = Event.new(UsedSalesTimeLeftSyncEvent_mt)
    return self
end

--- Creates an instance to send.
-- @param table items Array of {id, timeLeft} entries, already validated for the wire format
-- @return table The new event instance
function UsedSalesTimeLeftSyncEvent.new(items)
    local self = UsedSalesTimeLeftSyncEvent.emptyNew()
    self.items = items
    return self
end

--- Writes the entry count followed by each id/timeLeft pair.
-- Only what the array holds is written, so the count can never diverge from the payload.
-- Entries are validated in buildAndBroadcastSync before the event is queued.
-- @param integer streamId The network stream id
-- @param table connection The connection being written to
function UsedSalesTimeLeftSyncEvent:writeStream(streamId, connection)
    local items = self.items
    streamWriteUInt8(streamId, #items)
    for _, entry in ipairs(items) do
        streamWriteUInt8(streamId, entry.id)
        streamWriteUInt16(streamId, entry.timeLeft)
    end
end

--- Mirrors writeStream, then applies the values.
-- @param integer streamId The network stream id
-- @param table connection The connection being read from
function UsedSalesTimeLeftSyncEvent:readStream(streamId, connection)
    local numItems = streamReadUInt8(streamId)
    local items = {}
    for i = 1, numItems do
        items[i] = {
            id = streamReadUInt8(streamId),
            timeLeft = streamReadUInt16(streamId)
        }
    end
    self.items = items
    self:run(connection)
end

--- Applies the received values to the local sale items.
-- connection:getIsServer() means this arrived from the server, so a server ignores the event
-- if a client ever tries to send one.
-- @param table connection The connection the event arrived on
function UsedSalesTimeLeftSyncEvent:run(connection)
    if not connection:getIsServer() then
        return
    end
    if g_currentMission == nil or g_currentMission.vehicleSaleSystem == nil then
        return
    end

    local vehicleSaleSystem = g_currentMission.vehicleSaleSystem
    for _, entry in ipairs(self.items) do
        local saleItem = vehicleSaleSystem:getSaleById(entry.id)
        if saleItem ~= nil then
            saleItem.timeLeft = entry.timeLeft
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Part 3: the hourly broadcast
---------------------------------------------------------------------------------------------------

--- Builds and sends the sync event. Called only through broadcastTimeLeftSync's pcall.
-- Every bail-out below is written to fail OPEN where a field name is uncertain: an absent or
-- renamed field must not silently disable synchronisation, which would reintroduce the bug
-- without any visible symptom on the server.
-- @param table vehicleSaleSystem The VehicleSaleSystem instance
function UsedSalesTimeLeft.buildAndBroadcastSync(vehicleSaleSystem)
    if vehicleSaleSystem.mission == nil or not vehicleSaleSystem.mission:getIsServer() then
        return
    end
    if vehicleSaleSystem.isEnabled == false then
        return
    end
    if g_server == nil or vehicleSaleSystem.items == nil or #vehicleSaleSystem.items == 0 then
        return
    end

    -- Nothing to sync to in single player
    local dynamicInfo = g_currentMission ~= nil and g_currentMission.missionDynamicInfo or nil
    if dynamicInfo ~= nil and dynamicInfo.isMultiplayer == false then
        return
    end

    -- Validate here, never inside writeStream, so the count always matches the payload
    local entries = {}
    for _, item in ipairs(vehicleSaleSystem.items) do
        if #entries >= UsedSalesTimeLeft.MAX_STREAM_ITEMS then
            break
        end
        local id = item.id
        if type(id) == "number" and id == math.floor(id)
            and id >= 1 and id <= UsedSalesTimeLeft.MAX_SALE_ID then
            entries[#entries + 1] = {
                id = id,
                timeLeft = UsedSalesTimeLeft.toStreamHours(item.timeLeft)
            }
        end
    end

    if #entries > 0 then
        g_server:broadcastEvent(UsedSalesTimeLeftSyncEvent.new(entries))
        DebugUtils.debugLog(string.format("Broadcast timeLeft sync for %d sale item(s)", #entries))
    end
end

--- Appended to VehicleSaleSystem:onHourChanged, which decrements timeLeft server-side.
-- The pcall keeps any failure of ours from propagating into the hour-changed dispatcher and
-- aborting listeners registered after us. Vanilla's decrement has already run at this point
-- (we are appended, not prepended), so sale expiry is unaffected either way.
-- @param table vehicleSaleSystem The VehicleSaleSystem instance
function UsedSalesTimeLeft.broadcastTimeLeftSync(vehicleSaleSystem)
    local ok, err = pcall(UsedSalesTimeLeft.buildAndBroadcastSync, vehicleSaleSystem)
    if not ok then
        DebugUtils.errorLog(tostring(err))
    end
end

---------------------------------------------------------------------------------------------------
-- Hook registration
---------------------------------------------------------------------------------------------------

-- Registered at script load, not in loadMap: the event hooks must be in place before the
-- network starts. Nil-checked so a future game patch renaming either class disables the sync
-- instead of throwing at load.
if VehicleSaleAddEvent ~= nil and VehicleSaleSystem ~= nil then
    VehicleSaleAddEvent.writeStream = Utils.appendedFunction(
        VehicleSaleAddEvent.writeStream, UsedSalesTimeLeft.onSaleAddWriteStream)
    VehicleSaleAddEvent.readStream = Utils.appendedFunction(
        VehicleSaleAddEvent.readStream, UsedSalesTimeLeft.onSaleAddReadStream)
    VehicleSaleSystem.onHourChanged = Utils.appendedFunction(
        VehicleSaleSystem.onHourChanged, UsedSalesTimeLeft.broadcastTimeLeftSync)
    DebugUtils.debugLog("Hooked into VehicleSaleAddEvent and VehicleSaleSystem.onHourChanged")
else
    DebugUtils.errorLog("VehicleSaleAddEvent or VehicleSaleSystem not found - multiplayer time sync disabled")
end
