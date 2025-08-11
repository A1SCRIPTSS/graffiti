RegisterNetEvent('graffiti:adminSpawnSprayInput', function(sprayOptions)
    local input = lib.inputDialog('Spawn Spraycan', {
        {
            type = 'select',
            label = 'Select Spray Type',
            options = sprayOptions,
            required = true
        }
    })

    if input and input[1] then
        TriggerServerEvent('graffiti:serverGiveSpray', input[1])
    end
end)