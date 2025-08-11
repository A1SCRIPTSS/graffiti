function UpdateGraffitiData()
    local Players = QBCore.Functions.GetQBPlayers()

    if Players and isLoaded then
        for k, v in pairs(Players) do
            if v then
                TriggerClientEvent('qb-graffiti:client:setGraffitiData', k, Config.Graffitis)
            end
        end
    end
end

function CheckGangTerritoryServer(coords, playerGang, graffitiGang, territoryRadius)
    territoryRadius = territoryRadius or 50.0
    
    if not graffitiGang then
        return true, nil
    end
    
    if not playerGang then
        return false, "You must be in a gang to place gang graffiti."
    end
    
    for k, v in pairs(Config.Graffitis) do
        if v and v.coords then
            local distance = #(coords - v.coords)
            if distance < territoryRadius then
                local graffitiInfo = Config.Sprays[v.model]
                if graffitiInfo and graffitiInfo.gang and graffitiInfo.gang ~= playerGang then
                    return false, "Enemy gang territory detected! Remove the " .. graffitiInfo.gang .. " graffiti first (Distance: " .. math.floor(distance) .. "m)"
                end
            end
        end
    end
    
    return true, nil
end

function GetOnlineGangMembers(gangName)
    local gangMembers = {}
    local Players = QBCore.Functions.GetQBPlayers()
    
    for playerId, player in pairs(Players) do
        if player.PlayerData.gang and player.PlayerData.gang.name == gangName then
            table.insert(gangMembers, {
                source = playerId,
                player = player,
                name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
            })
        end
    end
    
    return gangMembers
end

function NotifyGangMembers(gangName, notification)
    local gangMembers = GetOnlineGangMembers(gangName)
    
    for _, member in pairs(gangMembers) do
        TriggerClientEvent('ox_lib:notify', member.source, notification)
    end
end

function GetGraffitiOwnerInfo(citizenid)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player then
        return {
            online = true,
            name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            gang = Player.PlayerData.gang and Player.PlayerData.gang.name or nil
        }
    else
        local result = MySQL.query.await('SELECT charinfo, gang FROM players WHERE citizenid = @citizenid', {
            ['@citizenid'] = citizenid
        })
        
        if result and result[1] then
            local charinfo = json.decode(result[1].charinfo)
            local gang = result[1].gang and json.decode(result[1].gang) or nil
            
            return {
                online = false,
                name = charinfo.firstname .. " " .. charinfo.lastname,
                gang = gang and gang.name or nil
            }
        end
    end
    
    return nil
end

function LogGangTerritoryAction(action, playerData, graffitiData, location)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = string.format(
        "[%s] GANG TERRITORY - %s: Player %s (%s) %s %s graffiti at %s",
        timestamp,
        action,
        playerData.name,
        playerData.gang or "No Gang",
        action == "PLACE" and "placed" or "removed",
        graffitiData.gang or "neutral",
        json.encode(location)
    )
    
    print("^2" .. logMessage .. "^7")
end

function table.length(T)
    local count = 0
    if T then
        for _ in pairs(T) do 
            count = count + 1 
        end
    end
    return count
end