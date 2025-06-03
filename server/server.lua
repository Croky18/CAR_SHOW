local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('carshow:requestVehicles', function()
    local src = source
    exports.oxmysql:execute('SELECT * FROM carshow_vehicles', {}, function(result)
        if result then
            local vehicles = {}
            for _, v in pairs(result) do
                table.insert(vehicles, {
                    model = v.model,
                    coords = vector4(v.x, v.y, v.z, v.w),
                    price = v.price or 0
                })
            end
            TriggerClientEvent('carshow:spawnVehicles', src, vehicles)
        end
    end)
end)


RegisterNetEvent('carshow:deleteVehicleByModel', function(modelName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData.job.name == Config.AllowedJob then
        local result = exports.oxmysql:executeSync('DELETE FROM carshow_vehicles WHERE model = ?', { modelName })
        TriggerClientEvent('oxib:notify', src, {
            description = ('%s verwijderd uit database.'):format(modelName),
            type = 'success'
        })
    else
        TriggerClientEvent('oxib:notify', src, { description = 'Geen rechten om te verwijderen.', type = 'error' })
    end
end)


RegisterNetEvent('carshow:saveVehicleToDatabase', function(model, x, y, z, w, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData.job.name == Config.AllowedJob then
        exports.oxmysql:insert('INSERT INTO carshow_vehicles (model, x, y, z, w, price) VALUES (?, ?, ?, ?, ?, ?)', {
            model, x, y, z, w, price
        })
        TriggerClientEvent('oxib:notify', src, { description = 'Voertuig opgeslagen met prijs!', type = 'success' })
    else
        TriggerClientEvent('oxib:notify', src, { description = 'Geen rechten om op te slaan.', type = 'error' })
    end
end)


lib.callback.register('carshow:isVehicleInDatabase', function(source, model)
    local result = exports.oxmysql:executeSync('SELECT 1 FROM carshow_vehicles WHERE model = ? LIMIT 1', { model })
    return result and #result > 0
end)

lib.callback.register('carshow:getPlayerJob', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.job.name
    end
    return nil
end)