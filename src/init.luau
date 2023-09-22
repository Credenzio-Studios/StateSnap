local RunService = game:GetService("RunService")

local Types = require(script.Types)
local Vault = require(script.Vault)
local Snapshot = require(script.Snapshot)

export type CollectorFunction = (serverTime: number) -> Types.StateList

--- 
local StateSnap = {
    Vault = Vault,
    Snapshot = Snapshot
}

local heartbeatConnection
local collectors: { CollectorFunction } = {}
local tickdelay = 1 / 20

--- Set the `saveDuration`, the length of time that Snapshots will remain in the Vault before removal
function StateSnap.SetSaveDuration(saveDuration: number)
    Vault.SetMaxSize(math.ceil((1 / tickdelay) * saveDuration))
end

--- Set the `tickrate`, the amount of times per second that Snapshots will be captured
function StateSnap.SetTickrate(tickrate: number)
    local saveDuration = Vault.GetMaxSize() / (1 / tickdelay)

    tickdelay = 1 / tickrate

    StateSnap.SetSaveDuration(saveDuration)
end

--- Starts capturing Snapshots each tick, adding them to the Vault.
--- Every time a Snapshot is captured, the StateList is aggregated from the results of each Collector function
function StateSnap.Start()
    StateSnap.Stop()

    local lastSnapshotTime = 0
    local function OnHeartbeat()
        local currentTime = workspace:GetServerTimeNow()

        if currentTime - lastSnapshotTime >= tickdelay then
            local stateList = {}

            for _, collector in ipairs(collectors) do
                local states = collector(currentTime)

                if type(states) == 'table' then
                    table.move(states, 1, #states, #stateList + 1, stateList)
                end
            end

            local snapshot = Snapshot.new(currentTime, stateList)
            Vault.Add(snapshot)
        end
    end

    heartbeatConnection = RunService.Heartbeat:Connect(OnHeartbeat)
end

--- Stops the capturing of Snapshots each tick
function StateSnap.Stop()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
end

--- Adds a Collector function that will be called every tick by the Snapshot aggregator to generate a list of State objects.
--- Each State object returned should be a new object; they should not be reused over multiple calls
function StateSnap.AddCollector(collector: CollectorFunction)
    if type(collector) ~= 'function' then
        error("Invalid type for argument 'collector': a function was expected", 2)
    end

    if not table.find(collectors, collector) then
        table.insert(collectors, collector)
    end
end

--- Removes a Collector function, preventing it from being called by the Snapshot aggregator unless it is added again
function StateSnap.RemoveCollector(collector: CollectorFunction)
    if type(collector) ~= 'function' then
        error("Invalid type for argument 'collector': a function was expected", 2)
    end
    
    local index = table.find(collectors, collector)

    if index then
        table.remove(collectors, index)
    end
end

return StateSnap