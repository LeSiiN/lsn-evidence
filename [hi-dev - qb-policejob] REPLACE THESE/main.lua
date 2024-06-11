-- Variables
local Plates = {}
local PlayerStatus = {}
local Objects = {}
QBCore = exports['qb-core']:GetCoreObject()
local updatingCops = false
local CuffedPlayers = {}
local seckey = "hidev-"..math.random(111111, 999999)
local GPSTable = {}
local RepairPed = {}
local LEOjobs = {}
local AlcoholStats = {}


-- Functions
local function UpdateBlips()
    local dutyPlayers = {}
    for k, v in pairs(GPSTable) do
        local ply = k
        local coords = GetEntityCoords(GetPlayerPed(ply))
        local heading = GetEntityHeading(GetPlayerPed(ply))
        dutyPlayers[#dutyPlayers+1] = {
            source = ply,
            label = v.call,
            vehClass = v.vehClass,
            job = v.job,
            gpsactive = v.gpsactive,
            location = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                w = heading
            }
        }
    end
    for k, v in pairs(GPSTable) do
        if k == v.source then
            TriggerClientEvent("police:client:UpdateBlips", k, dutyPlayers)
        end
    end
end

local function CreateObjectId()
    if Objects then
        local objectId = math.random(10000, 99999)
        while Objects[objectId] do
            objectId = math.random(10000, 99999)
        end
        return objectId
    else
        local objectId = math.random(10000, 99999)
        return objectId
    end
end

local function IsVehicleOwned(plate)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    return result
end

local function GetCurrentCops()
    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" and v.PlayerData.job.onduty then
            amount += 1
        end
    end
    return amount
end

local function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end
-- Commands
QBCore.Commands.Add("spikestrip", Lang:t("commands.place_spike"), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent('police:client:SpawnSpikeStrip', src)
    end
end)

QBCore.Commands.Add("grantlicense", Lang:t("commands.license_grant"), {{name = "id", help = Lang:t('info.player_id')}, {name = "license", help = Lang:t('info.license_type')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.grade.level >= Config.LicenseRank then
        if args[2] == "driver" or args[2] == "weapon" or args[2] == "hunting" then
            local SearchedPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
            if not SearchedPlayer then return end
            local licenseTable = SearchedPlayer.PlayerData.metadata["licences"]
            if licenseTable[args[2]] then
                TriggerClientEvent('QBCore:Notify', src, Lang:t("error.license_already"), "error")
                return
            end
            licenseTable[args[2]] = true
            SearchedPlayer.Functions.SetMetaData("licences", licenseTable)
            TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("success.granted_license"), "success")
            TriggerClientEvent('QBCore:Notify', src, Lang:t("success.grant_license"), "success")
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t("error.error_license_type"), "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.rank_license"), "error")
    end
end)

QBCore.Commands.Add("revokelicense", Lang:t("commands.license_revoke"), {{name = "id", help = Lang:t('info.player_id')}, {name = "license", help = Lang:t('info.license_type')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.grade.level >= Config.LicenseRank then
        if args[2] == "driver" or args[2] == "weapon" then
            local SearchedPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
            if not SearchedPlayer then return end
            local licenseTable = SearchedPlayer.PlayerData.metadata["licences"]
            if not licenseTable[args[2]] then
                TriggerClientEvent('QBCore:Notify', src, Lang:t("error.error_license"), "error")
                return
            end
            licenseTable[args[2]] = false
            SearchedPlayer.Functions.SetMetaData("licences", licenseTable)
            TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("error.revoked_license"), "error")
            TriggerClientEvent('QBCore:Notify', src, Lang:t("success.revoke_license"), "success")
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t("error.error_license"), "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.rank_revoke"), "error")
    end
end)

QBCore.Commands.Add("pobject", Lang:t("commands.place_object"), {{name = "type",help = Lang:t("info.poobject_object")}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local type = args[1]:lower()
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        if type == "cone" then
            TriggerClientEvent("police:client:spawnCone", src)
        elseif type == "barrier" then
            TriggerClientEvent("police:client:spawnBarrier", src)
        elseif type == "roadsign" then
            TriggerClientEvent("police:client:spawnRoadSign", src)
        elseif type == "tent" then
            TriggerClientEvent("police:client:spawnTent", src)
        elseif type == "light" then
            TriggerClientEvent("police:client:spawnLight", src)
        elseif type == "delete" then
            TriggerClientEvent("police:client:deleteObject", src)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("cuff", Lang:t("commands.cuff_player"), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:CuffPlayer", src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("escort", Lang:t("commands.escort"), {}, false, function(source)
    local src = source
    TriggerClientEvent("police:client:EscortPlayer", src)
end)

QBCore.Commands.Add("callsign", Lang:t("commands.callsign"), {{name = "name", help = Lang:t('info.callsign_name')}}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.SetMetaData("callsign", table.concat(args, " "))
end)

QBCore.Commands.Add("jail", Lang:t("commands.jail_player"), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:JailPlayer", src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("unjail", Lang:t("commands.unjail_player"), {{name = "id", help = Lang:t('info.player_id')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        local playerId = tonumber(args[1])
        TriggerClientEvent("prison:client:UnjailPerson", playerId)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add('addpromille', 'Add alcohol promille', {{name= "id", help = Lang:t('info.player_id')}, {name = "promille", help = "How many promille"}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        local playerId = tonumber(args[1])
        local promille = tonumber(args[2])
        TriggerEvent("police:server:UpdateAlcohol", playerId, promille)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)
QBCore.Commands.Add("seizecash", Lang:t("commands.seizecash"), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:SeizeCash", src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("cam", Lang:t("commands.camera"), {{name = "camid", help = Lang:t('info.camera_id')}}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:ActiveCamera", src, tonumber(args[1]))
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("flagplate", Lang:t("commands.flagplate"), {{name = "plate", help = Lang:t('info.plate_number')}, {name = "reason", help = Lang:t('info.flag_reason')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        local reason = {}
        for i = 2, #args, 1 do
            reason[#reason+1] = args[i]
        end
        Plates[args[1]:upper()] = {
            isflagged = true,
            reason = table.concat(reason, " ")
        }
        TriggerClientEvent('QBCore:Notify', src, Lang:t("info.vehicle_flagged", {vehicle = args[1]:upper(), reason = table.concat(reason, " ")}))
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("unflagplate", Lang:t("commands.unflagplate"), {{name = "plate", help = Lang:t('info.plate_number')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        if Plates and Plates[args[1]:upper()] then
            if Plates[args[1]:upper()].isflagged then
                Plates[args[1]:upper()].isflagged = false
                TriggerClientEvent('QBCore:Notify', src, Lang:t("info.unflag_vehicle", {vehicle = args[1]:upper()}))
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t("error.vehicle_not_flag"), 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t("error.vehicle_not_flag"), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("plateinfo", Lang:t("commands.plateinfo"), {{name = "plate", help = Lang:t('info.plate_number')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        if Plates and Plates[args[1]:upper()] then
            if Plates[args[1]:upper()].isflagged then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('success.vehicle_flagged', {plate = args[1]:upper(), reason = Plates[args[1]:upper()].reason}), 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t("error.vehicle_not_flag"), 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t("error.vehicle_not_flag"), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("depot", Lang:t("commands.depot"), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:ImpoundVehicle", src, false)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("impound", Lang:t("commands.impound"), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:ImpoundVehicle", src, true)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("paytow", Lang:t("commands.paytow"), {{name = "id", help = Lang:t('info.player_id')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        local playerId = tonumber(args[1])
        local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
        if OtherPlayer then
            if OtherPlayer.PlayerData.job.name == "tow" then
                OtherPlayer.Functions.AddMoney("bank", 500, "police-tow-paid")
                TriggerClientEvent('QBCore:Notify', OtherPlayer.PlayerData.source, Lang:t("success.tow_paid"), 'success')
                TriggerClientEvent('QBCore:Notify', src, Lang:t("info.tow_driver_paid"))
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t("error.not_towdriver"), 'error')
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("paylawyer", Lang:t("commands.paylawyer"), {{name = "id",help = Lang:t('info.player_id')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" or Player.PlayerData.job.name == "judge" then
        local playerId = tonumber(args[1])
        local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
        if not OtherPlayer then return end
        if OtherPlayer.PlayerData.job.name == "lawyer" then
            OtherPlayer.Functions.AddMoney("bank", 500, "police-lawyer-paid")
            TriggerClientEvent('QBCore:Notify', OtherPlayer.PlayerData.source, Lang:t("success.tow_paid"), 'success')
            TriggerClientEvent('QBCore:Notify', src, Lang:t("info.paid_lawyer"))
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t("error.not_lawyer"), "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add('fine', Lang:t("commands.fine"), {{name = 'id', help = Lang:t('info.player_id')}, {name = 'amount', help = Lang:t('info.amount')}}, false, function(source, args)
    local biller = QBCore.Functions.GetPlayer(source)
    local billed = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local amount = tonumber(args[2])
    if biller.PlayerData.job.type == "leo" then
        if billed ~= nil then
            if biller.PlayerData.citizenid ~= billed.PlayerData.citizenid then
                if amount and amount > 0 then
                    if billed.Functions.RemoveMoney('bank', amount, "paid-fine") then
                        TriggerClientEvent('QBCore:Notify', source, Lang:t("info.fine_issued"), 'success')
                        TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, Lang:t("info.received_fine"))
                        exports['qb-management']:AddMoney(biller.PlayerData.job.name, amount)
                    elseif billed.Functions.RemoveMoney('cash', amount, "paid-fine") then
                        TriggerClientEvent('QBCore:Notify', source, Lang:t("info.fine_issued"), 'success')
                        TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, Lang:t("info.received_fine"))
                        exports['qb-management']:AddMoney(biller.PlayerData.job.name, amount)
                    else
                        MySQL.Async.insert('INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',{billed.PlayerData.citizenid, amount, biller.PlayerData.job.name, biller.PlayerData.charinfo.firstname, biller.PlayerData.citizenid}, function(id)
                            if id then
                                TriggerClientEvent('qb-phone:client:AcceptorDenyInvoice', billed.PlayerData.source, id, biller.PlayerData.charinfo.firstname, biller.PlayerData.job.name, biller.PlayerData.citizenid, amount, GetInvokingResource())
                            end
                        end)
                        TriggerClientEvent('qb-phone:RefreshPhone', billed.PlayerData.source)
                    end
                else
                    TriggerClientEvent('QBCore:Notify', source, Lang:t("error.amount_higher"), 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', source, Lang:t("error.fine_yourself"), 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, Lang:t("error.not_online"), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("anklet", Lang:t("commands.anklet"), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:CheckDistance", src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("ankletlocation", Lang:t("commands.ankletlocation"), {{name = "cid", help = Lang:t('info.citizen_id')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        local citizenid = args[1]
        local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        if not Target then return end
        if Target.PlayerData.metadata["tracker"] then
            TriggerClientEvent("police:client:SendTrackerLocation", Target.PlayerData.source, src)
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t("error.no_anklet"), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

QBCore.Commands.Add("takedrivinglicense", Lang:t("commands.drivinglicense"), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:SeizeDriverLicense", source)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

RegisterNetEvent('police:server:SendTrackerLocation', function(coords, requestId)
    local Target = QBCore.Functions.GetPlayer(source)
    local msg = Lang:t('info.target_location', {firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname})
    local alertData = {
        title = Lang:t('info.anklet_location'),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        description = msg
    }
    TriggerClientEvent("police:client:TrackerMessage", requestId, msg, coords)
    TriggerClientEvent("qb-phone:client:addPoliceAlert", requestId, alertData)
end)

QBCore.Commands.Add('911p', Lang:t("commands.police_report"), {{name='message', help= Lang:t("commands.message_sent")}}, false, function(source, args)
    local src = source
    local message
    if args[1] then message = table.concat(args, " ") else message = Lang:t("commands.civilian_call") end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
            local alertData = {title = Lang:t("commands.emergency_call"), coords = {x = coords.x, y = coords.y, z = coords.z}, description = message}
            TriggerClientEvent("qb-phone:client:addPoliceAlert", v.PlayerData.source, alertData)
            TriggerClientEvent('police:client:policeAlert', v.PlayerData.source, coords, message)
        end
    end
end)

-- Items
for _,v in pairs(Config.CuffItems) do
    QBCore.Functions.CreateUseableItem(v.itemname , function(source,item)
        TriggerClientEvent("police:client:CuffPlayer", source, item.name)
    end)
end

QBCore.Functions.CreateUseableItem(Config.CuffKeyItem , function(source,item)
    TriggerClientEvent("police:client:UnCuffPlayer", source, item.name, source)
end)

QBCore.Functions.CreateUseableItem(Config.AlcoholTesterName , function(source,item)
    TriggerClientEvent("qb-police:client:scanAlcohol", source)
end)

QBCore.Functions.CreateUseableItem(Config.CutTieItem , function(source,item)
    TriggerClientEvent("police:client:UnCuffPlayer", source, item.name, source)
end)

QBCore.Functions.CreateUseableItem(Config.CutCuffItem , function(source,item)
    TriggerClientEvent('police:client:useCuffCutter', source, item.name)
end)

QBCore.Functions.CreateUseableItem("moneybag", function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.Functions.GetItemByName("moneybag") or not item.info or item.info == "" or Player.PlayerData.job.type == "leo" or not Inventory.RemoveItem(src, "moneybag", 1, item.slot) then return end
    Player.Functions.AddMoney("cash", tonumber(item.info.cash), "used-moneybag")
end)

QBCore.Functions.CreateUseableItem('filled_evidence_bag', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player and Player.PlayerData.job.type == "leo" then
        TriggerClientEvent('evidence:client:writeEvidenceNot', src, item)
    end
end)

QBCore.Functions.CreateUseableItem('leo_gps', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player and Player.PlayerData.job.type == "leo" or Player.PlayerData.job.type == "ems" then
        TriggerClientEvent('police:client:UseGPS', src)
    end
end)

-- Callbacks
QBCore.Functions.CreateCallback('police:server:isPlayerDead', function(_, cb, playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    cb(Player.PlayerData.metadata["isdead"])
end)

QBCore.Functions.CreateCallback('police:server:isPlayerLast', function(_, cb, playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    cb(Player.PlayerData.metadata["inlaststand"])
end)

QBCore.Functions.CreateCallback('police:GetPlayerStatus', function(_, cb, playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    local statList = {}
    if Player then
        if PlayerStatus[Player.PlayerData.source] and next(PlayerStatus[Player.PlayerData.source]) then
            for k in pairs(PlayerStatus[Player.PlayerData.source]) do
                statList[#statList+1] = PlayerStatus[Player.PlayerData.source][k].text
            end
        end
    end
    cb(statList)
end)

QBCore.Functions.CreateCallback('police:IsSilencedWeapon', function(source, cb, weapon)
    local Player = QBCore.Functions.GetPlayer(source)
    local itemInfo = Player.Functions.GetItemByName(QBCore.Shared.Weapons[weapon]["name"])
    local retval = false
    if itemInfo then
        if itemInfo.info and itemInfo.info.attachments then
            for k in pairs(itemInfo.info.attachments) do
                if itemInfo.info.attachments[k].component == "COMPONENT_AT_AR_SUPP_02" or
                    itemInfo.info.attachments[k].component == "COMPONENT_AT_AR_SUPP" or
                    itemInfo.info.attachments[k].component == "COMPONENT_AT_PI_SUPP_02" or
                    itemInfo.info.attachments[k].component == "COMPONENT_AT_PI_SUPP" then
                    retval = true
                end
            end
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('police:GetDutyPlayers', function(_, cb)
    local dutyPlayers = {}
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" and v.PlayerData.job.onduty then
            dutyPlayers[#dutyPlayers+1] = {
                source = v.PlayerData.source,
                label = v.PlayerData.metadata["callsign"],
                job = v.PlayerData.job.name
            }
        end
    end
    cb(dutyPlayers)
end)

QBCore.Functions.CreateCallback('police:GetImpoundedVehicles', function(_, cb)
    local Player = QBCore.Functions.GetPlayer(_)
    local vehicles = {}
    MySQL.query('SELECT * FROM player_vehicles WHERE state = ? AND citizenid = ?', {2, Player.PlayerData.citizenid}, function(result)
        if result[1] then
            vehicles = result
        end
        cb(vehicles)
    end)
end)

QBCore.Functions.CreateCallback('police:IsPlateFlagged', function(_, cb, plate)
    local retval = false
    if Plates and Plates[plate] then
        if Plates[plate].isflagged then
            retval = true
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('police:GetCops', function(_, cb)
    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end
    cb(amount)
end)

QBCore.Functions.CreateCallback('police:server:IsPoliceForcePresent', function(_, cb)
    local retval = false
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" and v.PlayerData.job.grade.level >= 2 then
            retval = true
            break
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('police:server:getSecureKey', function(source, cb)
    cb(seckey)
end)

QBCore.Functions.CreateCallback('police:server:PayForVehicle', function(source, cb, price, vehicle)
    local Player = QBCore.Functions.GetPlayer(source)
	local cid = Player.PlayerData.citizenid
    local bank = Player.PlayerData.money['bank']
    local cash = Player.PlayerData.money['cash']
	local plate = GeneratePlate()
    local paid = false
    if price == 0 then cb(true) return end
    if bank >= price and price > 0 then
        Player.Functions.RemoveMoney("bank", price, "pd-vehicle")
        cb(true, plate)
		paid = true
    elseif cash >= price and price > 0 then
        Player.Functions.RemoveMoney("cash", price, "pd-vehicle")
        cb(true, plate)
		paid = true
    else
        cb(false)
		paid = false
    end
	if Config.OwnedPoliceCars and paid then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0
        })
        TriggerClientEvent('QBCore:Notify', source, Lang:t('success.purchased'), 'success')
    end
end)

QBCore.Functions.CreateCallback('police:server:getCuffStatus', function(_, cb, playerid)
    local Player = QBCore.Functions.GetPlayer(playerid)
    local citizenid = Player.PlayerData.citizenid
    if CuffedPlayers[citizenid] then
        cb(CuffedPlayers[citizenid])
        return
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('police:server:GetEvidenceByType', function(source, cb, type)
    local EvidenceBags = Inventory.GetItem(source, 'filled_evidence_bag')
    if not EvidenceBags then TriggerClientEvent('QBCore:Notify', source, Lang:t('error.dont_have_evidence_bag'), 'error') end
    local ItemList = {}
    if Config.Inventory == 'qb-inventory' or Config.Inventory == 'ps-inventory' then
        for k,v in pairs(EvidenceBags) do
            if v.info.type == type then
                if type == 'casing' then if v.info.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'vehiclefragment' then if v.info.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'bullet' then if v.info.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'blood' then if v.info.dnalabel == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'fingerprint' then if v.info.fingerprint == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'footprint' then if v.info.shoes == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                end
            end
        end
	elseif Config.Inventory == 'new-qb-inventory' then
		local EvidenceItems = exports['qb-inventory']:GetItemsByName(source, 'filled_evidence_bag')
        for k,v in pairs(EvidenceItems) do
            if v.info.type == type then
                if type == 'casing' then if v.info.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'vehiclefragment' then if v.info.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'bullet' then if v.info.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'blood' then if v.info.dnalabel == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'fingerprint' then if v.info.fingerprint == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'footprint' then if v.info.shoes == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                end
            end
        end
    elseif Config.Inventory == 'ox_inventory' then
        for k,v in pairs(EvidenceBags) do
            if v.metadata.type == type then
                if type == 'casing' then if v.metadata.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'vehiclefragment' then if v.metadata.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'bullet' then if v.metadata.serie == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'blood' then if v.metadata.dnalabel == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'fingerprint' then if v.metadata.fingerprint == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                elseif type == 'footprint' then if v.metadata.shoes == Lang:t('info.unknown') then ItemList[#ItemList+1] = v end
                end
            end
        end
    end
    cb(ItemList)
end)

QBCore.Functions.CreateCallback('police:server:HasImpoundPrice', function(source, cb, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveMoney('cash', amount, 'police-impound') then
        cb(true)
    end
    cb(false)
end)

QBCore.Functions.CreateCallback('police:server:GetRepairPedStatus', function(source, cb, loc)
    if RepairPed[loc] then cb(RepairPed[loc].busy) return end
    cb(false)
end)

QBCore.Functions.CreateCallback('police:server:SetWeaponRepair', function(source, cb, loc, weapdata)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.items[weapdata.slot] then
        if Player.PlayerData.items[weapdata.slot].info.quality ~= 100 then
            if Inventory.RemoveItem(src, weapdata.name, 1, weapdata.slot) then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weapdata.name], "remove")
                TriggerClientEvent("inventory:client:CheckWeapon", src, weapdata.name)
                RepairPed[loc].data = {
                    CitizenId = Player.PlayerData.citizenid,
                    WeaponData = weapdata,
                }
                cb(true)
            else
                cb(false)
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.weapon_not_damaged'), "error")
            cb(false)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_weapon_hand'), "error")
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('police:server:GetRepairPedData', function(source, cb)
    cb(RepairPed)
end)

-- Events
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for k, v in pairs(QBCore.Shared.Jobs) do
        if v.type == 'leo' then
            LEOjobs[k] = 0
        end
    end
    if Config.Inventory == 'ox_inventory' then
        for i = 1, #Config.Locations['trash'] do
            exports.ox_inventory:RegisterStash(('policetrash_%s'):format(i), 'Police Trash', 300, 4000000, nil, LEOjobs, Config.Locations['trash'][i])
        end
    end
    if Config.RepairStations.enabled then
        for k,v in pairs(Config.RepairStations.locations) do
            RepairPed[k] = {busy = false, data = {}}
            RepairPed[k].pedid = NetworkGetNetworkIdFromEntity(CreatePed(5, v.pedhash, vector3(v.pedloc.x,v.pedloc.y,v.pedloc.z-1), v.pedloc.w, true, true))
            RepairPed[k].key = k
            RepairPed[k].pedloc = v.pedloc
            RepairPed[k].walkto = v.walkto
			RepairPed[k].jobtype = v.jobtype
        end
    end
end)

AddEventHandler('onResourceStop', function()
    if Config.Inventory == 'ox_inventory' then
        for i = 1, #Config.Locations['trash'] do
            exports.ox_inventory:ClearInventory(('policetrash_%s'):format(i))
        end
    elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'ps-inventory' then
        CreateThread(function()
            MySQL.query("DELETE FROM stashitems WHERE stash = 'policetrash'")
        end)
	elseif Config.Inventory == 'new-qb-inventory' then
        CreateThread(function()
            MySQL.query("DELETE FROM inventories WHERE identifier = 'policetrash'")
        end)
    end
end)

RegisterNetEvent('police:server:openStash', function(id, name)
    Inventory.OpenStash(source, id, name)
end)

RegisterNetEvent('police:server:addTrunkItems', function(plate, items)
    Wait(1000)
    Inventory.TrunkItems(source, plate, items)
end)

RegisterNetEvent('police:server:openShop', function(name, items)
    if Config.Inventory == 'ox_inventory' then
        local si = {}
        for k,v in pairs(items.items) do
            si[#si+1] = {name = v.name, price = v.price}
        end
        Inventory.OpenShop(source, name, si, LEOjobs)
    else
        Inventory.OpenShop(source, name, items.items, LEOjobs)
    end
end)

RegisterNetEvent('police:server:SetRepairPedStatus', function(loc, status, hasweapon)
    local src = source
    local players = QBCore.Functions.GetQBPlayers()
    local Player = QBCore.Functions.GetPlayer(src)
    --[[for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" then
            TriggerClientEvent('police:client:SyncRepairLocation', v.PlayerData.source, loc, status, hasweapon, Player.PlayerData.citizenid)
        end
    end--]]
	TriggerClientEvent('police:client:SyncRepairLocation', -1, loc, status, hasweapon, Player.PlayerData.citizenid)
    RepairPed[loc].busy = status
end)

RegisterNetEvent('police:server:GiveWeaponBack', function(loc)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local players = QBCore.Functions.GetQBPlayers()
    if not Player then return end
    if RepairPed[loc].data.CitizenId ~= Player.PlayerData.citizenid then return end
    local itemdata = RepairPed[loc].data.WeaponData
    if Config.Inventory == 'ox_inventory' then
        itemdata.metadata.durability = 100
        Inventory.AddItem(src, itemdata.name, 1, itemdata.metadata)
    else
        itemdata.info.quality = 100
        Player.Functions.AddItem(itemdata.name, 1, false, itemdata.info)
    end
    RepairPed[loc].data = {}
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemdata.name], "add")
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" then
            TriggerClientEvent('police:client:SyncRepairLocation', v.PlayerData.source, loc, false, false, nil)
        end
    end
end)

RegisterNetEvent('police:server:policeAlert', function(text)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" and v.PlayerData.job.onduty then
            local alertData = {title = Lang:t('info.new_call'), coords = {x = coords.x, y = coords.y, z = coords.z}, description = text}
            TriggerClientEvent("qb-phone:client:addPoliceAlert", v.PlayerData.source, alertData)
            TriggerClientEvent('police:client:policeAlert', v.PlayerData.source, coords, text)
        end
    end
end)

RegisterNetEvent('police:server:TakeOutImpound', function(plate, garage)
    local src = source
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = Config.Locations["impound"][garage]
    if #(playerCoords - targetCoords) > 10.0 then return DropPlayer(src, "Attempted exploit abuse") end

    MySQL.update('UPDATE player_vehicles SET state = ? WHERE plate = ?', {0, plate})
    TriggerClientEvent('QBCore:Notify', src, Lang:t("success.impound_vehicle_removed"), 'success')
end)

RegisterNetEvent('police:server:CuffPlayer', function(position, id, item)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(id)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(src)
    local CuffedPlayer = QBCore.Functions.GetPlayer(id)
    if not Player or not CuffedPlayer or not Player.Functions.GetItemByName(item) then return end
    TriggerClientEvent('police:client:GetCuffed', CuffedPlayer.PlayerData.source, Player.PlayerData.source, position, item)
end)

RegisterNetEvent('qb-policejob:server:NotifyOtherPlayer', function(source, message, type, time)
    TriggerClientEvent('QBCore:Notify', source, message, type, time)
end)

RegisterNetEvent('police:server:CutCuffs', function(id, item)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(id)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(src)
    local CuffedPlayer = QBCore.Functions.GetPlayer(id)
    local citizenid = CuffedPlayer.PlayerData.citizenid
    local cuffed = CuffedPlayers[citizenid].cuffed
    if not Player or not CuffedPlayer or not Player.Functions.GetItemByName(item) or not cuffed then return end
    if Inventory.AddItem(src, Config.BrokenCuffItem, 1) then
        TriggerClientEvent('police:client:GetUnCuffed', CuffedPlayer.PlayerData.source, item)
    end
end)

RegisterNetEvent('police:server:TiePlayer', function(playerId, isSoftcuff)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(src)
    local TiedPlayer = QBCore.Functions.GetPlayer(playerId)
    if not Player or not TiedPlayer or (not Player.Functions.GetItemByName("ziptie")) then return end
    if Inventory.RemoveItem(src, 'ziptie', 1) then
        TriggerClientEvent("police:client:GetTied", TiedPlayer.PlayerData.source, Player.PlayerData.source, isSoftcuff)
    end
end)

RegisterNetEvent('police:server:isEscortingPlayer', function(bool, playerId)
    TriggerClientEvent('police:client:setEscortStatus', playerId, bool)
end)

RegisterNetEvent('police:server:EscortPlayer', function(playerId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(source)
    local EscortPlayer = QBCore.Functions.GetPlayer(playerId)
    if not Player or not EscortPlayer then return end

    if (Player.PlayerData.job.type == "leo" or Player.PlayerData.job.type == "ems") or (EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"] or EscortPlayer.PlayerData.metadata["inlaststand"]) then
        TriggerClientEvent('police:client:EscortAnimation', src)
        TriggerClientEvent("police:client:GetEscorted", EscortPlayer.PlayerData.source, Player.PlayerData.source)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.not_cuffed_dead"), 'error')
    end
end)

RegisterNetEvent('police:server:KidnapPlayer', function(playerId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(source)
    local EscortPlayer = QBCore.Functions.GetPlayer(playerId)
    if not Player or not EscortPlayer then return end

    if EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"] or EscortPlayer.PlayerData.metadata["inlaststand"] then
        TriggerClientEvent("police:client:GetKidnappedTarget", EscortPlayer.PlayerData.source, Player.PlayerData.source)
        TriggerClientEvent("police:client:GetKidnappedDragger", Player.PlayerData.source, EscortPlayer.PlayerData.source)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.not_cuffed_dead"), 'error')
    end
end)

RegisterNetEvent('police:server:SetPlayerOutVehicle', function(playerId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local EscortPlayer = QBCore.Functions.GetPlayer(playerId)
    if not QBCore.Functions.GetPlayer(src) or not EscortPlayer then return end

    if EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"] or EscortPlayer.PlayerData.metadata["inlaststand"] then
        TriggerClientEvent("police:client:SetOutVehicle", EscortPlayer.PlayerData.source)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.not_cuffed_dead"), 'error')
    end
end)

RegisterNetEvent('police:server:PutPlayerInVehicle', function(playerId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local EscortPlayer = QBCore.Functions.GetPlayer(playerId)
    if not QBCore.Functions.GetPlayer(src) or not EscortPlayer then return end

    if EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"] or EscortPlayer.PlayerData.metadata["inlaststand"] then
        TriggerClientEvent('police:client:setEscortStatus', src, false)
        TriggerClientEvent("police:client:PutInVehicle", EscortPlayer.PlayerData.source)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.not_cuffed_dead"), 'error')
    end
end)

RegisterNetEvent('police:server:BillPlayer', function(playerId, price)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(src)
    local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
    if not Player or not OtherPlayer or Player.PlayerData.job.name ~= "police" or Player.PlayerData.job.type ~= "leo" then return end

    OtherPlayer.Functions.RemoveMoney("bank", price, "paid-bills")
    exports['qb-management']:AddMoney("police", price)
    TriggerClientEvent('QBCore:Notify', OtherPlayer.PlayerData.source, Lang:t("info.fine_received", {fine = price}))
end)

RegisterNetEvent('police:server:JailPlayer', function(playerId, time)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(src)
    local OtherPlayer = QBCore.Functions.GetPlayer(playerId)

    if (not Player or not OtherPlayer) or not Player.PlayerData.job.type == "leo" then return end
    local currentDate = os.date("*t")
    if currentDate.day == 31 then
        currentDate.day = 30
    end

    OtherPlayer.Functions.SetMetaData("injail", time)
    OtherPlayer.Functions.SetMetaData("criminalrecord", {
        ["hasRecord"] = true,
        ["date"] = currentDate
    })
    TriggerClientEvent("police:client:SendToJail", OtherPlayer.PlayerData.source, time)
    TriggerClientEvent('QBCore:Notify', src, Lang:t("info.sent_jail_for", {time = time}))
    local name = OtherPlayer.PlayerData.charinfo.firstname.." "..OtherPlayer.PlayerData.charinfo.lastname
    exports['futte-newspaper']:CreateJailStory(name, time)
end)

RegisterNetEvent('police:server:SetHandcuffStatus', function(isHandcuffed, cuffitem, position)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    if Player then
        Player.Functions.SetMetaData("ishandcuffed", isHandcuffed)
        if isHandcuffed then
            CuffedPlayers[citizenid] = {cuffed = true, item = cuffitem, pos = position}
        else
            CuffedPlayers[citizenid] = nil
        end
    end
end)

RegisterNetEvent('heli:spotlight', function(state)
    local serverID = source
    TriggerClientEvent('heli:spotlight', -1, serverID, state)
end)

RegisterNetEvent('police:server:FlaggedPlateTriggered', function(camId, plate, street1, street2, blipSettings)
    local src = source
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player then
            if (Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty) then
                if street2 then
                    TriggerClientEvent("112:client:SendPoliceAlert", v, "flagged", {
                        camId = camId,
                        plate = plate,
                        streetLabel = street1 .. " " .. street2
                    }, blipSettings)
                else
                    TriggerClientEvent("112:client:SendPoliceAlert", v, "flagged", {
                        camId = camId,
                        plate = plate,
                        streetLabel = street1
                    }, blipSettings)
                end
            end
        end
    end
end)

RegisterNetEvent('police:server:SearchPlayer', function(playerId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    --if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local SearchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if not QBCore.Functions.GetPlayer(src) or not SearchedPlayer then return end

    TriggerClientEvent('QBCore:Notify', src, Lang:t("info.cash_found", {cash = SearchedPlayer.PlayerData.money["cash"]}))
    TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("info.being_searched"))
end)

RegisterNetEvent('police:server:SeizeCash', function(playerId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(src)
    local SearchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if not Player or not SearchedPlayer then return end

    local moneyAmount = SearchedPlayer.PlayerData.money["cash"]
    local info = { cash = moneyAmount }
    SearchedPlayer.Functions.RemoveMoney("cash", moneyAmount, "police-cash-seized")
    Player.Functions.AddItem("moneybag", 1, false, info)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["moneybag"], "add")
    TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("info.cash_confiscated"))
end)

RegisterNetEvent('police:server:SeizeDriverLicense', function(playerId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local SearchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if not QBCore.Functions.GetPlayer(src) or not SearchedPlayer then return end

    local driverLicense = SearchedPlayer.PlayerData.metadata["licences"]["driver"]
    if driverLicense then
        local licenses = {["driver"] = false, ["business"] = SearchedPlayer.PlayerData.metadata["licences"]["business"]}
        SearchedPlayer.Functions.SetMetaData("licences", licenses)
        TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("info.driving_license_confiscated"))
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.no_driver_license"), 'error')
    end
end)

RegisterNetEvent('police:server:RobPlayer', function(playerId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local Player = QBCore.Functions.GetPlayer(src)
    local SearchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if not Player or not SearchedPlayer then return end

    local money = SearchedPlayer.PlayerData.money["cash"]
    --Player.Functions.AddMoney("cash", money, "police-player-robbed")
    --SearchedPlayer.Functions.RemoveMoney("cash", money, "police-player-robbed")
    --TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("info.cash_robbed", {money = money}))
    --TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, Lang:t("info.stolen_money", {stolen = money}))
end)

RegisterNetEvent('police:server:UpdateBlips', function()
    -- KEEP FOR REF BUT NOT NEEDED ANYMORE.
end)

RegisterNetEvent('police:server:spawnObject', function(type)
    local src = source
    local objectId = CreateObjectId()
    Objects[objectId] = type
    TriggerClientEvent("police:client:spawnObject", src, objectId, type, src)
end)

RegisterNetEvent('police:server:deleteObject', function(objectId)
    TriggerClientEvent('police:client:removeObject', -1, objectId)
end)

RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local src = source
    price = price and price or 0
    if IsVehicleOwned(plate) then
        if not fullImpound then
            MySQL.query(
                'UPDATE player_vehicles SET state = ?, depotprice = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?',
                {0, price, body, engine, fuel, plate})
            TriggerClientEvent('QBCore:Notify', src, Lang:t("info.vehicle_taken_depot", {price = price}))
        else
            MySQL.query(
                'UPDATE player_vehicles SET state = ?, depotprice = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?',
                {2, price, body, engine, fuel, plate})
            TriggerClientEvent('QBCore:Notify', src, Lang:t("info.vehicle_seized", {price = price}))
        end
    end
end)

RegisterNetEvent('evidence:server:UpdateStatus', function(data)
    local src = source
    PlayerStatus[src] = data
end)

RegisterNetEvent('police:server:UpdateCurrentCops', function()
    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()
    if updatingCops then return end
    updatingCops = true
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end
    TriggerClientEvent("police:SetCopCount", -1, amount)
    TriggerEvent('police:SetCopCount', amount) -- added for car boosting script
    updatingCops = false
end)

RegisterNetEvent('police:server:showFingerprint', function(playerId)
    local src = source
    TriggerClientEvent('police:client:showFingerprint', playerId, src, playerId)
    TriggerClientEvent('police:client:showFingerprint', src, playerId, playerId)
end)

RegisterNetEvent('police:server:UpdateAlcohol', function(promille, type)
    local src = source
    if not promille or not src then return end
    local currentpromille = 0
    if AlcoholStats[src] then currentpromille = AlcoholStats[src].promille end
    local newpromille
    if type == 'add' then
        newpromille = currentpromille + promille
    elseif type == 'remove' then
        newpromille = currentpromille - promille
    end
    if newpromille < 0 then newpromille = 0 end
    AlcoholStats[src] = {promille = newpromille}
end)

RegisterNetEvent('police:server:showAlcoholTester', function(playerId)
    local src = source
    -- TriggerClientEvent('police:client:showAlcoholTester', playerId, src, true)
    TriggerClientEvent('police:client:showAlcoholTester', src, playerId, false)
end)

RegisterNetEvent('police:server:startAlcoholTest', function(userId)
    local src = source
    TriggerClientEvent('police:client:showAlcoholTester', userId, src, true)
end)

RegisterNetEvent('police:server:analyzeBlow', function(polId)
    local src = source
    local promille
    if AlcoholStats[src] then
        promille = AlcoholStats[src].promille
    else
        promille = 0
    end
    TriggerClientEvent('police:client:sendAlcoholData', src, promille)
    TriggerClientEvent('police:client:sendAlcoholData', polId, promille)
end)
RegisterNetEvent('police:server:showFingerprintId', function(sessionId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local fid = Player.PlayerData.metadata["fingerprint"]
    local cid = Player.PlayerData.citizenid
    local name = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname
    TriggerClientEvent('police:client:showFingerprintId', sessionId, fid, name, cid, src)
    TriggerClientEvent('police:client:showFingerprintId', src, fid, name, cid, src)
end)

RegisterNetEvent('police:server:SetTracker', function(targetId)
    local src = source
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 10 then return DropPlayer(src, "Attempted exploit abuse") end

    local Target = QBCore.Functions.GetPlayer(targetId)
    if not QBCore.Functions.GetPlayer(src) or not Target then return end

    local TrackerMeta = Target.PlayerData.metadata["tracker"]
    if TrackerMeta then
        Target.Functions.SetMetaData("tracker", false)
        TriggerClientEvent('QBCore:Notify', targetId, Lang:t("success.anklet_taken_off"), 'success')
        TriggerClientEvent('QBCore:Notify', src, Lang:t("success.took_anklet_from", {firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname}), 'success')
        TriggerClientEvent('police:client:SetTracker', targetId, false)
    else
        Target.Functions.SetMetaData("tracker", true)
        TriggerClientEvent('QBCore:Notify', targetId, Lang:t("success.put_anklet"), 'success')
        TriggerClientEvent('QBCore:Notify', src, Lang:t("success.put_anklet_on", {firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname}), 'success')
        TriggerClientEvent('police:client:SetTracker', targetId, true)
    end
end)

RegisterNetEvent('police:server:SyncSpikes', function(table)
    TriggerClientEvent('police:client:SyncSpikes', -1, table)
    TriggerClientEvent('police:client:SpikePolyZone', -1, table)
end)

RegisterNetEvent('police:server:removeSpike', function(name)
    TriggerClientEvent('police:client:removeSpike', -1, name)
end)

RegisterNetEvent('police:server:changeDuty', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    local Job = Player.PlayerData.job

    if Job and Job.onduty and not data.duty then
        Player.Functions.SetJobDuty(false)
        QBCore.Functions.Notify(source, Lang:t("success.beingoffduty"), 'primary')
    elseif Job and not Job.onduty and data.duty then
        Player.Functions.SetJobDuty(true)
        QBCore.Functions.Notify(source, Lang:t("success.beingonduty"), 'primary')
    end
end)

RegisterNetEvent('police:server:setEvidenceBagNote', function(item, note)
    local Player = QBCore.Functions.GetPlayer(source)
    if Config.Inventory == 'qb-inventory' or Config.Inventory == 'ps-inventory' then
        item.info.evidenceNote = note
        item.info.noteWrite = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname
        if Inventory.RemoveItem(source, 'filled_evidence_bag', 1, item.slot) then
            Inventory.AddItem(source,'filled_evidence_bag', 1, item.info, item.slot)
        end
    elseif Config.Inventory == 'ox_inventory' then
        item.metadata.evidenceNote = note
        item.metadata.noteWrite = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname
        if Inventory.RemoveItem(source, 'filled_evidence_bag', 1, item.slot) then
            Inventory.AddItem(source,'filled_evidence_bag', 1, item.metadata, item.slot)
        end
    end
end)

RegisterNetEvent('police:server:AddRemove', function(itemname, amount, action, src, hash)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if hash ~= seckey then DropPlayer(src, "Attempted exploit abuse") end
    if action == "add" then
        Inventory.AddItem(src, itemname, amount)
        TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[itemname], "add")
    elseif action == "remove" then
        Inventory.RemoveItem(src, itemname, amount)
        TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[itemname], "remove")
    end
end)

RegisterNetEvent('police:server:UpdateEvidenceBag', function(Item, Slot)
    if Item then
        if Config.Inventory == 'qb-inventory' or Config.Inventory == 'ps-inventory' then
            if Item.info.type == 'casing' then
                Item.info.serie = Item.info.serie2
                Item.info.ammotype = Item.info.ammotype2
            elseif Item.info.type == 'bullet' then
                Item.info.serie = Item.info.serie2
                Item.info.ammotype = Item.info.ammotype2
            elseif Item.info.type == 'vehiclefragment' then
                Item.info.serie = Item.info.serie2
                Item.info.ammotype = Item.info.ammotype2
                Item.info.rgb = Item.info.rgb2
            elseif Item.info.type == 'blood' then
                Item.info.dnalabel = Item.info.dnalabel2
                Item.info.bloodtype = Item.info.bloodtype2
            elseif Item.info.type == 'fingerprint' then
                Item.info.fingerprint = Item.info.fingerprint2
            elseif Item.info.type == 'footprint' then
                Item.info.shoes = Item.info.shoes2
            end
            if Inventory.RemoveItem(source, 'filled_evidence_bag', 1, Slot) then
                Inventory.AddItem(source, 'filled_evidence_bag', 1, Item.info, Slot)
            end
		elseif Config.Inventory == 'new-qb-inventory' then
            if Item.info.type == 'casing' then
                Item.info.serie = Item.info.serie2
                Item.info.ammotype = Item.info.ammotype2
            elseif Item.info.type == 'bullet' then
                Item.info.serie = Item.info.serie2
                Item.info.ammotype = Item.info.ammotype2
            elseif Item.info.type == 'vehiclefragment' then
                Item.info.serie = Item.info.serie2
                Item.info.ammotype = Item.info.ammotype2
                Item.info.rgb = Item.info.rgb2
            elseif Item.info.type == 'blood' then
                Item.info.dnalabel = Item.info.dnalabel2
                Item.info.bloodtype = Item.info.bloodtype2
            elseif Item.info.type == 'fingerprint' then
                Item.info.fingerprint = Item.info.fingerprint2
            elseif Item.info.type == 'footprint' then
                Item.info.shoes = Item.info.shoes2
            end
            if Inventory.RemoveItem(source, 'filled_evidence_bag', 1, Slot) then
                Inventory.AddItem(source, 'filled_evidence_bag', 1, Item.info, Slot)
            end
        elseif Config.Inventory == 'ox_inventory' then
            if Item.metadata.type == 'casing' then
                Item.metadata.serie = Item.metadata.serie2
                Item.metadata.ammotype = Item.metadata.ammotype2
            elseif Item.metadata.type == 'bullet' then
                Item.metadata.serie = Item.metadata.serie2
                Item.metadata.ammotype = Item.metadata.ammotype2
            elseif Item.metadata.type == 'vehiclefragment' then
                Item.metadata.serie = Item.metadata.serie2
                Item.metadata.ammotype = Item.metadata.ammotype2
                Item.metadata.rgb = Item.metadata.rgb2
            elseif Item.metadata.type == 'blood' then
                Item.metadata.dnalabel = Item.metadata.dnalabel2
                Item.metadata.bloodtype = Item.metadata.bloodtype2
            elseif Item.metadata.type == 'fingerprint' then
                Item.metadata.fingerprint = Item.metadata.fingerprint2
            elseif Item.metadata.type == 'footprint' then
                Item.metadata.shoes = Item.metadata.shoes2
            end
            if Inventory.RemoveItem(source, 'filled_evidence_bag', 1, Slot) then
                Inventory.AddItem(source, 'filled_evidence_bag', 1, Item.metadata, Slot)
            end
        end
    end
end)

RegisterNetEvent('police:server:UpdateBlipInfo',function(data)
    local player = source
    if (not GPSTable[player] or (GPSTable[player].vehClass ~= data.vehClass or GPSTable[player].job ~= data.playerJob or GPSTable[player].gpsactive ~= data.gpsactive)) and player then GPSTable[player] = {vehClass = data.vehClass, job = data.playerJob, call = data.call, source = player, gpsactive = data.gpsactive} end
end)

RegisterNetEvent('police:server:SetCallSign', function(callsign)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.SetMetaData("callsign", callsign)
end)

RegisterServerEvent('baseevents:enteredVehicle', function(veh, seat, modelName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local data = {
        vehicle = veh,
        seat = seat,
        name = modelName,
        event = 'Entered'
    }
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent('police:client:VehicleInfo', src, data)
    end
end)

RegisterServerEvent('baseevents:leftVehicle', function(veh, seat, modelName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local data = {
        event = 'Left'
    }
    if Player.PlayerData.job.type == "leo" and Player.PlayerData.job.onduty then
        TriggerClientEvent('police:client:VehicleInfo', src, data)
    end
end)

RegisterNetEvent('qb-policejob:server:OpenOtherInventory', function(invName)
    if not invName then return end
    local src = source
    exports['qb-inventory']:OpenInventory(src, invName)
end)

RegisterNetEvent('qb-policejob:server:OpenOtherPlayerInventory', function(target)
    if not target then return end
    local src = source
    exports['qb-inventory']:OpenInventoryById(src, target)
end)
-- Threads
CreateThread(function()
    while true do
        Wait(1000 * 60 * 10)
        local curCops = GetCurrentCops()
        TriggerClientEvent("police:SetCopCount", -1, curCops)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        UpdateBlips()
    end
end)

CreateThread(function()
    while true do
        Wait( 60000 * Config.AlcoholReleaseInterval.min)
        for k,v in pairs(AlcoholStats) do
            if v.promille > 0 then
                local temppromille = v.promille - Config.AlcoholReleaseInterval.promille
                if temppromille < 0 then
                    AlcoholStats[k] = nil
                else
                    AlcoholStats[k] = {promille = temppromille}
                end
            end
        end
    end
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    if src and GPSTable[src] then GPSTable[src] = nil end
end)


