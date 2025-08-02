if GetConvarInt('ox_target:defaults', 1) ~= 1 then return end

local api = require 'client.api'

local bones <const> = {
    [0] = 'door_dside_f',
    [1] = 'door_pside_f',
    [2] = 'door_dside_r',
    [3] = 'door_pside_r'
}

---@param vehicle number
---@param door number
local function toggleDoor(vehicle, door)
    if GetVehicleDoorLockStatus(vehicle) ~= 2 then
        if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
            SetVehicleDoorShut(vehicle, door, false)
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end
    end
end

local function onSelectDoor(data, door)
    local entity = data.entity

    if NetworkGetEntityOwner(entity) == cache.playerId then
        return toggleDoor(entity, door)
    end

    TriggerServerEvent('ox_target:toggleEntityDoor', VehToNet(entity), door)
end

RegisterNetEvent('ox_target:toggleEntityDoor', function(netId, door)
    local entity = NetToVeh(netId)
    toggleDoor(entity, door)
end)

local function getRelativeDoorCoords(entity, doorId)
    local boneIndex <const> = GetEntityBoneIndexByName(entity, bones[doorId])
    local worldPositionOfBone <const> = GetWorldPositionOfEntityBone(entity, boneIndex)
    return GetOffsetFromEntityGivenWorldCoords(entity, worldPositionOfBone.x, worldPositionOfBone.y, worldPositionOfBone.z)
end

local function canInteractWithDoor(entity, doorId)
    return not cache.vehicle
        and DoesEntityExist(entity)
        and DoesEntityHaveDrawable(entity)
        and GetIsDoorValid(entity, doorId)
        and not IsVehicleDoorDamaged(entity, doorId)
        and GetVehicleDoorLockStatus(entity) <= 1
end

local function isTargetPointingAtDoor(entity, doorId, coords, bone)
    if not canInteractWithDoor(entity, doorId) then
        return false
    end

    if GetVehicleModelNumberOfSeats(GetEntityModel(entity)) > 4 then -- vehicle is not a car (e.g. bus)
        return bone == GetEntityBoneIndexByName(entity, bones[doorId]) -- return true to apply ox_target default logic for targeting doors
    end

    local relativeCoords <const> = GetOffsetFromEntityGivenWorldCoords(entity, coords.x, coords.y, coords.z)
    local relativeCoordsY <const> = (math.floor(relativeCoords.y * 100)) / 100

    -- return false if the targeted door is on the wrong side of the vehicle
    -- the target is pointing to the driver side if the relative x < 0
    local isPassengerSide <const> = doorId % 2 == 1
    if (relativeCoords.x < 0) == isPassengerSide then
        return false
    end

    local relativeDoorCoords <const> = getRelativeDoorCoords(entity, doorId)

    -- to determine if the targeted door is a front door, we need to check if the pointer's position is between the bone of the front door and the bone of the rear door
    -- this is not necessary if the vehicle only has front doors
    local isFrontDoor <const> = doorId <= 1
    if isFrontDoor then
        local rearDoorId <const> = doorId + 2
        if GetIsDoorValid(entity, rearDoorId) and not IsVehicleDoorDamaged(entity, rearDoorId) then
            local relativeRearDoorCoords = getRelativeDoorCoords(entity, rearDoorId)
            return relativeCoordsY <= relativeDoorCoords.y
                and relativeCoordsY > relativeRearDoorCoords.y
                and #(relativeCoords - relativeDoorCoords) < 2.5
        end
    end

    return relativeCoordsY <= relativeDoorCoords.y
        and #(relativeCoords - relativeDoorCoords) < 2.5
end
    
api.addGlobalVehicle({
    {
        name = 'ox_target:driverF',
        icon = 'fa-solid fa-car-side',
        label = locale('toggle_front_driver_door'),
        bones = { 'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r' },
        distance = 2,
        canInteract = function(entity, distance, coords, name, bone)
            return isTargetPointingAtDoor(entity, 0, coords, bone)
        end,
        onSelect = function(data)
            onSelectDoor(data, 0)
        end
    },
    {
        name = 'ox_target:passengerF',
        icon = 'fa-solid fa-car-side',
        label = locale('toggle_front_passenger_door'),
        bones = { 'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r' },
        distance = 2,
        canInteract = function(entity, distance, coords, name, bone)
            return isTargetPointingAtDoor(entity, 1, coords, bone)
        end,
        onSelect = function(data)
            onSelectDoor(data, 1)
        end
    },
    {
        name = 'ox_target:driverR',
        icon = 'fa-solid fa-car-side',
        label = locale('toggle_rear_driver_door'),
        bones = { 'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r' },
        distance = 2,
        canInteract = function(entity, distance, coords, name, bone)
            return isTargetPointingAtDoor(entity, 2, coords, bone)
        end,
        onSelect = function(data)
            onSelectDoor(data, 2)
        end
    },
    {
        name = 'ox_target:passengerR',
        icon = 'fa-solid fa-car-side',
        label = locale('toggle_rear_passenger_door'),
        bones = { 'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r' },
        distance = 2,
        canInteract = function(entity, distance, coords, name, bone)
            return isTargetPointingAtDoor(entity, 3, coords, bone)
        end,
        onSelect = function(data)
            onSelectDoor(data, 3)
        end
    },
    {
        name = 'ox_target:bonnet',
        icon = 'fa-solid fa-car',
        label = locale('toggle_hood'),
        offset = vec3(0.5, 1, 0.5),
        distance = 2,
        canInteract = function(entity, distance, coords)
            return canInteractWithDoor(entity, 4)
        end,
        onSelect = function(data)
            onSelectDoor(data, 4)
        end
    },
    {
        name = 'ox_target:trunk',
        icon = 'fa-solid fa-car-rear',
        label = locale('toggle_trunk'),
        offset = vec3(0.5, 0, 0.5),
        distance = 2,
        canInteract = function(entity, distance, coords, name)
            return canInteractWithDoor(entity, 5)
        end,
        onSelect = function(data)
            onSelectDoor(data, 5)
        end
    }
})