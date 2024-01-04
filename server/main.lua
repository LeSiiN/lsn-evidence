------------------------------------------------------------------------------[ VARIABLES ]------------------------------------------------------------------------------
local Casings = {}
local Bullethole = {}
local Fragements = {}
local BloodDrops = {}
local FingerDrops = {}
local QBCore = exports['qb-core']:GetCoreObject()
local fingerprintsList = {}

------------------------------------------------------------------------------[ FUNCTIONS ]------------------------------------------------------------------------------
local function CreateBloodId()
    if BloodDrops then
        local bloodId = math.random(10000, 99999)
        while BloodDrops[bloodId] do
            bloodId = math.random(10000, 99999)
        end
        return bloodId
    else
        local bloodId = math.random(10000, 99999)
        return bloodId
    end
end

local function CreateFingerId()
    if FingerDrops then
        local fingerId = math.random(10000, 99999)
        while FingerDrops[fingerId] do
            fingerId = math.random(10000, 99999)
        end
        return fingerId
    else
        local fingerId = math.random(10000, 99999)
        return fingerId
    end
end

local function CreateCasingId()
    if Casings then
        local caseId = math.random(10000, 99999)
        while Casings[caseId] do
            caseId = math.random(10000, 99999)
        end
        return caseId
    else
        local caseId = math.random(10000, 99999)
        return caseId
    end
end

local function CreateBulletholeId()
    if Bullethole then
        local holesId = math.random(10000, 99999)
        while Bullethole[holesId] do
            holesId = math.random(10000, 99999)
        end
        return holesId
    else
        local holesId = math.random(10000, 99999)
        return holesId
    end
end

local function CreateVehicleFragementId()
    if VehicleFragement then
        local fragementId = math.random(10000, 99999)
        while VehicleFragement[fragementId] do
            fragementId = math.random(10000, 99999)
        end
        return fragementId
    else
        local fragementId = math.random(10000, 99999)
        return fragementId
    end
end

local function DnaHash(s)
    local h = string.gsub(s, '.', function(c)
        return string.format('%02x', string.byte(c))
    end)
    return h
end

------------------------------------------------------------------------------[ COMMANDS ]------------------------------------------------------------------------------
if Config.Commands then
    lib.addCommand('clearcasings', {
        help = Lang:t('commands.clear_casign')
    }, function(source, raw)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            TriggerClientEvent('evidence:client:ClearCasingsInArea', src)
        else
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
            elseif Config.Notify == "ox" then
                TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.on_duty_police_only'), type= 'error'})
            else
                print(Lang:t('error.config_error'))
            end
        end
    end)

    lib.addCommand('clearholes', {
        help = Lang:t('commands.clear_bullethole')
    }, function(source, raw)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            TriggerClientEvent('evidence:client:ClearBulletholeInArea', src)
        else
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
            elseif Config.Notify == "ox" then
                TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.on_duty_police_only'), type= 'error'})
            else
                print(Lang:t('error.config_error'))
            end
        end
    end)

    lib.addCommand('clearfragements', {
        help = Lang:t('commands.clear_fragements')
    }, function(source, raw)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            TriggerClientEvent('evidence:client:ClearVehicleFragementsInArea', src)
        else
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
            elseif Config.Notify == "ox" then
                TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.on_duty_police_only'), type= 'error'})
            else
                print(Lang:t('error.config_error'))
            end
        end
    end)

    lib.addCommand('clearscene', {
        help = Lang:t('commands.clear_crime_scene')
    }, function(source, raw)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            TriggerClientEvent('evidence:client:ClearScene', src)
        else
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
            elseif Config.Notify == "ox" then
                TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.on_duty_police_only'), type= 'error'})
            else
                print(Lang:t('error.config_error'))
            end
        end
    end)

    lib.addCommand('clearblood', {
        help = Lang:t('commands.clearblood')
    }, function(source, raw)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            TriggerClientEvent('evidence:client:ClearBlooddropsInArea', src)
        else
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
            elseif Config.Notify == "ox" then
                TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.on_duty_police_only'), type= 'error'})
            else
                print(Lang:t('error.config_error'))
            end
        end
    end)

    lib.addCommand('takedna', {
        help = Lang:t('commands.takedna'),
        params = {
            {
                name = 'id',
                type = 'playerId',
                help = Lang:t('info.player_id'),
            },
        },
    }, function(source, args, raw)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local OtherPlayer = QBCore.Functions.GetPlayer(tonumber(args.id))
        if not OtherPlayer or Player.PlayerData.job.type ~= 'leo' or not Player.PlayerData.job.onduty then return end
        if Player.Functions.RemoveItem('empty_evidence_bag', 1) then
            local info = {
                label = Lang:t('info.dna_sample'),
                type = 'dna',
                dnalabel = DnaHash(OtherPlayer.PlayerData.citizenid)
            }
            if not Player.Functions.AddItem('filled_evidence_bag', 1, false, info) then return end
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
        else
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
            elseif Config.Notify == "ox" then
                TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.on_duty_police_only'), type= 'error'})
            else
                print(Lang:t('error.config_error'))
            end
        end
    end)
end
------------------------------------------------------------------------------[ ITEMS ]------------------------------------------------------------------------------
QBCore.Functions.CreateUseableItem("rag", function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Player.Functions.RemoveItem("rag", 1) then return end
    TriggerClientEvent('evidence:client:ClearSceneCrime', src)
end)

QBCore.Functions.CreateUseableItem("evidencecleaningkit", function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
        if not Player.Functions.RemoveItem("evidencecleaningkit", 1) then return end
        TriggerClientEvent('evidence:client:ClearScene', src)
    else
        if Config.Notify == "qb" then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
        elseif Config.Notify == "ox" then
            TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.on_duty_police_only'), type= 'error'})
        else
            print(Lang:t('error.config_error'))
        end
    end
end)

if Config.ShowShootersLine then
    QBCore.Functions.CreateUseableItem("policepointer", function(source)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        TriggerClientEvent('evidence:client:toggleDrawLine', src)
    end)
end
------------------------------------------------------------------------------[ EVENTS ]------------------------------------------------------------------------------

-----------------------------------------[ BLOOD ]-----------------------------------------
RegisterNetEvent('evidence:server:CreateBloodDrop', function(citizenid, bloodtype, coords)
    local bloodId = CreateBloodId()
    BloodDrops[bloodId] = {
        dna = citizenid,
        bloodtype = bloodtype
    }
    TriggerClientEvent('evidence:client:AddBlooddrop', -1, bloodId, citizenid, bloodtype, coords)
end)


RegisterNetEvent('evidence:server:ClearBlooddrops', function(blooddropList)
    if blooddropList and next(blooddropList) then
        for _, v in pairs(blooddropList) do
            TriggerClientEvent('evidence:client:RemoveBlooddrop', -1, v)
            BloodDrops[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddBlooddropToInventory', function(bloodId, bloodInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem('empty_evidence_bag', 1) then
        TriggerClientEvent('evidence:client:PlayerPickUpAnimation', src)
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, bloodInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveBlooddrop', -1, bloodId)
            BloodDrops[bloodId] = nil
        end
    else
        if Config.Notify == "qb" then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.have_evidence_bag'), 'error')
        elseif Config.Notify == "ox" then
            TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.have_evidence_bag'), type= 'error'})
        else
            print(Lang:t('error.config_error'))
        end
    end
end)

-----------------------------------------[ FINGERPRINTS ]-----------------------------------------
RegisterNetEvent('evidence:server:CreateFingerDrop', function(coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local fingerId = CreateFingerId()
    FingerDrops[fingerId] = Player.PlayerData.metadata['fingerprint']
    TriggerClientEvent('evidence:client:AddFingerPrint', -1, fingerId, Player.PlayerData.metadata['fingerprint'], coords)
end)

RegisterNetEvent('evidence:server:ClearFingerprints', function(fingerprintList)
    if fingerprintList and next(fingerprintList) then
        for _, v in pairs(fingerprintList) do
            TriggerClientEvent('evidence:client:RemoveFingerprint', -1, v)
            FingerDrops[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddFingerprintToInventory', function(fingerId, fingerInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem('empty_evidence_bag', 1) then
        TriggerClientEvent('evidence:client:PlayerPickUpAnimation', src)
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, fingerInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveFingerprint', -1, fingerId)
            FingerDrops[fingerId] = nil
        end
    else
        if Config.Notify == "qb" then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.have_evidence_bag'), 'error')
        elseif Config.Notify == "ox" then
            TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.have_evidence_bag'), type= 'error'})
        else
            print(Lang:t('error.config_error'))
        end
    end
end)

-----------------------------------------[ CASINGS ]-----------------------------------------
RegisterNetEvent('evidence:server:CreateCasing', function(weapon, coords, currentTime, pedcoords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local casingId = CreateCasingId()
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    local serieNumber = nil
    if weaponInfo then
        local weaponItem = Player.Functions.GetItemByName(weaponInfo['name'])
        if weaponItem then
            if weaponItem.info and weaponItem.info ~= '' then
                serieNumber = weaponItem.info.serie
            end
        end
    end
    TriggerClientEvent('evidence:client:AddCasing', -1, casingId, weapon, coords, serieNumber, currentTime, pedcoords)
end)

RegisterNetEvent('evidence:server:ClearCasings', function(casingList)
    if casingList and next(casingList) then
        for _, v in pairs(casingList) do
            TriggerClientEvent('evidence:client:RemoveCasing', -1, v)
            Casings[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddCasingToInventory', function(casingId, casingInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem('empty_evidence_bag', 1) then
        TriggerClientEvent('evidence:client:PlayerPickUpAnimation', src)
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, casingInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveCasing', -1, casingId)
            Casings[casingId] = nil
        end
    else
        if Config.Notify == "qb" then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.have_evidence_bag'), 'error')
        elseif Config.Notify == "ox" then
            TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.have_evidence_bag'), type= 'error'})
        else
            print(Lang:t('error.config_error'))
        end
    end
end)

-----------------------------------------[ BULLET HOLES ]-----------------------------------------
RegisterNetEvent('evidence:server:CreateBullethole', function(weapon, raycastcoords, pedcoords, heading, currentTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local bulletholeId = CreateBulletholeId()
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    local serieNumber = nil
    if weaponInfo then
        local weaponItem = Player.Functions.GetItemByName(weaponInfo['name'])
        if weaponItem then
            if weaponItem.info and weaponItem.info ~= '' then
                serieNumber = weaponItem.info.serie
            end
        end
    end
    TriggerClientEvent('evidence:client:AddBullethole', -1, bulletholeId, weapon, raycastcoords, pedcoords, heading, currentTime, serieNumber)
end)

RegisterNetEvent('evidence:server:ClearBullethole', function(bulletholeList)
    if bulletholeList and next(bulletholeList) then
        for _, v in pairs(bulletholeList) do
            TriggerClientEvent('evidence:client:RemoveBullethole', -1, v)
            Bullethole[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddBulletToInventory', function(bulletholeId, bulletInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem('empty_evidence_bag', 1) then
        TriggerClientEvent('evidence:client:PlayerPickUpAnimation', src)
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, bulletInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveBullethole', -1, bulletholeId)
            Bullethole[bulletholeId] = nil
        end
    else
        if Config.Notify == "qb" then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.have_evidence_bag'), 'error')
        elseif Config.Notify == "ox" then
            TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.have_evidence_bag'), type= 'error'})
        else
            print(Lang:t('error.config_error'))
        end
    end
end)

-----------------------------------------[ VEHICLE FRAGEMENTS ]-----------------------------------------
RegisterNetEvent('evidence:server:CreateVehicleFragement', function(weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local vehiclefragementId = CreateVehicleFragementId()
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    local serieNumber = nil
    if weaponInfo then
        local weaponItem = Player.Functions.GetItemByName(weaponInfo['name'])
        if weaponItem then
            if weaponItem.info and weaponItem.info ~= '' then
                serieNumber = weaponItem.info.serie
            end
        end
    end
    TriggerClientEvent('evidence:client:AddVehicleFragement', -1, vehiclefragementId, weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b, serieNumber)
end)

RegisterNetEvent('evidence:server:ClearVehicleFragements', function(vehiclefragmentList)
    if vehiclefragmentList and next(vehiclefragmentList) then
        for _, v in pairs(vehiclefragmentList) do
            TriggerClientEvent('evidence:client:RemoveVehicleFragement', -1, v)
            Fragements[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddFragementToInventory', function(vehiclefragementId, fragementInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem('empty_evidence_bag', 1) then
        TriggerClientEvent('evidence:client:PlayerPickUpAnimation', src)
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, fragementInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveVehicleFragement', -1, vehiclefragementId)
            Fragements[vehiclefragementId] = nil
        end
    else
        if Config.Notify == "qb" then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.have_evidence_bag'), 'error')
        elseif Config.Notify == "ox" then
            TriggerClientEvent("ox_lib:notify", src, {title= "Evidence", description= Lang:t('error.have_evidence_bag'), type= 'error'})
        else
            print(Lang:t('error.config_error'))
        end
    end
end)
