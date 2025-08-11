rotationCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', 0)
sprayingParticle = nil
placingObject = nil
sprayingCan = nil
isPlacing = false
canPlace = false
isLoaded = false
isAnimating = false
local isRemovingGraffiti = false

CreateThread(function()
    RequestModel(GetHashKey('a_m_m_rurmeth_01'))
    while not HasModelLoaded(GetHashKey('a_m_m_rurmeth_01')) do
        Wait(0)
    end

    local blip = AddBlipForCoord(109.24, -1090.58, 28.3)
    SetBlipSprite(blip, 72)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 17)
    SetBlipAsShortRange(blip, true)
    SetBlipNameFromTextFile(blip, "Graffiti Shop")

    local npc = CreatePed(4, GetHashKey('a_m_m_rurmeth_01'), vector3(109.24, -1090.58, 28.3), 347.5, false, false)
    
    SetPedFleeAttributes(npc, 0, 0)
    SetEntityInvincible(npc , true)
    FreezeEntityPosition(npc, true)
    SetPedDiesWhenInjured(npc, false)
    SetPedDropsWeaponsWhenDead(npc, false)
    SetBlockingOfNonTemporaryEvents(npc, true)

    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'graffiti_shop',
            icon = 'fa-palette',
            label = 'Graffiti Shop',
            onSelect = function()
                TriggerEvent('qb-graffiti:client:graffitiShop')
            end,
            distance = 3.0
        }
    })

    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if isLoaded and Config.Graffitis then
            for k, v in pairs(Config.Graffitis) do
                if v and v.model and v.coords then
                    local information = GetInfo(tonumber(v.model))

                    if information then
                        local distance = #(coords - v.coords)
                        if distance < 100.0 then
                            if not DoesEntityExist(v.entity) then
                                RequestModel(tonumber(v.model))
                                while not HasModelLoaded(tonumber(v.model)) do
                                    Wait(0)
                                end

                                v.entity = CreateObjectNoOffset(tonumber(v.model), v.coords, false, false)
                                if v.rotation then
                                    SetEntityRotation(v.entity, v.rotation.x, v.rotation.y, v.rotation.z)
                                end
                                FreezeEntityPosition(v.entity, true)
                            end
                        else
                            if DoesEntityExist(v.entity) then
                                DeleteEntity(v.entity)
                                v.entity = nil
                            end
                        end

                        if information.blip == true then
                            if not DoesBlipExist(v.blip) then
                                v.blip = AddBlipForRadius(v.coords, 100.0)
                                SetBlipAlpha(v.blip, 100)
                                SetBlipColour(v.blip, information.blipcolor)
                            end
                        end
                    end
                end
            end
        end

        Wait(1000)
    end
end)

local function loadGraffitiData()
    lib.callback('qb-graffiti:server:getGraffitiData', false, function(data)
        if data then
            Config.Graffitis = data
            isLoaded = true
        else
            Config.Graffitis = {}
            isLoaded = true
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if not isLoaded then
        loadGraffitiData()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if isLoaded then
        isLoaded = false

        if Config.Graffitis then
            for k, v in pairs(Config.Graffitis) do
                if v then
                    if DoesEntityExist(v.entity) then
                        DeleteEntity(v.entity)
                    end
        
                    if DoesBlipExist(v.blip) then
                        RemoveBlip(v.blip)
                    end
                end
            end
        end
    
        Config.Graffitis = {}
    end
end)

RegisterNetEvent('qb-graffiti:client:setGraffitiData', function(data)
    if isLoaded and Config.Graffitis then
        for k, v in pairs(Config.Graffitis) do
            if v then
                if DoesEntityExist(v.entity) then
                    DeleteEntity(v.entity)
                end

                if DoesBlipExist(v.blip) then
                    RemoveBlip(v.blip)
                end
            end
        end
    end

    Config.Graffitis = data or {}
end)

RegisterNetEvent('qb-graffiti:client:placeGraffiti', function(model, slot, metadata)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local information = GetInfo(model)
    local ped = PlayerPedId()

    if isPlacing or not isLoaded or isAnimating then
        return
    end

    if information then
        if information.gang then
            if not PlayerData.gang or PlayerData.gang.name ~= information.gang then
                return lib.notify({
                    description = 'This graffiti is for ' .. information.gang .. ' gang members only.',
                    type = 'error'
                })
            end
        end

        local territoryRadius = 50.0
        local canPlace, errorMessage = CanPlaceGangGraffiti(
            PlayerData.gang and PlayerData.gang.name or nil, 
            information.gang, 
            territoryRadius
        )
        
        if not canPlace then
            return lib.notify({
                description = errorMessage,
                type = 'error'
            })
        end

        PlaceGraffiti(model, function(result, coords, rotation)
            if result then
                local nearbyGraffiti = GetClosestGraffiti(5.0)
                if nearbyGraffiti then
                    return lib.notify({
                        description = 'Someone has already put graffiti nearby.',
                        type = 'error'
                    })
                end

                isAnimating = true

                local tempAlpha = 0
                local tempSpray = CreateObjectNoOffset(model, coords, false, false, false)

                SetEntityRotation(tempSpray, rotation.x, rotation.y, rotation.z)
                FreezeEntityPosition(tempSpray, true)
                SetEntityAlpha(tempSpray, 0, false)

                CreateThread(function()
                    while tempAlpha < 255 and DoesEntityExist(tempSpray) do
                        tempAlpha = tempAlpha + 51
                        SetEntityAlpha(tempSpray, tempAlpha, false)
                        Wait(800)
                    end
                end)

                SprayingAnim()

                local progressCompleted = lib.progressBar({
                    duration = 8000,
                    label = 'Spraying with paint',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                        mouse = false
                    }
                })

                StopAnimTask(ped, 'switch@franklin@lamar_tagging_wall', 'lamar_tagging_exit_loop_lamar', 1.0)
                if sprayingParticle then
                    StopParticleFxLooped(sprayingParticle, true)
                    sprayingParticle = nil
                end
                if sprayingCan then
                    DeleteObject(sprayingCan)
                    sprayingCan = nil
                end

                isAnimating = false

                if progressCompleted then
                    TriggerServerEvent('qb-graffiti:client:addServerGraffiti', model, coords, rotation, slot, metadata)
                end

                DeleteObject(tempSpray)
            end
        end)
    else
        lib.notify({
            description = 'The item has no information. Buy graffiti from the shop!',
            type = 'error'
        })
    end
end)

RegisterNetEvent('qb-graffiti:client:removeClosestGraffiti', function()
    if isRemovingGraffiti then return end
    isRemovingGraffiti = true
    
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    if not isLoaded then
        isRemovingGraffiti = false
        return 
    end
    
    local graffiti = GetClosestGraffitiEnhanced(5.0)
    if not graffiti then
        isRemovingGraffiti = false
        return lib.notify({ description = 'No graffiti found nearby.', type = 'error' })
    end

    local playerGang = PlayerData.gang and PlayerData.gang.name or nil
    local removalCheck = CanRemoveGraffiti(playerGang, graffiti)
    
    if not removalCheck.canRemove then
        isRemovingGraffiti = false
        if removalCheck.message then
            return lib.notify({ 
                description = removalCheck.message, 
                type = 'error',
                duration = 5000
            })
        end
        return
    end

    local removalDetails = GetRemovalDetails(removalCheck.removalType, graffiti)
    
    local success = lib.progressBar({
        duration = removalDetails.duration,
        label = removalDetails.label,
        useWhileDead = false,
        canCancel = true,
        disable = { 
            car = true, 
            move = true, 
            combat = true 
        },
        anim = {
            scenario = removalDetails.animation,
            disable = { 
                move = true, 
                car = true, 
                combat = true 
            }
        }
    })

    if success then
        TriggerServerEvent('qb-graffiti:server:removeServerGraffitiByKey', graffiti.key, {
            removalType = removalCheck.removalType,
            playerGang = playerGang,
            graffitiGang = graffiti.gang,
            graffitiName = graffiti.name,
            location = graffiti.coords
        })
    else
        lib.notify({ description = 'Removal cancelled', type = 'error' })
    end
    
    isRemovingGraffiti = false
end)

RegisterNetEvent('qb-graffiti:client:gangGraffitiRemoved', function(data)
    local message = string.format(
        "⚠️ GANG ALERT: %s gang member removed your %s graffiti!", 
        data.playerGang or "Unknown", 
        data.graffitiGang
    )
    
    if not data.hasEnoughMembers then
        message = message .. "\nYour gang didn't have enough active members to protect this territory!"
    end
    
    lib.notify({
        title = 'Territory Under Attack!',
        description = message,
        type = 'error',
        duration = 10000
    })
end)

RegisterNetEvent('qb-graffiti:client:graffitiShop', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local options = {}

    if not isLoaded then
        return
    end

    for k, v in pairs(Config.Sprays) do
        local disabled = CheckShopData(v.gang, PlayerData.gang)
        if not disabled then
            options[#options + 1] = {
                title = v.name .. ' - $' .. v.price,
                description = '',
                icon = 'fa-brush',
                disabled = disabled,
                onSelect = function()
                    TriggerServerEvent('qb-graffiti:server:graffitiShop', {
                        model = k,
                        name = v.name,
                        price = v.price 
                    })
                end
            }
        end
    end

    lib.registerContext({
        id = 'graffiti_shop_menu',
        title = 'Graffiti Shop',
        options = options
    })

    lib.showContext('graffiti_shop_menu')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end    
    
    Wait(2000)

    if not isLoaded then
        loadGraffitiData()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    if Config.Graffitis then
        for k, v in pairs(Config.Graffitis) do
            if v then
                if DoesEntityExist(v.entity) then
                    DeleteEntity(v.entity)
                end
            end
        end
    end
end)