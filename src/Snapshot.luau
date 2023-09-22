local HttpService = game:GetService("HttpService")

local Interpolate = require(script.Parent.Interpolate)
local Types = require(script.Parent.Types)

local match = string.match
local function Trim(s)
   return match(s, '^()%s*$') and '' or match(s, '^%s*(.*%S)')
end

--- Contains State data representing a specific point in time
local Snapshot = {}
Snapshot.__index = Snapshot

--- Instantiates a new snapshot with the given `time` and `stateList`
function Snapshot.new(time: number?, stateList: Types.StateList?)
    local stateMap = {}

    if stateList then
        for idx, state in ipairs(stateList) do
            local id = state.Id
            if not id then
                error("Each state in the given stateList must have an 'Id'", 2)
            end

            stateMap[id] = idx
        end
    end

    local self = {
        Id = HttpService:GenerateGUID(false),
        Time = time or workspace:GetServerTimeNow(),
        StateList = stateList or {}::Types.StateList,
        StateMap = stateMap
    }

    setmetatable(self, Snapshot)

    return self
end

export type Snapshot = typeof(Snapshot.new())

--- Gets the State with the given `Id`
function Snapshot.Get(self: Snapshot, id: string)
    local index = self.StateMap[id]

    if index then
        return self.StateList[index]::Types.State?
    end

    return nil
end

--- Adds the given `state` to the Snapshot.
--- If a State with the same `state.Id` exists within the Snapshot, then that State will be removed from the Snapshot and replaced with `state`
function Snapshot.Add(self: Snapshot, state: Types.State)
    if state then
        local id = state.Id
        local input = state.Input
        local data = state.Data

        if not id or not input or not data then
            error("Invalid type for argument 'state': a table containing keys 'Id', 'Input' and 'Data' was expected", 2)
        end

        local index = self.StateMap[id]

        if index then
            self.StateList[index] = state
        else
            table.insert(self.StateList, state)
            self.StateMap[id] = #self.StateList
        end
    else
        error("Invalid type for argument 'state': a table containing keys 'Id', 'Input' and 'Data' was expected", 2)
    end
end

--- Interpolates between two Snapshots given the `timeOrPercentage` and a `parameters` string representing which state data keys should be interpolated.
--- For example, calling this function with timeOrPercentage = 0.5 and parameters = 'position' would give a result with any 'position' keys within State data to be interpolated 50% between `self` and `goal`
function Snapshot.Interpolate(self: Snapshot, goal: Snapshot, timeOrPercentage: number, parameters: string) : Types.InterpolatedSnapshot
    local new, old = goal, self

    if goal.Time < self.Time then
        new = self
        old = goal
    elseif goal.Time == self.Time
    or timeOrPercentage == 1 then
        return {
            Percentage = 1,
            OldId = old.Id,
            NewId = new.Id,
            StateList = table.clone(new.StateList),
            StateMap = table.clone(new.StateMap)
        }
    elseif timeOrPercentage == 0 then
        return {
            Percentage = 0,
            OldId = old.Id,
            NewId = new.Id,
            StateList = table.clone(old.StateList),
            StateMap = table.clone(old.StateMap)
        }
    end

    local p = timeOrPercentage
    local t0, t1 = new.Time, old.Time
    
    if p > 1 then
        local val = p - t0
        local max = t0 - t1

        p = val / max
    end

    local newStates = new.StateList
    local oldStateList = old.StateList
    local oldStateMap = old.StateMap
    local iStateList = table.create(#newStates)
    local iStateMap = {}

    local params = Trim(parameters):gsub('%w+', ' '):split(' ')

    for i, param in ipairs(params) do
        local matched = param:match('%w%(([%w]+)%)')
        local method = matched or 'linear'

        if matched then
            param = param:gsub('%(.+', '')
        end

        params[i] = nil
        params[param] = method
    end

    for _, state in ipairs(newStates) do
        local id = state.Id
        local oldStateIndex = oldStateMap[id]
        local oldState = oldStateIndex and oldStateList[oldStateIndex]
        local oldStateInput = oldState and oldState.Input
        local oldStateData = oldState and oldState.Data
        local iStateInput: { Types.StateInput } = {}
        local iStateData: Types.StateData = {}
        local iState : Types.State = {
            Id = id,
            Input = iStateInput,
            Data = iStateData
        }

        if oldStateInput then
            for _, input in ipairs(oldStateInput) do
                table.insert(iStateInput, input)
            end
        end

        for _, input in ipairs(state.Input) do
            table.insert(iStateInput, input)
        end

        for k, newV in pairs(state.Data) do
            local method = params[k]
            local oldV = oldStateData and oldStateData[k]
            if method and oldV then
                iStateData[k] = Interpolate.Interpolate(method, oldV, newV, p)
            else
                iStateData[k] = newV
            end
        end

        table.insert(iStateList, iState)
        iStateMap[id] = #iStateList
    end

    return {
        Percentage = p,
        OldId = old.Id,
        NewId = new.Id,
        StateList = iStateList,
        StateMap = iStateMap
    }
end

return Snapshot