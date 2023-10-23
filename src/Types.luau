export type Value = boolean | number | string | Vector3 | CFrame

export type StateInput = any

export type StateData = { [string]: Value }

export type State = {
    Id: string,
    Input: { StateInput },
    Data: StateData
}

export type StateList = { State }
export type StateMap = { [string]: State }

export type InterpolatedSnapshot = {
    Percentage: number,
    OldId: string,
    NewId: string,
    StateList: StateList,
    StateMap: StateMap
}

return {}