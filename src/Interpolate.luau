local Types = require(script.Parent.Types)

local clamp = math.clamp
local acos = math.acos
local cos = math.cos
local sin = math.sin

local pi = math.pi
local pi2 = math.pi * 2

local function Lerp(v0: number, v1: number, t: number)
    return v0 + (v1 - v0) * t
end

local function DegreeLerp(v0: number, v1: number, t: number)
    local result
    local diff = v1 - v0

    if diff < -180 then
        v1 += 360
        result = Lerp(v0, v1, t)

        if result >= 360 then
            result -= 360
        end
    elseif diff > 180 then
        v1 -= 360
        result = Lerp(v0, v1, t)

        if result < 0 then
            result += 360
        end
    else
        result = Lerp(v0, v1, t)
    end

    return result
end

local function RadianLerp(v0: number, v1: number, t: number)
    local result
    local diff = v1 - v0

    if diff < -pi then
        v1 += pi2
        result = Lerp(v0, v1, t)

        if result >= 360 then
            result -= 360
        end
    elseif diff > pi then
        v1 -= pi2
        result = Lerp(v0, v1, t)

        if result < 0 then
            result += pi2
        end
    else
        result = Lerp(v0, v1, t)
    end

    return result
end

local function Slerp(v0: Vector3, v1: Vector3, t: number)
    local dot = clamp(v0:Dot(v1), -1, 1)
    local theta = acos(dot) * t
    local relVec = (v1 - v0 * dot).Unit

    return v0 * cos(theta) + relVec * sin(theta)
end

local function Interpolate(method: string, old: Types.Value, new: Types.Value, t: number)
    if old == nil then
        return new
    elseif new == nil then
        return old
    end

    local to, tn = typeof(old), typeof(new)

    if to ~= tn then
        error("Cannot interpolate values of different types, got: '"..to.."' and '"..tn.."'", 2)
    end

    if to == 'number' then
        if method == 'linear' then
            return Lerp(old::number, new::number, t)
        elseif method == 'degree' then
            return DegreeLerp(old::number, new::number, t)
        elseif method == 'radian' then
            return RadianLerp(old::number, new::number, t)
        end
    elseif to == 'Vector3' then
        if method == 'linear' then
            return (old::Vector3):Lerp(new::Vector3, t)
        elseif method == 'spherical' then
            return Slerp(old::Vector3, new::Vector3, t)
        end
    elseif to == 'CFrame' then
        return (old::CFrame):Lerp(new::CFrame, t)
    else
        error("Cannot interpolate values of type '"..to.."'", 2)
    end

    error("No interpolation method '"..method.."' found for '"..to.."'", 2)
end

return {
    Interpolate = Interpolate
}