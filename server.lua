-- Server-Side Script: helicopter_camera.lua

local Config = {
    Keybind = 246,  -- Y key (default to open camera)
    LockOnKey = 22, -- Spacebar (default to lock on)
    ZoomInKey = 241, -- Scroll Up (default for zoom in)
    ZoomOutKey = 242, -- Scroll Down (default for zoom out)
    SpotlightToggleKey = 47, -- G key (default to toggle spotlight)
    HelicopterModels = {
        "polmav",
        "buzzard",
        "frogger"
    }
}

-- Register a command that allows players to toggle the camera using /helicam
RegisterCommand("helicam", function(source, args, rawCommand)
    TriggerClientEvent("helicam:toggleCamera", source)
end, false)

-- Server event to check if the player is a passenger in a helicopter
RegisterServerEvent("helicam:checkPassenger")
AddEventHandler("helicam:checkPassenger", function()
    local src = source
    local playerPed = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(playerPed, false)
    
    -- If the player is in a helicopter, check if they are the driver or a passenger
    if veh ~= 0 and IsPedInAnyHeli(playerPed) then
        local seatIndex = GetPedInVehicleSeat(veh, -1) -- Check driver seat
        if playerPed == seatIndex then
            -- Notify the player if they are the driver and cannot use the camera
            TriggerClientEvent("helicam:notify", src, "You cannot use the camera or spotlight as the pilot.")
        else
            -- Start the camera for passengers
            TriggerClientEvent("helicam:startCamera", src)
        end
    else
        -- Notify the player if they are not in a helicopter
        TriggerClientEvent("helicam:notify", src, "You need to be in a helicopter to use the camera and spotlight.")
    end
end)
