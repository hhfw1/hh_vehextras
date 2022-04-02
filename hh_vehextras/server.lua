local QBCore = exports['qb-core']:GetCoreObject()



function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.Sync.fetchScalar('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end



QBCore.Commands.Add("givecar", "Give Vehicle to Players (Admin Only)", {{name="id", help="Player ID"}, {name="model", help="Vehicle Model, for example: t20"}, {name="plate", help="Custom Number Plate (Leave to assign random) , for example: ABC123"}}, false, function(source, args)
    local src = source
    local ply = QBCore.Functions.GetPlayer(src)
    local tPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local veh = args[2]
    local plate = args[3]
    if not plate or plate == "" then plate = GeneratePlate() end
    if veh and tPlayer then
        TriggerClientEvent('hhfw:client:givecar', args[1], veh, plate)
	TriggerClientEvent("QBCore:Notify", src, "You gave vehilce to "..tPlayer.PlayerData.charinfo.firstname.." "..tPlayer.PlayerData.charinfo.lastname.." Vehicle :"..veh.." With Plate : "..plate, "success", 8000)
    else 
        TriggerClientEvent('QBCore:Notify', src, "Incorrect Format", "error")
    end
end, "god")



RegisterServerEvent('hhfw:server:SaveCar', function(mods, vehicle, hash, plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local result = MySQL.Sync.fetchAll('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    if result[1] == nil then
	MySQL.Async.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            Player.PlayerData.citizenid,
            vehicle.model,
            vehicle.hash,
            json.encode(mods),
            plate,
            0
        })
        TriggerClientEvent('QBCore:Notify', src, 'The vehicle is now yours!', 'success', 5000)
    else
        TriggerClientEvent('QBCore:Notify', src, 'This vehicle is already yours..', 'error', 3000)
    end
end)



-------------Transfer Vehicle-------------


QBCore.Commands.Add("transfercar", "Transfer Vehicle to Other Player (Must Be in Vehicle)", {{name="id", help="Player ID"}}, false, function(source, args)
    local id = args[1]
    if id then
        TriggerClientEvent('hhfw:client:transferrc', source, id)
    else 
        TriggerClientEvent('QBCore:Notify', source, "Please Provide ID", "error")
    end
end)


RegisterServerEvent('hhfw:GiveRC', function(player, target, plate)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(player)
    local tPlayer = QBCore.Functions.GetPlayer(target)
    MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, xPlayer.PlayerData.citizenid}, function(result)  
        if result[1] and next(result[1]) then
            if plate == result[1].plate then
                MySQL.Async.execute('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', {tPlayer.PlayerData.citizenid, tPlayer.PlayerData.license, result[1].plate})
                TriggerClientEvent("QBCore:Notify", player.PlayerData.source, "You gave registration paper to "..tPlayer.PlayerData.charinfo.firstname.." "..tPlayer.PlayerData.charinfo.lastname, "success", 8000)
                TriggerClientEvent("QBCore:Notify", target.PlayerData.source, "You received registration paper from "..xPlayer.PlayerData.charinfo.firstname.." "..xPlayer.PlayerData.charinfo.lastname, "success", 8000)     
            else
                TriggerClientEvent("QBCore:Notify", src, "You dont't own this vehicle", "error", 5000)
            end
        else
            TriggerClientEvent("QBCore:Notify", src, "You dont't own this vehicle", "error", 5000)
        end
    end)
end)



