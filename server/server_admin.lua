local QBCore = exports['qb-core']:GetCoreObject()

local function isAdmin(src)
    return QBCore.Functions.HasPermission(src, 'admin')
end

lib.addCommand('cleargraffiti', {
    help = 'Clear all graffiti from the map',
    restricted = 'group.admin'
}, function(source)
    if not isAdmin(source) then
        return TriggerClientEvent('ox_lib:notify', source, {
            description = 'You do not have permission to use this command.',
            type = 'error'
        })
    end

    MySQL.query('DELETE FROM `graffitis`', {}, function()
        Config.Graffitis = {}
        UpdateGraffitiData()
        TriggerClientEvent('ox_lib:notify', -1, {
            description = 'All graffiti has been cleared by an admin.',
            type = 'inform'
        })
    end)
end)

lib.addCommand('spawnspraycan', {
    help = 'Give yourself a spraycan item (admin only)',
    restricted = 'group.admin'
}, function(source)
    if not isAdmin(source) then
        return TriggerClientEvent('ox_lib:notify', source, {
            description = 'You do not have permission to use this command.',
            type = 'error'
        })
    end

    local sprayOptions = {}
    for modelHash, sprayData in pairs(Config.Sprays) do
        sprayOptions[#sprayOptions + 1] = {
            value = modelHash,
            label = sprayData.name
        }
    end

    TriggerClientEvent('graffiti:adminSpawnSprayInput', source, sprayOptions)
end)

RegisterNetEvent('graffiti:serverGiveSpray', function(modelHash)
    local src = source
    if not isAdmin(src) then return end

    local sprayInfo = Config.Sprays[tonumber(modelHash)]
    if not sprayInfo then
        return TriggerClientEvent('ox_lib:notify', src, {
            description = 'Invalid graffiti selection.',
            type = 'error'
        })
    end

    exports.ox_inventory:AddItem(src, 'spraycan', 1, {
        model = tonumber(modelHash),
        name = sprayInfo.name,
        description = 'Spray: ' .. sprayInfo.name
    })

    TriggerClientEvent('ox_lib:notify', src, {
        description = 'You have been given a spraycan for: ' .. sprayInfo.name,
        type = 'success'
    })
end)