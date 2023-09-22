local Snapshot = require(script.Parent.Snapshot)

--- A container for snapshots
local Vault = {}
local snapshots: { Snapshot.Snapshot } = {}
local maxSize: number = 120

--- Remove old snapshots from the Vault.
--- If specified, `offset` determines an amount of additional snapshots to be removed
local function PruneOld(offset : number?)
    local numSnapshots = #snapshots
    for _ = maxSize, numSnapshots - 1 + offset do
        table.remove(snapshots, maxSize)
    end
end

--- Gets the latest Snapshot
function Vault.GetLatest()
    return snapshots[1]
end

--- Get the Snapshots immediately before and after the given `time`
function Vault.Get(time: number)
    for i = 1, maxSize do
        local snapshot = snapshots[i]

        if snapshot.Time <= time then
            local callSnapshots = {
                Old = snapshot,
                New = snapshots[i - 1]
            }

            return callSnapshots
        end
    end

    return nil
end

--- Get the Snapshot closest to the given `time`
function Vault.GetClosest(time: number)
    local callSnapshots = Vault.Get(time)

    if callSnapshots then
        local old, new = math.abs(time - callSnapshots.Old.Time), callSnapshots.New and math.abs(time - callSnapshots.New.Time)

        if not new or new ~= new or new <= old then
            return callSnapshots.Old
        else
            return callSnapshots.New
        end
    end

    return nil
end

--- Add a Snapshot to the Vault & remove expired Snapshots
function Vault.Add(snapshot: Snapshot.Snapshot)
    PruneOld(1)

    table.insert(snapshots, 1, snapshot)
end

--- Set the max capacity of the Vault & remove expired Snapshots
function Vault.SetMaxSize(size: number)
    if type(size) ~= "number" then
        error("Invalid type for argument 'size': a number was expected", 2)
    end

    maxSize = size

    PruneOld()
end

--- Get the max capacity of the Vault
function Vault.GetMaxSize()
    return maxSize
end

return Vault