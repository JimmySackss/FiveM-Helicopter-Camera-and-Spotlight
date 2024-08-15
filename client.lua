-- Client-Side Script: helicopter_camera_client.lua

-- Variables to track the state of the camera and spotlight
local isCameraActive = false
local isSpotlightActive = false
local cameraHandle = nil
local spotlightHandle = nil
local lockedOnEntity = nil

-- Main thread that handles the camera controls
Citizen.CreateThread(function()
    while true do
        if isCameraActive then
            -- If the camera is active, handle the camera controls
            HandleCameraControls()
            Citizen.Wait(0)  -- Check every frame (real-time response needed)
        else
            Citizen.Wait(500)  -- When the camera is inactive, check less frequently to reduce strain
        end
    end
end)

-- Function to handle camera controls
function HandleCameraControls()
    -- Prevent the player from exiting the vehicle while the camera is active
    DisableControlAction(0, 75, true) -- Disable exit vehicle

    local playerPed = PlayerPedId()
    local heli = GetVehiclePedIsIn(playerPed, false)
    
    -- Stop the camera if the player exits the helicopter
    if not IsPedInAnyHeli(playerPed) or heli == 0 then
        StopCamera()
        return
    end

    -- Handle locking onto a vehicle
    if IsControlJustPressed(0, Config.LockOnKey) then
        lockedOnEntity = GetEntityInCrosshair()
    end

    -- Handle camera zooming in/out
    if IsControlJustPressed(0, Config.ZoomInKey) then
        SetCamFov(cameraHandle, math.max(10.0, GetCamFov(cameraHandle) - 5.0))
    elseif IsControlJustPressed(0, Config.ZoomOutKey) then
        SetCamFov(cameraHandle, math.min(70.0, GetCamFov(cameraHandle) + 5.0))
    end

    -- Handle spotlight toggling
    if IsControlJustPressed(0, Config.SpotlightToggleKey) then
        ToggleSpotlight()
    end

    -- If locked onto an entity, point the camera and spotlight at it
    if lockedOnEntity and DoesEntityExist(lockedOnEntity) then
        PointCamAtEntity(cameraHandle, lockedOnEntity, 0.0, 0.0, 0.0, true)
        if isSpotlightActive then
            PointSpotlightAtEntity(lockedOnEntity)
        end
    elseif isSpotlightActive then
        -- Otherwise, point the spotlight at where the camera is facing
        local camCoords = GetCamCoord(cameraHandle)
        local forwardVector = RotAnglesToVec(GetCamRot(cameraHandle, 2))
        PointSpotlightAtCoords(camCoords + (forwardVector * 1000.0))
    end
end

-- Event to start the camera
RegisterNetEvent("helicam:startCamera")
AddEventHandler("helicam:startCamera", function()
    if not isCameraActive then
        isCameraActive = true
        local playerPed = PlayerPedId()
        cameraHandle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        AttachCamToEntity(cameraHandle, playerPed, 0.0, 0.0, 1.0, true)
        SetCamRot(cameraHandle, 0.0, 0.0, GetEntityHeading(playerPed))
        RenderScriptCams(true, false, 0, true, true)
    else
        StopCamera()
    end
end)

-- Event to display a notification to the player
RegisterNetEvent("helicam:notify")
AddEventHandler("helicam:notify", function(message)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, true)
end)

-- Function to stop the camera and cleanup resources
function StopCamera()
    if isCameraActive then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cameraHandle, false)
        CleanupSpotlight()
        isCameraActive = false
        lockedOnEntity = nil
    end
end

-- Function to toggle the spotlight on/off
function ToggleSpotlight(state)
    if state == nil then
        state = not isSpotlightActive
    end

    isSpotlightActive = state
    local heli = GetVehiclePedIsIn(PlayerPedId(), false)
    
    -- Create the spotlight if it doesn't exist, or toggle its visibility
    if isSpotlightActive then
        if not DoesEntityExist(spotlightHandle) then
            spotlightHandle = CreateObject("prop_spotlight_pole", 0.0, 0.0, 0.0, true, true, false)
            AttachEntityToEntity(spotlightHandle, heli, GetEntityBoneIndexByName(heli, "misc_b"), 0.0, 0.0, -1.5, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        end
        SetEntityVisible(spotlightHandle, true, false)
    else
        SetEntityVisible(spotlightHandle, false, false)
    end
end

-- Cleanup function for the spotlight
function CleanupSpotlight()
    if DoesEntityExist(spotlightHandle) then
        DeleteObject(spotlightHandle)
        spotlightHandle = nil
    end
end

-- Point the spotlight at a specific entity
function PointSpotlightAtEntity(entity)
    local entityCoords = GetEntityCoords(entity)
    SetEntityCoordsNoOffset(spotlightHandle, entityCoords.x, entityCoords.y, entityCoords.z + 5.0, false, false, false)
end

-- Point the spotlight at specific coordinates
function PointSpotlightAtCoords(coords)
    SetEntityCoordsNoOffset(spotlightHandle, coords.x, coords.y, coords.z, false, false, false)
end

-- Perform a raycast to find the entity in the camera's crosshair
function GetEntityInCrosshair()
    local camCoords = GetCamCoord(cameraHandle)
    local forwardVector = RotAnglesToVec(GetCamRot(cameraHandle, 2))
    local rayHandle = StartShapeTestRay(camCoords, camCoords + (forwardVector * 1000.0), 10, -1, 0)
    local _, hit, _, _, entityHit = GetRaycastResult(rayHandle)
    
    if hit == 1 then
        return entityHit
    end
    
    return nil
end

-- Convert camera rotation angles to a directional vector
function RotAnglesToVec(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end
