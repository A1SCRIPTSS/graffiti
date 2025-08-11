isLoaded = false

function useSpraycan(event, item, inventory, slot)
    local playerId = inventory.player and inventory.player.source or inventory.id
    
    if not playerId then
        return false
    end
    
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    if Player and isLoaded then
        local metadata = item and item.metadata
        
        if not metadata then
            local inventoryItem = exports.ox_inventory:GetSlot(playerId, slot)
            if inventoryItem and inventoryItem.metadata then
                metadata = inventoryItem.metadata
            end
        end
        
        if metadata and metadata.model then
            TriggerClientEvent('qb-graffiti:client:placeGraffiti', playerId, metadata.model, slot, metadata)
            return false
        else
            TriggerClientEvent('ox_lib:notify', playerId, {
                description = 'The item has no information. Buy graffiti from the shop!',
                type = 'error'
            })
            return false
        end
    end
    
    return false
end

function useSprayremover(event, item, inventory, slot)
    local playerId = inventory.player and inventory.player.source or inventory.id
    
    if not playerId then
        print("^1[GRAFFITI DEBUG] ERROR: Could not determine player ID from inventory")
        return false
    end
    
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    if Player and isLoaded then
        TriggerClientEvent('qb-graffiti:client:removeClosestGraffiti', playerId)
        return false 
    end
    
    return false
end

exports('useSpraycan', useSpraycan)
exports('useSprayremover', useSprayremover)

CreateThread(function()
    MySQL.query('SELECT `key`, `owner`, `model`, `coords`, `rotation` FROM `graffitis`', {}, function(result)
        Config.Graffitis = {}
        
        if result then
            for k, v in pairs(result) do
                if v and v.coords and v.rotation then
                    local success, coords = pcall(json.decode, v.coords)
                    local success2, rotation = pcall(json.decode, v.rotation)
                    
                    if success and success2 then
                        Config.Graffitis[tonumber(v.key)] = {
                            key = tonumber(v.key),
                            model = tonumber(v.model),
                            coords = vector3(QBCore.Shared.Round(coords.x, 2), QBCore.Shared.Round(coords.y, 2), QBCore.Shared.Round(coords.z, 2)),
                            rotation = vector3(QBCore.Shared.Round(rotation.x, 2), QBCore.Shared.Round(rotation.y, 2), QBCore.Shared.Round(rotation.z, 2)),
                            owner = v.owner,
                            entity = nil,
                            blip = nil
                        }
                    end
                end
            end
        end

        isLoaded = true
        
        Wait(2000)
        UpdateGraffitiData()
    end)
end)

lib.callback.register('qb-graffiti:server:getGraffitiData', function(source)
    while not isLoaded do
        Wait(0)
    end
    
    return Config.Graffitis
end)

RegisterServerEvent('qb-graffiti:client:addServerGraffiti', function(model, coords, rotation, slot, metadata)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)

    if not (Player and isLoaded) then
        return
    end

    local minDistance = 5.0
    for k, v in pairs(Config.Graffitis) do
        if v and v.coords and #(coords - v.coords) < minDistance then
            TriggerClientEvent('ox_lib:notify', source, {
                description = 'Too close to existing graffiti!',
                type = 'error'
            })
            return
        end
    end

    local graffitiInfo = Config.Sprays[model]
    if not graffitiInfo then
        TriggerClientEvent('ox_lib:notify', source, {
            description = 'Invalid graffiti model!',
            type = 'error'
        })
        return
    end

    local playerGang = Player.PlayerData.gang and Player.PlayerData.gang.name or nil
    local territoryRadius = 50.0
    
    local canPlace, errorMessage = CheckGangTerritoryServer(coords, playerGang, graffitiInfo.gang, territoryRadius)
    
    if not canPlace then
        TriggerClientEvent('ox_lib:notify', source, {
            description = errorMessage,
            type = 'error'
        })
        return
    end

    if graffitiInfo.gang and (not playerGang or playerGang ~= graffitiInfo.gang) then
        TriggerClientEvent('ox_lib:notify', source, {
            description = 'This graffiti is for ' .. graffitiInfo.gang .. ' gang members only.',
            type = 'error'
        })
        return
    end

    MySQL.insert('Insert into `graffitis` (owner, model, `coords`, `rotation`) values (@owner, @model, @coords, @rotation)', {
        ['@owner'] = Player.PlayerData.citizenid,
        ['@model'] = tostring(model),
        ['@coords'] = json.encode(vector3(QBCore.Shared.Round(coords.x, 2), QBCore.Shared.Round(coords.y, 2), QBCore.Shared.Round(coords.z, 2))),
        ['@rotation'] = json.encode(vector3(QBCore.Shared.Round(rotation.x, 2), QBCore.Shared.Round(rotation.y, 2), QBCore.Shared.Round(rotation.z, 2)))
    }, function(key)
        if key and key > 0 then
            Config.Graffitis[tonumber(key)] = {
                key = tonumber(key),
                model = tonumber(model),
                coords = vector3(QBCore.Shared.Round(coords.x, 2), QBCore.Shared.Round(coords.y, 2), QBCore.Shared.Round(coords.z, 2)),
                rotation = vector3(QBCore.Shared.Round(rotation.x, 2), QBCore.Shared.Round(rotation.y, 2), QBCore.Shared.Round(rotation.z, 2)),
                owner = Player.PlayerData.citizenid,
                entity = nil,
                blip = nil
            }

            UpdateGraffitiData()
            
            local success = exports.ox_inventory:RemoveItem(source, 'spraycan', 1, metadata, slot)
            
            if not success then
                success = exports.ox_inventory:RemoveItem(source, 'spraycan', 1)
            end
            
            local successMessage = 'Graffiti placed successfully!'
            if graffitiInfo.gang then
                successMessage = graffitiInfo.gang .. ' territory claimed!'
            end
            
            TriggerClientEvent('ox_lib:notify', source, {
                description = successMessage,
                type = 'success'
            })
        end
    end)
end)

lib.callback.register('qb-graffiti:server:checkGangActiveMembers', function(source, gangName)
    local gangMembers = GetOnlineGangMembers(gangName)
    return #gangMembers >= Config.MinGangMembers
end)

RegisterServerEvent('qb-graffiti:server:removeServerGraffitiByKey', function(key, removalData)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)

    if not (Player and isLoaded) then
        return
    end

    local graffitiData = Config.Graffitis[key]
    if not graffitiData then
        return
    end

    local graffitiInfo = Config.Sprays[graffitiData.model]
    local graffitiGang = graffitiInfo and graffitiInfo.gang or nil

    if graffitiGang and removalData then
        local playerGang = removalData.playerGang
        local hasEnoughMembers = #GetOnlineGangMembers(graffitiGang) >= Config.MinGangMembers
        
        if graffitiGang ~= playerGang and hasEnoughMembers then
            local Players = QBCore.Functions.GetQBPlayers()
            
            for playerId, player in pairs(Players) do
                if player.PlayerData.gang and player.PlayerData.gang.name == graffitiGang then
                    TriggerClientEvent('qb-graffiti:client:gangGraffitiRemoved', playerId, {
                        playerGang = playerGang,
                        graffitiGang = graffitiGang,
                        graffitiName = removalData.graffitiName,
                        location = removalData.location,
                        removerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                        hasEnoughMembers = hasEnoughMembers
                    })
                end
            end
            
            print(string.format("^3[GANG TERRITORY] %s (%s) removed %s gang graffiti at %s^7", 
                Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                playerGang or "No Gang",
                graffitiGang,
                json.encode(removalData.location)
            ))
        end
    end

    MySQL.query('Delete from `graffitis` where `key` = @key', {
        ['@key'] = tonumber(key)
    }, function()
        Config.Graffitis[key] = nil
        UpdateGraffitiData()
        
        local removed = exports.ox_inventory:RemoveItem(source, 'sprayremover', 1)
        
        if not removed then
            print("^1[GRAFFITI DEBUG] ERROR: Failed to remove sprayremover item from player inventory")
        end
        
        local removalType = removalData and removalData.removalType or "cleaning"
        local successMessage = "Graffiti cleaned successfully!"
        
        if removalType == "gang_removal" then
            successMessage = "Gang graffiti removed quickly!"
        elseif removalType == "hostile_removal" then
            successMessage = "Enemy territory graffiti removed! This area is now free."
        elseif removalType == "unprotected_removal" then
            successMessage = "Unprotected gang graffiti removed easily!"
        end
        
        TriggerClientEvent('ox_lib:notify', source, {
            description = successMessage,
            type = 'success'
        })
    end)
end)

RegisterServerEvent('qb-graffiti:server:graffitiShop', function(data)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)

    if not (Player and isLoaded) then
        return
    end

    if Player.Functions.RemoveMoney('cash', data.price) then
        local added = exports.ox_inventory:AddItem(source, 'spraycan', 1, {
            model = data.model,
            name = data.name,
            description = 'Spray: ' .. data.name
        })

        TriggerClientEvent('ox_lib:notify', source, {
            description = 'You bought a graffiti can for $' .. data.price .. ' with the name: ' .. data.name,
            type = 'success'
        })
    else
        local morePrice = data.price - Player.PlayerData.money.cash
        TriggerClientEvent('ox_lib:notify', source, {
            description = 'You not have enough money. You need more ($' .. morePrice .. ')',
            type = 'error'
        })
    end
end)