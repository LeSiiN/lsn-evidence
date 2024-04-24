------------------------------------------------------------------------------[ VARIABLES ]------------------------------------------------------------------------------
local QBCore = exports['qb-core']:GetCoreObject()
local resourceState = GetResourceState('lsn-evidence')
local ox_inventoryState = GetResourceState('ox_inventory')

local Casings = {}
local Bullethole = {}
local Fragments = {}
local BloodDrops = {}
local FingerDrops = {}
local FootprintDrops = {}
local fingerprintsList = {}

------------------------------------------------------------------------------[ FUNCTIONS ]------------------------------------------------------------------------------
local function CreateEvidenceId(type)
    local evidenceTable = {
        blood = BloodDrops,
        finger = FingerDrops,
        casing = Casings,
        bullethole = Bullethole,
        vehiclefragment = Fragments,
        footprint = FootprintDrops
    }

    if evidenceTable[type] then
        local evidenceId = math.random(10000, 99999)
        while evidenceTable[type][evidenceId] do
            evidenceId = math.random(10000, 99999)
        end
        evidenceTable[type][evidenceId] = {
            serverTime = os.time()
        }
        return evidenceId
    else
        local randomId = math.random(10000, 99999)
        evidenceTable[type][randomId] = {
            serverTime = os.time()
        }
        return randomId
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

    lib.addCommand('clearfragments', {
        help = Lang:t('commands.clear_fragments')
    }, function(source, raw)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            TriggerClientEvent('evidence:client:ClearVehicleFragmentsInArea', src)
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

    lib.addCommand('clearfootprints', {
        help = Lang:t('commands.clearfootprint')
    }, function(source, raw)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            TriggerClientEvent('evidence:client:ClearFootprintInArea', src)
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
------------------------------------------------------------------------------[ EVENTS ]------------------------------------------------------------------------------

-----------------------------------------[ BLOOD ]-----------------------------------------
-- RegisterNetEvent('evidence:server:CreateBloodDrop', function(citizenid, bloodtype, coords)
--     local bloodId = CreateEvidenceId("blood")
--     BloodDrops[bloodId] = {
--         dna = citizenid,
--         bloodtype = bloodtype
--     }
--     TriggerClientEvent('evidence:client:AddBlooddrop', -1, bloodId, citizenid, bloodtype, coords)
-- end)

RegisterNetEvent('evidence:server:CreateBloodDrop', function(citizenid, bloodtype, coords)
    local bloodId = CreateEvidenceId("blood")
    BloodDrops[bloodId].dna = citizenid
    BloodDrops[bloodId].bloodtype = bloodtype
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
        if ox_inventoryState == 'started' then
            local info = {}
            info.label = bloodInfo.label
            info.type = bloodInfo.type
            info.street = bloodInfo.street
            info.dnalabel = bloodInfo.dnalabel
            info.dnalabel2 = bloodInfo.dnalabel2
            info.bloodtype = bloodInfo.bloodtype
            info.bloodtype2 = bloodInfo.bloodtype2
            if exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then
                exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, info)
            end
            TriggerClientEvent('evidence:client:RemoveBlooddrop', -1, bloodId)
            BloodDrops[bloodId] = nil
        else
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, bloodInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveBlooddrop', -1, bloodId)
            BloodDrops[bloodId] = nil
        end
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
    local fingerId = CreateEvidenceId("finger")
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
        if ox_inventoryState == 'started' then
            local info = {}
            info.label = fingerInfo.label
            info.type = fingerInfo.type
            info.street = fingerInfo.street
            info.serie = fingerInfo.fingerprint
            info.serie2 = fingerInfo.fingerprint2
            if exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then
                exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, info)
            end
            TriggerClientEvent('evidence:client:RemoveFingerprint', -1, fingerId)
            FingerDrops[fingerId] = nil
        else
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, fingerInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveFingerprint', -1, fingerId)
            FingerDrops[fingerId] = nil
        end
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
RegisterNetEvent('evidence:server:CreateCasing', function(weapon, coords, currentTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local casingId = CreateEvidenceId("casing")
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    local serieNumber = nil

    if ox_inventoryState == 'started' then
        weaponInfo = exports.ox_inventory:GetCurrentWeapon(src)
        if weaponInfo then
            if weaponInfo.metadata and weaponInfo.metadata ~= '' then
                serieNumber = weaponInfo.metadata.serial
            end
        end
    else
        if weaponInfo then
            local weaponItem = Player.Functions.GetItemByName(weaponInfo['name'])
            if weaponItem then
                if weaponItem.info and weaponItem.info ~= '' then
                    serieNumber = weaponItem.info.serie
                end
            end
        end
    end
    TriggerClientEvent('evidence:client:AddCasing', -1, casingId, weapon, coords, serieNumber, currentTime)
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
        if ox_inventoryState == 'started' then
            local info = {}
            info.label = casingInfo.label
            info.type = casingInfo.type
            info.street = casingInfo.street
            info.ammolabel = casingInfo.ammolabel
            info.ammotype = casingInfo.ammotype
            info.ammotype2 = casingInfo.ammotype2
            info.serie = casingInfo.serie
            info.serie2 = casingInfo.serie2
            if exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then
                exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, info)
            end
            TriggerClientEvent('evidence:client:RemoveCasing', -1, casingId)
            Casings[casingId] = nil
        else
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, casingInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveCasing', -1, casingId)
            Casings[casingId] = nil
        end
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
    local bulletholeId = CreateEvidenceId("bullethole")
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    local serieNumber = nil

    if ox_inventoryState == 'started' then
        weaponInfo = exports.ox_inventory:GetCurrentWeapon(src)
        if weaponInfo then
            if weaponInfo.metadata and weaponInfo.metadata ~= '' then
                serieNumber = weaponInfo.metadata.serial
            end
        end
    else
        if weaponInfo then
            local weaponItem = Player.Functions.GetItemByName(weaponInfo['name'])
            if weaponItem then
                if weaponItem.info and weaponItem.info ~= '' then
                    serieNumber = weaponItem.info.serie
                end
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
        if ox_inventoryState == 'started' then
            local info = {}
            info.label = bulletInfo.label
            info.type = bulletInfo.type
            info.street = bulletInfo.street
            info.ammolabel = bulletInfo.ammolabel
            info.ammotype = bulletInfo.ammotype
            info.ammotype2 = bulletInfo.ammotype2
            info.serie = bulletInfo.serie
            info.serie2 = bulletInfo.serie2
            if exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then
                exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, info)
            end
            TriggerClientEvent('evidence:client:RemoveBullethole', -1, bulletholeId)
            Bullethole[bulletholeId] = nil
        else
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, bulletInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveBullethole', -1, bulletholeId)
            Bullethole[bulletholeId] = nil
        end
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
RegisterNetEvent('evidence:server:CreateVehicleFragment', function(weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local fragmentId = CreateEvidenceId("vehiclefragment")
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    local serieNumber = nil

    if ox_inventoryState == 'started' then
        weaponInfo = exports.ox_inventory:GetCurrentWeapon(src)
        if weaponInfo then
            if weaponInfo.metadata and weaponInfo.metadata ~= '' then
                serieNumber = weaponInfo.metadata.serial
            end
        end
    else
        if weaponInfo then
            local weaponItem = Player.Functions.GetItemByName(weaponInfo['name'])
            if weaponItem then
                if weaponItem.info and weaponItem.info ~= '' then
                    serieNumber = weaponItem.info.serie
                end
            end
        end
    end
    TriggerClientEvent('evidence:client:AddVehicleFragment', -1, fragmentId, weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b, serieNumber)
end)

RegisterNetEvent('evidence:server:ClearVehicleFragments', function(vehiclefragmentList)
    if vehiclefragmentList and next(vehiclefragmentList) then
        for _, v in pairs(vehiclefragmentList) do
            TriggerClientEvent('evidence:client:RemoveVehicleFragment', -1, v)
            Fragments[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddFragmentToInventory', function(vehiclefragmentId, fragmentInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem('empty_evidence_bag', 1) then
        TriggerClientEvent('evidence:client:PlayerPickUpAnimation', src)
        if ox_inventoryState == 'started' then
            local info = {}
            info.label = fragmentInfo.label
            info.type = fragmentInfo.type
            info.street = fragmentInfo.street
            info.rgb = fragmentInfo.rgb
            info.rgb2 = fragmentInfo.rgb2
            info.ammotype = fragmentInfo.ammotype
            info.ammotype2 = fragmentInfo.ammotype2
            info.serie = fragmentInfo.serie
            info.serie2 = fragmentInfo.serie2
            if exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then
                exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, info)
            end
            TriggerClientEvent('evidence:client:RemoveVehicleFragment', -1, vehiclefragmentId)
            Fragments[vehiclefragmentId] = nil
        else
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, fragmentInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveVehicleFragment', -1, vehiclefragmentId)
            Fragments[vehiclefragmentId] = nil
        end
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

-----------------------------------------[ FOOTPRINTS ]-----------------------------------------
RegisterNetEvent('evidence:server:CreateFootPrint', function(shoes, coords, currentTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local footprintId = CreateEvidenceId("footprint")
    TriggerClientEvent('evidence:client:AddFootPrint', -1, footprintId, shoes, coords, currentTime)
end)

RegisterNetEvent('evidence:server:ClearFootPrints', function(footprintList)
    if footprintList and next(footprintList) then
        for _, v in pairs(footprintList) do
            TriggerClientEvent('evidence:client:RemoveFootPrint', -1, v)
            FootprintDrops[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddFootPrintToInventory', function(footprintId, footprintInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem('empty_evidence_bag', 1) then
        TriggerClientEvent('evidence:client:PlayerPickUpAnimation', src)
        if ox_inventoryState == 'started' then
            local info = {}
            info.label = footprintInfo.label
            info.type = footprintInfo.type
            info.street = footprintInfo.street
            info.shoes = footprintInfo.shoes
            info.shoes2 = footprintInfo.shoes2
            if exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then
                exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, info)
            end
            TriggerClientEvent('evidence:client:RemoveCasing', -1, footprintId)
            FootprintDrops[footprintId] = nil
        else
        if Player.Functions.AddItem('filled_evidence_bag', 1, false, footprintInfo) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['filled_evidence_bag'], 'add')
            TriggerClientEvent('evidence:client:RemoveCasing', -1, footprintId)
            FootprintDrops[footprintId] = nil
        end
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

-----------------------------------------[ deleteEvidence Logic ]-----------------------------------------
lib.cron.new('*/' ..Config.RemoveEvidence.. ' * * * *', function()
    TriggerClientEvent("evidence:client:deleteEvidence", -1)

    local evidenceTable = {
        blood = BloodDrops,
        finger = FingerDrops,
        casing = Casings,
        bullethole = Bullethole,
        vehiclefragment = Fragments,
        footprint = FootprintDrops
    }
    for k, v in pairs(evidenceTable) do
        for k2, v2 in pairs(v) do
            if v2.serverTime + Config.RemoveEvidence * 60 < os.time() then
                v[k2] = nil
            end
        end
    end
end)
