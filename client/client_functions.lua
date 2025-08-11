function CheckRay(coords, direction)
    local rayEndPoint = coords + direction * 1000.0
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(coords.x, coords.y, coords.z, rayEndPoint.x, rayEndPoint.y, rayEndPoint.z, 19, PlayerPedId(), 7)
    local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultEx(rayHandle)
    return surfaceNormal, GetEntityType(entityHit) == 0
end

function GetRotation(coords, direction)
    local normal, typed = CheckRay(coords + vector3(0.0, 0.0, 0.0), direction + vector3(0.0, 0.0, 0.0))
    local camLookPosition = coords - normal * 10

    SetCamCoord(rotationCam, coords.x, coords.y, coords.z)
    PointCamAtCoord(rotationCam, camLookPosition.x, camLookPosition.y, camLookPosition.z)
    SetCamActive(rotationCam, true)

    Citizen.Wait(0)

    local rot = GetCamRot(rotationCam, 2)
    SetCamActive(rotationCam, false)

    return rot, typed
end

function SetRotation(entity)
    local direction = RotationToDirection(GetGameplayCamRot())
    local rotation, hastype = GetRotation(GetEntityCoords(PlayerPedId()), direction)
    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z)

    local markerCoords = GetOffsetFromEntityInWorldCoords(placingObject, 0, -0.1, 0)
    
    canPlace = true
    
    if rotation.x < -80.0 or rotation.x > 80.0 then 
        canPlace = false 
    end

    if GetEntityHeightAboveGround(entity) > 2.0 then
        canPlace = false
    end

    if not hastype then
        canPlace = false
    end

    DrawMarker(6, markerCoords.x, markerCoords.y, markerCoords.z, 0.0, 0.0, 0.0, rotation.x, rotation.y, rotation.z, 0.8, 0.3, 0.8, canPlace and 0 or 255, canPlace and 255 or 0, 0, 255, false, false, false, false, false, false, false)
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance, 
        y = cameraCoord.y + direction.y * distance, 
        z = cameraCoord.z + direction.z * distance
    }

    local a, b, c, d, e = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))

    return b, c, e
end

function RotationToDirection(rotation)
	local adjustedRotation = {
        x = (math.pi / 180) * rotation.x, 
        y = (math.pi / 180) * rotation.y, 
        z = (math.pi / 180) * rotation.z
    }

	return vector3(-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.sin(adjustedRotation.x))
end

function GetInfo(model)
    return Config.Sprays[model]
end

function CheckShopData(gang, PlayerData)
    if not gang then
        return false
    else
        if PlayerData then
            if gang == PlayerData.name then
                return false
            else
                return true
            end
        else
            return true
        end
    end
end

function GetClosestGangGraffiti(distance, excludeGang)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for k, v in pairs(Config.Graffitis) do
        if v then
            local graffitiDistance = #(coords - v.coords)
            if graffitiDistance < distance then
                local information = GetInfo(v.model)
                if information and information.gang then
                    if not excludeGang or information.gang ~= excludeGang then
                        return {
                            key = tonumber(v.key),
                            gang = information.gang,
                            distance = graffitiDistance,
                            coords = v.coords
                        }
                    end
                end
            end
        end
    end

    return nil
end

function CanPlaceGangGraffiti(playerGang, graffitiGang, territoryRadius)
    territoryRadius = territoryRadius or 50.0
    if not graffitiGang then
        return true, nil
    end
    
    if not playerGang then
        return false, "You must be in a gang to place gang graffiti."
    end
    
    local enemyGraffiti = GetClosestGangGraffiti(territoryRadius, playerGang)
    
    if enemyGraffiti then
        return false, "Enemy gang territory detected! Remove the " .. enemyGraffiti.gang .. " graffiti first (Distance: " .. math.floor(enemyGraffiti.distance) .. "m)"
    end
    
    return true, nil
end

function GetClosestGraffitiEnhanced(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestGraffiti = nil
    local closestDistance = distance

    for k, v in pairs(Config.Graffitis) do
        if v then
            local graffitiDistance = #(coords - v.coords)
            if graffitiDistance < closestDistance then
                local information = GetInfo(v.model)
                closestGraffiti = {
                    key = tonumber(v.key),
                    distance = graffitiDistance,
                    coords = v.coords,
                    gang = information and information.gang or nil,
                    name = information and information.name or "Unknown",
                    model = v.model,
                    owner = v.owner or nil
                }
                closestDistance = graffitiDistance
            end
        end
    end

    return closestGraffiti
end

function CanRemoveGraffiti(playerGang, graffiti)
    if not graffiti.gang then
        return {
            canRemove = true,
            removalType = "cleaning",
            message = nil
        }
    end
    
    if playerGang and playerGang == graffiti.gang then
        return {
            canRemove = true,
            removalType = "gang_removal",
            message = nil
        }
    end
    
    local hasEnoughMembers = lib.callback.await('qb-graffiti:server:checkGangActiveMembers', false, graffiti.gang)
    
    if not hasEnoughMembers then
        return {
            canRemove = false,
            removalType = "protected",
            message = 'This graffiti is protected until more gang members come online!'
        }
    end
    
    return {
        canRemove = true,
        removalType = "hostile_removal",
        message = nil
    }
end

function GetRemovalDetails(removalType, graffiti)
    local details = {
        duration = 20000,
        label = 'Washing the wall',
        animation = "WORLD_HUMAN_MAID_CLEAN"
    }
    
    if removalType == "gang_removal" then
        details.duration = 8000
        details.label = 'Removing gang graffiti'
        details.animation = "WORLD_HUMAN_JANITOR"
    elseif removalType == "hostile_removal" then
        details.duration = 30000
        details.label = 'Scrubbing enemy graffiti'
        details.animation = "WORLD_HUMAN_MAID_CLEAN"
    end
    
    return details
end

function PlaceGraffiti(model, cb)
    local ped = PlayerPedId()

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local centerCoords = GetEntityCoords(ped) + (GetEntityForwardVector(ped) * 1.5)
    placingObject = CreateObject(model, centerCoords, false, false)

    if not placingObject then
        cb(false)
        return
    end

    isPlacing = true
    canPlace = false

    CreateThread(function()
        local textUIShown = false

        while isPlacing do
            local ped = PlayerPedId()
            local hit, coords, entity = RayCastGamePlayCamera(10.0)
            local graffiti = GetClosestGraffiti(5.0)
            local blacklist = GetInBlacklistedZone()

            DisableControlAction(0, 24, true)
            DisableControlAction(1, 38, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 142, true)
            DisablePlayerFiring(ped, true)

            if placingObject and DoesEntityExist(placingObject) then
                SetEntityCoords(placingObject, coords.x, coords.y, coords.z)
                SetRotation(placingObject)
            else
                isPlacing = false
                canPlace = false
                if textUIShown then lib.hideTextUI() end
                cb(false)
                return
            end

            if IsControlJustPressed(0, 177) then
                if textUIShown then lib.hideTextUI() end
                textUIShown = false

                if sprayingParticle then
                    StopParticleFxLooped(sprayingParticle, true)
                    sprayingParticle = nil
                end
                if sprayingCan and DoesEntityExist(sprayingCan) then
                    DeleteObject(sprayingCan)
                    sprayingCan = nil
                end
                StopAnimTask(ped, 'switch@franklin@lamar_tagging_wall', 'lamar_tagging_exit_loop_lamar', 1.0)

                DeleteEntity(placingObject)
                placingObject = nil
                isPlacing = false
                canPlace = false
                cb(false)
                return
            end

            if graffiti then
                lib.notify({
                    description = 'Someone has already put graffiti nearby.',
                    type = 'error'
                })
                if textUIShown then lib.hideTextUI() end
                textUIShown = false

                if placingObject and DoesEntityExist(placingObject) then
                    DeleteEntity(placingObject)
                end
                placingObject = nil
                isPlacing = false
                canPlace = false
                cb(false)
                return
            end

            if blacklist then
                lib.notify({
                    description = 'You cannot put graffiti on this place.',
                    type = 'error'
                })
                if textUIShown then lib.hideTextUI() end
                textUIShown = false

                if placingObject and DoesEntityExist(placingObject) then
                    DeleteEntity(placingObject)
                end
                placingObject = nil
                isPlacing = false
                canPlace = false
                cb(false)
                return
            end

            if hit == 1 and canPlace then
                if not textUIShown then
                    lib.showTextUI('Press [ENTER] to place | Press [BACKSPACE] to cancel', {
                        position = "bottom-center",
                        icon = 'spray-can',
                        style = {
                            borderRadius = 8,
                            backgroundColor = '#1e1e1e',
                            color = 'white'
                        }
                    })
                    textUIShown = true
                end

                if IsControlJustPressed(0, 191) then
                    if textUIShown then lib.hideTextUI() end
                    textUIShown = false

                    local entityCoords = GetEntityCoords(placingObject)
                    local entityRotation = GetEntityRotation(placingObject)

                    DeleteEntity(placingObject)
                    placingObject = nil
                    isPlacing = false

                    cb(true, entityCoords, entityRotation)
                    return
                end

                if placingObject and #(GetEntityCoords(ped) - GetEntityCoords(placingObject)) > 5.0 then
                    canPlace = false
                end
            else
                if textUIShown then
                    lib.hideTextUI()
                    textUIShown = false
                end
                canPlace = false
            end

            Wait(0)
        end

        if textUIShown then
            lib.hideTextUI()
        end
    end)
end

function SprayingAnim()
    local ped = PlayerPedId()

    RequestAnimDict('switch@franklin@lamar_tagging_wall')
    while not HasAnimDictLoaded('switch@franklin@lamar_tagging_wall') do 
        Wait(0)
    end

    RequestModel('prop_cs_spray_can')
    while not HasModelLoaded('prop_cs_spray_can') do 
        Wait(0)
    end

    RequestNamedPtfxAsset('scr_playerlamgraff')
    while not HasNamedPtfxAssetLoaded('scr_playerlamgraff') do 
        Wait(0)
    end

    local coords = GetEntityCoords(ped)
    sprayingCan = CreateObject('prop_cs_spray_can', coords.x, coords.y, coords.z, true, true)
    AttachEntityToEntity(sprayingCan, ped, GetPedBoneIndex(ped, 28422), 0, -0.01, -0.012, 0, 0, 0, true, true, false, false, 2, true)

    CreateThread(function()
        TaskPlayAnim(ped, 'switch@franklin@lamar_tagging_wall', 'lamar_tagging_wall_loop_lamar', 8.0, -8.0, -1, 8192, 0.0, false, false, false)
        Wait(5500)
        TaskPlayAnim(ped, 'switch@franklin@lamar_tagging_wall', 'lamar_tagging_exit_loop_lamar', 8.0, -2.0, -1, 8193, 0.0, false, false, false)
    
        if sprayingParticle then
            StopParticleFxLooped(sprayingParticle, true)
            sprayingParticle = nil
        end

        UseParticleFxAssetNextCall('scr_playerlamgraff')
        sprayingParticle = StartParticleFxLoopedOnEntity('scr_lamgraff_paint_spray', sprayingCan, 0, 0, 0, 0, 0, 0, 1.0, false, false, false)
        SetParticleFxLoopedColour(sprayingParticle, 1.0, 0.5, 0.5, 0)
        SetParticleFxLoopedAlpha(sprayingParticle, 0.25)
    end)
end

function GetClosestGraffiti(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for k, v in pairs(Config.Graffitis) do
        if v then
            if #(coords - v.coords) < distance then
                return tonumber(v.key)
            end
        end
    end

    return nil
end

function GetInBlacklistedZone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for k, v in pairs(Config.BlacklistedZones) do
        if v then
            if #(coords - v.coords) < v.radius then
                return true
            end
        end
    end

    return false
end