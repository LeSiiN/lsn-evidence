------------------------------------------------------------------------------[ VARIABLES ]------------------------------------------------------------------------------
PlayerJob = {}

local QBCore = exports['qb-core']:GetCoreObject()

local Casings = {}
local CurrentCasing = nil

local Blooddrops = {}
local CurrentBlooddrop = nil

local Fingerprints = {}
local CurrentFingerprint = 0

local Bullethole = {}
local CurrentBullethole = nil

local Fragements = {}
local CurrentVehicleFragement = nil

local currentTime = 0
local r, g, b = 0, 0, 0

local drawLine_r, drawLine_g, drawLine_b = 0, 0, 0

local WhitelistedWeapons = {
    `weapon_unarmed`,
    `weapon_snowball`,
    `weapon_stungun`,
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`
}

------------------------------------------------------------------------------[ FUNCTIONS ]------------------------------------------------------------------------------
local function DrawText3D(x, y, z, text)
    SetTextScale(0.30, 0.30)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 68)
    ClearDrawOrigin()
end

local function WhitelistedWeapon(weapon)
    for i = 1, #WhitelistedWeapons do
        if WhitelistedWeapons[i] == weapon then
            return true
        end
    end
    return false
end

local function DropBulletCasing(weapon, ped, currentTime)
    if IsPedSwimming(ped) then return end
    local randX = math.random() + math.random(-1, 1)
    local randY = math.random() + math.random(-1, 1)
    local coords = GetOffsetFromEntityInWorldCoords(ped, randX, randY, 0)
    TriggerServerEvent('evidence:server:CreateCasing', weapon, coords, currentTime)
    Wait(350)
end

local function SendBulletHole(weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
    if raycastcoords ~= nil then
        if GetEntityType(entityHit) == 2 then
            TriggerServerEvent('evidence:server:CreateVehicleFragement', weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
        else
            TriggerServerEvent('evidence:server:CreateBullethole', weapon, raycastcoords, pedcoords, heading, currentTime)
        end
        Wait(350)
    end
end

local function DnaHash(s)
    local h = string.gsub(s, '.', function(c)
        return string.format('%02x', string.byte(c))
    end)
    return h
end

local function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayCamera(distance)
    local playerPed = PlayerPedId()
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local result, hit, endCoords, _, entityHit = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return hit == 1, endCoords, entityHit
end

------------------------------------------------------------------------------[ EVENTS ]------------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local player = QBCore.Functions.GetPlayerData()
        PlayerJob = player.job
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local player = QBCore.Functions.GetPlayerData()
    PlayerJob = player.job
    if GetResourceState('ox_inventory'):match("start") then
        exports.ox_inventory:displayMetadata({
            label = 'Label',
            type = 'Type',
            street = 'Street',
            ammolabel = 'Ammo Label',
            ammotype = 'Ammo Type',
            serie = 'Serial',
            dnalabel = 'DNA',
            bloodtype = 'Blood Type',
            fingerprint = 'Fingerprint',
            rgb = '',
        })
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerJob = {}
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(newDuty)
    PlayerJob.onduty = newDuty
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('evidence:client:PlayerPickUpAnimation', function()
    local playerPed = PlayerPedId()
    RequestAnimDict("pickup_object")
    while not HasAnimDictLoaded("pickup_object") do
        Wait(0)
    end
    TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(playerPed)
end)

-----------------------------------------[ BLOOD ]-----------------------------------------
RegisterNetEvent('evidence:client:AddBlooddrop', function(bloodId, citizenid, bloodtype, coords)
    local ped = PlayerPedId()
    if IsPedSwimming(ped) then return end
    Blooddrops[bloodId] = {
        citizenid = citizenid,
        bloodtype = bloodtype,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        },
        time = GetGameTimer()
    }
end)

RegisterNetEvent('evidence:client:RemoveBlooddrop', function(bloodId)
    Blooddrops[bloodId] = nil
    CurrentBlooddrop = 0
end)

RegisterNetEvent('evidence:client:ClearBlooddropsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local blooddropList = {}
    QBCore.Functions.Progressbar('clear_blooddrops', Lang:t('progressbar.blood_clear'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Blooddrops and next(Blooddrops) then
            for bloodId, _ in pairs(Blooddrops) do
                if #(pos -
                        vector3(Blooddrops[bloodId].coords.x, Blooddrops[bloodId].coords.y, Blooddrops[bloodId].coords.z)) <
                    10.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.blood_clear'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.blood_clear'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.blood_not_cleared'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.blood_not_cleared'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ FINGERPRINT ]-----------------------------------------
RegisterNetEvent('evidence:client:AddFingerPrint', function(fingerId, fingerprint, coords)
    local ped = PlayerPedId()
    if IsPedSwimming(ped) then return end
    Fingerprints[fingerId] = {
        fingerprint = fingerprint,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        },
        time = GetGameTimer(),
    }
end)

RegisterNetEvent('evidence:client:RemoveFingerprint', function(fingerId)
    Fingerprints[fingerId] = nil
    CurrentFingerprint = 0
end)

-----------------------------------------[ CASSINGS ]-----------------------------------------
RegisterNetEvent('evidence:client:AddCasing', function(casingId, weapon, coords, serie, currentTime)
    Casings[casingId] = {
        type = weapon,
        serie = serie and serie or Lang:t('evidence.serial_not_visible'),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        },
        time = currentTime
    }
end)

RegisterNetEvent('evidence:client:RemoveCasing', function(casingId)
    Casings[casingId] = nil
    CurrentCasing = 0
end)

RegisterNetEvent('evidence:client:ClearCasingsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local casingList = {}
    QBCore.Functions.Progressbar('clear_casings', Lang:t('progressbar.bullet_casing'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Casings and next(Casings) then
            for casingId, _ in pairs(Casings) do
                if #(pos - vector3(Casings[casingId].coords.x, Casings[casingId].coords.y, Casings[casingId].coords.z)) <
                    10.0 then
                    casingList[#casingList + 1] = casingId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.bullet_casing_removed'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.bullet_casing_removed'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearCasings', casingList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.bullet_casing_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.bullet_casing_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ BULLETHOLE ]-----------------------------------------
RegisterNetEvent('evidence:client:AddBullethole', function(bulletholeId, weapon, raycastcoords, pedcoords, heading, currentTime, serie)
    if Config.PoliceCreatesEvidence and PlayerJob.type == 'leo' then
        drawLine_r = 0
        drawLine_g = 255
        drawLine_b = 0
    else
        drawLine_r = 255
        drawLine_g = 0
        drawLine_b = 0
    end
    Bullethole[bulletholeId] = {
        drawLine_r = drawLine_r,
        drawLine_g = drawLine_g,
        drawLine_b = drawLine_b,
        type = weapon,
        serie = serie and serie or Lang:t('evidence.serial_not_visible'),
        coords = {
            x = raycastcoords.x,
            y = raycastcoords.y,
            z = raycastcoords.z
        },
        pedcoord = {
            x = pedcoords.x,
            y = pedcoords.y,
            z = pedcoords.z,
            h = heading
        },
        time = currentTime
    }
end)

RegisterNetEvent('evidence:client:RemoveBullethole', function(bulletholeId)
    Bullethole[bulletholeId] = nil
    CurrentBullethole = 0
end)

RegisterNetEvent('evidence:client:ClearBulletholeInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local bulletholeList = {}
    QBCore.Functions.Progressbar('clear_bullethole', Lang:t('progressbar.bullet_hole'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Bullethole and next(Bullethole) then
            for bulletholeId, _ in pairs(Bullethole) do
                if #(pos - vector3(Bullethole[bulletholeId].coords.x, Bullethole[bulletholeId].coords.y, Bullethole[bulletholeId].coords.z)) <
                    10.0 then
                        bulletholeList[#bulletholeList + 1] = bulletholeId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.bullet_hole_removed'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.bullet_hole_removed'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearBullethole', bulletholeList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.bullet_hole_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.bullet_hole_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ VEHICLE FRAGEMENTS ]-----------------------------------------
RegisterNetEvent('evidence:client:AddVehicleFragement', function(vehiclefragementId, weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b, serie)
    if Config.PoliceCreatesEvidence and PlayerJob.type == 'leo' then
        drawLine_r = 0
        drawLine_g = 255
        drawLine_b = 0
    else
        drawLine_r = 255
        drawLine_g = 0
        drawLine_b = 0
    end
    Fragements[vehiclefragementId] = {
        coords = {
            x = raycastcoords.x,
            y = raycastcoords.y,
            z = raycastcoords.z
        },
        pedcoord = {
            x = pedcoords.x,
            y = pedcoords.y,
            z = pedcoords.z,
            h = heading
        },
        r = r,
        g = g,
        b = b,
        type = weapon,
        serie = serie and serie or Lang:t('evidence.serial_not_visible'),
        drawLine_r = drawLine_r,
        drawLine_g = drawLine_g,
        drawLine_b = drawLine_b,
        time = currentTime
    }
end)

RegisterNetEvent('evidence:client:RemoveVehicleFragement', function(vehiclefragementId)
    Fragements[vehiclefragementId] = nil
    CurrentVehicleFragement = 0
end)

RegisterNetEvent('evidence:client:ClearVehicleFragementsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local vehiclefragmentList = {}
    QBCore.Functions.Progressbar('clear_fragements', Lang:t('progressbar.vehicle_fragements'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Fragements and next(Fragements) then
            for vehiclefragementId, _ in pairs(Fragements) do
                if #(pos - vector3(Fragements[vehiclefragementId].coords.x, Fragements[vehiclefragementId].coords.y, Fragements[vehiclefragementId].coords.z)) <
                    10.0 then
                        vehiclefragmentList[#vehiclefragmentList + 1] = vehiclefragementId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.vehicle_fragement_removed'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.vehicle_fragement_removed'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearVehicleFragements', vehiclefragmentList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.vehicle_fragements_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.vehicle_fragements_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ EVENTS FOR COMMANDS/ITEMS ]-----------------------------------------
RegisterNetEvent('evidence:client:ClearScene', function()
    local pos = GetEntityCoords(PlayerPedId())
    local bulletholeList = {}
    local casingList = {}
    local blooddropList = {}
    local fingerprintList = {}
    local vehiclefragmentList = {}
    QBCore.Functions.Progressbar('clear_scene', Lang:t('progressbar.crime_scene'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Bullethole and next(Bullethole) then
            for bulletholeId, _ in pairs(Bullethole) do
                if #(pos - vector3(Bullethole[bulletholeId].coords.x, Bullethole[bulletholeId].coords.y, Bullethole[bulletholeId].coords.z)) <
                    30.0 then
                        bulletholeList[#bulletholeList + 1] = bulletholeId
                end
            end
            TriggerServerEvent('evidence:server:ClearBullethole', bulletholeList)
        end
        if Casings and next(Casings) then
            for casingId, _ in pairs(Casings) do
                if #(pos - vector3(Casings[casingId].coords.x, Casings[casingId].coords.y, Casings[casingId].coords.z)) <
                    30.0 then
                    casingList[#casingList + 1] = casingId
                end
            end
            TriggerServerEvent('evidence:server:ClearCasings', casingList)
        end
        if Blooddrops and next(Blooddrops) then
            for bloodId, _ in pairs(Blooddrops) do
                if #(pos -
                        vector3(Blooddrops[bloodId].coords.x, Blooddrops[bloodId].coords.y, Blooddrops[bloodId].coords.z)) <
                        30.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
        end
        if Fingerprints and next(Fingerprints) then
            for fingerId, _ in pairs(Fingerprints) do
                if #(pos -
                        vector3(Fingerprints[fingerId].coords.x, Fingerprints[fingerId].coords.y, Fingerprints[fingerId].coords.z)) <
                        30.0 then
                            fingerprintList[#fingerprintList + 1] = fingerId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', fingerprintList)
        end
        if Fragements and next(Fragements) then
            for vehiclefragementId, _ in pairs(Fragements) do
                if #(pos -
                        vector3(Fragements[vehiclefragementId].coords.x, Fragements[vehiclefragementId].coords.y, Fragements[vehiclefragementId].coords.z)) <
                        30.0 then
                            vehiclefragmentList[#vehiclefragmentList + 1] = vehiclefragementId
                end
            end
            TriggerServerEvent('evidence:server:ClearVehicleFragements', vehiclefragmentList)
        end
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('success.crime_scene_removed'), 'success')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('success.crime_scene_removed'), duration = 5000, type = 'success' })
        else
            print(Lang:t('error.config_error'))
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.scene_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.scene_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

RegisterNetEvent('evidence:client:ClearSceneCrime', function()
    local pos = GetEntityCoords(PlayerPedId())
    local bulletholeList = {}
    local casingList = {}
    local blooddropList = {}
    local fingerprintList = {}
    local vehiclefragmentList = {}
    QBCore.Functions.Progressbar('clear_scene', Lang:t('progressbar.crime_scene'), 3000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Bullethole and next(Bullethole) then
            for bulletholeId, _ in pairs(Bullethole) do
                if #(pos - vector3(Bullethole[bulletholeId].coords.x, Bullethole[bulletholeId].coords.y, Bullethole[bulletholeId].coords.z)) <
                    30.0 then
                        bulletholeList[#bulletholeList + 1] = bulletholeId
                end
            end
            TriggerServerEvent('evidence:server:ClearBullethole', bulletholeList)
        end
        if Casings and next(Casings) then
            for casingId, _ in pairs(Casings) do
                if #(pos - vector3(Casings[casingId].coords.x, Casings[casingId].coords.y, Casings[casingId].coords.z)) <
                    30.0 then
                    casingList[#casingList + 1] = casingId
                end
            end
            TriggerServerEvent('evidence:server:ClearCasings', casingList)
        end
        if Blooddrops and next(Blooddrops) then
            for bloodId, _ in pairs(Blooddrops) do
                if #(pos -
                        vector3(Blooddrops[bloodId].coords.x, Blooddrops[bloodId].coords.y, Blooddrops[bloodId].coords.z)) <
                        30.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
        end
        if Fingerprints and next(Fingerprints) then
            for fingerId, _ in pairs(Fingerprints) do
                if #(pos -
                        vector3(Fingerprints[fingerId].coords.x, Fingerprints[fingerId].coords.y, Fingerprints[fingerId].coords.z)) <
                        30.0 then
                            fingerprintList[#fingerprintList + 1] = fingerId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', fingerprintList)
        end
        if Fragements and next(Fragements) then
            for vehiclefragementId, _ in pairs(Fragements) do
                if #(pos -
                        vector3(Fragements[vehiclefragementId].coords.x, Fragements[vehiclefragementId].coords.y, Fragements[vehiclefragementId].coords.z)) <
                        30.0 then
                            vehiclefragmentList[#vehiclefragmentList + 1] = vehiclefragementId
                end
            end
            TriggerServerEvent('evidence:server:ClearVehicleFragements', vehiclefragmentList)
        end
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('success.crime_scene_removed'), 'success')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('success.crime_scene_removed'), duration = 5000, type = 'success' })
        else
            print(Lang:t('error.config_error'))
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.scene_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.scene_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

------------------------------------------------------------------------------[ THREADS ]------------------------------------------------------------------------------

-----------------------------------------[ DROP EVIDENCE ]-----------------------------------------
CreateThread(function()
    while true do
        Wait(3)
        if PlayerJob.type == 'leo' and not Config.PoliceCreatesEvidence then return end
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local pedcoords = GetEntityCoords(PlayerPedId())
            local heading = GetEntityHeading(PlayerPedId())

            local hit, raycastcoords, entityHit = RayCastGamePlayCamera(1000.0)
            local weapon = GetSelectedPedWeapon(ped)
            if not WhitelistedWeapon(weapon) then
                currentTime = GetGameTimer()
                r, g, b = GetVehicleColor(entityHit)

                SendBulletHole(weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
                DropBulletCasing(weapon, ped, currentTime)
            end
        end
    end
end)

-----------------------------------------[ REMOVE EVIDENCE AFTER 30 MINS ]-----------------------------------------
CreateThread(function()
    while true do
        Wait(60000)
        local bulletholeList = {}
        local casingList = {}
        local blooddropList = {}
        local fingerprintList = {}
        local vehiclefragmentList = {}
        local RemoveEvidence = Config.RemoveEvidence * 60 * 1000
        -----------------------------[ CASINGS ]-----------------------------
        if Casings and next(Casings) then
            for k, v in pairs(Casings) do
                CurrentCasing = k
                local timer = GetGameTimer()
                local currentTimer = Casings[CurrentCasing].time + RemoveEvidence
                if timer > Casings[CurrentCasing].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    casingList[#casingList + 1] = CurrentCasing
                    TriggerServerEvent('evidence:server:ClearCasings', casingList)
                end
            end
        end
        -----------------------------[ BLOOD ]-----------------------------
        if Blooddrops and next(Blooddrops) then
            for k, v in pairs(Blooddrops) do
                CurrentBlooddrop = k
                local timer = GetGameTimer()
                local currentTimer = Blooddrops[CurrentBlooddrop].time + RemoveEvidence
                if timer > Blooddrops[CurrentBlooddrop].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    blooddropList[#blooddropList + 1] = CurrentBlooddrop
                    TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
                end
            end
        end
        -----------------------------[ FINGERPRINTS ]-----------------------------
        if Fingerprints and next(Fingerprints) then
            for k, v in pairs(Fingerprints) do
                CurrentFingerprint = k
                local timer = GetGameTimer()
                local currentTimer = Fingerprints[CurrentFingerprint].time + RemoveEvidence
                if timer > Fingerprints[CurrentFingerprint].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    fingerprintList[#fingerprintList + 1] = CurrentFingerprint
                    TriggerServerEvent('evidence:server:ClearFingerprints', fingerprintList)
                end
            end
        end
        -----------------------------[ BULLETHOLE ]-----------------------------
        if Bullethole and next(Bullethole) then
            for k, v in pairs(Bullethole) do
                CurrentBullethole = k
                local timer = GetGameTimer()
                local currentTimer = Bullethole[CurrentBullethole].time + RemoveEvidence
                if timer > Bullethole[CurrentBullethole].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    bulletholeList[#bulletholeList + 1] = CurrentBullethole
                    TriggerServerEvent('evidence:server:ClearBullethole', bulletholeList)
                end
            end
        end
        -----------------------------[ VEHICLE FRAGEMENTS ]-----------------------------
        if Fragements and next(Fragements) then
            for k, v in pairs(Fragements) do
                CurrentVehicleFragement = k
                local timer = GetGameTimer()
                local currentTimer = Fragements[CurrentVehicleFragement].time + RemoveEvidence
                if timer > Fragements[CurrentVehicleFragement].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    vehiclefragmentList[#vehiclefragmentList + 1] = CurrentVehicleFragement
                    TriggerServerEvent('evidence:server:ClearVehicleFragements', vehiclefragmentList)
                end
            end
        end
    end
end)

-----------------------------------------[ CHECK WITH FLASHLIGHT OR CAMERA ]-----------------------------------------
CreateThread(function()
    while true do
        Wait(5)
        if LocalPlayer.state.isLoggedIn then
            if PlayerJob.type == 'leo' and PlayerJob.onduty then
                if (IsPlayerFreeAiming(PlayerId()) and GetSelectedPedWeapon(PlayerPedId()) == `WEAPON_FLASHLIGHT`) or IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_tourist_map@male@base", "base", 3) then
                    local pos = GetEntityCoords(PlayerPedId(), true)
                    local hit, coords = RayCastGamePlayCamera(1000.0)
                    if next(Casings) then
                        for k, v in pairs(Casings) do
                            local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                            local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                            if dist < 20 then
                                CurrentCasing = k
                                DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.CasingMarkerRGBA.r, Config.CasingMarkerRGBA.g, Config.CasingMarkerRGBA.b, Config.CasingMarkerRGBA.a, false, false, false, true, false, false, false)
                                if dist > 2.5 and dist < 10 then
                                    DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, " ~b~Bullet Casing [ " ..Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']].. " ]~s~")
                                elseif raycastdist < 0.25 and dist < 5 then
                                    DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                    if IsControlJustReleased(0, 23) then
                                        local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                        local street1 = GetStreetNameFromHashKey(s1)
                                        local street2 = GetStreetNameFromHashKey(s2)
                                        local streetLabel = street1
                                        if street2 then
                                            streetLabel = streetLabel .. ' | ' .. street2
                                        end
                                        local info = {
                                            label = Lang:t('info.casing'),
                                            type = 'casing',
                                            street = streetLabel:gsub("%'", ''),
                                            ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']],
                                            ammotype = Casings[CurrentCasing].type,
                                            serie = Casings[CurrentCasing].serie
                                        }
                                        TriggerServerEvent('evidence:server:AddCasingToInventory', CurrentCasing, info)
                                        if Config.Inventory == "ox" then
                                            exports.ox_inventory:displayMetadata({
                                                label = 'Label',
                                                type = 'Type',
                                                street = 'Street',
                                                ammolabel = 'Ammo Label',
                                                ammotype = 'Ammo Type',
                                                serie = 'Serial'
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if next(Blooddrops) then
                        local pos = GetEntityCoords(PlayerPedId(), true)
                        for k, v in pairs(Blooddrops) do
                            local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                            local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                            if dist < 20 then
                                CurrentBlooddrop = k
                                DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.BloodMarkerRGBA.r, Config.BloodMarkerRGBA.g, Config.BloodMarkerRGBA.b, Config.BloodMarkerRGBA.a, false, false, false, true, false, false, false)
                                if dist > 2.5 and dist < 10 then
                                    DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, "~r~Blood [ "..DnaHash(Blooddrops[CurrentBlooddrop].citizenid).." ]~s~")
                                elseif raycastdist < 0.25 and dist < 5 then
                                    DrawText3D(v.coords.x, v.coords.y, v.coords.z -0.05, Lang:t('info.blood_text', { value = DnaHash(Blooddrops[CurrentBlooddrop].citizenid) }))
                                    if IsControlJustReleased(0, 23) then
                                        local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                        local street1 = GetStreetNameFromHashKey(s1)
                                        local street2 = GetStreetNameFromHashKey(s2)
                                        local streetLabel = street1
                                        if street2 then
                                            streetLabel = streetLabel .. ' | ' .. street2
                                        end
                                        local info = {
                                            label = Lang:t('info.blood'),
                                            type = 'blood',
                                            street = streetLabel:gsub("%'", ''),
                                            dnalabel = DnaHash(Blooddrops[CurrentBlooddrop].citizenid),
                                            bloodtype = Blooddrops[CurrentBlooddrop].bloodtype
                                        }
                                        TriggerServerEvent('evidence:server:AddBlooddropToInventory', CurrentBlooddrop, info)
                                        if Config.Inventory == "ox" then
                                            exports.ox_inventory:displayMetadata({
                                                label = 'Label',
                                                type = 'Type',
                                                street = 'Street',
                                                dnalabel = 'DNA',
                                                bloodtype = 'Blood Type'
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if next(Fingerprints) then
                        local pos = GetEntityCoords(PlayerPedId(), true)
                        for k, v in pairs(Fingerprints) do
                            local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                            local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                            if dist < 20 then
                                CurrentFingerprint = k
                                DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.FingerprintMarkerRGBA.r, Config.FingerprintMarkerRGBA.g, Config.FingerprintMarkerRGBA.b, Config.FingerprintMarkerRGBA.a, false, false, false, true, false, false, false)
                                if dist > 2.5 and dist < 10 then
                                    DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, "~y~Fingerprint [ "..Fingerprints[CurrentFingerprint].fingerprint.." ]~s~")
                                elseif raycastdist < 0.25 and dist < 5 then
                                    DrawText3D(v.coords.x, v.coords.y, v.coords.z -0.05, Lang:t('info.fingerprint_text'))
                                    if IsControlJustReleased(0, 23) then
                                        local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                        local street1 = GetStreetNameFromHashKey(s1)
                                        local street2 = GetStreetNameFromHashKey(s2)
                                        local streetLabel = street1
                                        if street2 then
                                            streetLabel = streetLabel .. ' | ' .. street2
                                        end
                                        local info = {
                                            label = Lang:t('info.fingerprint'),
                                            type = 'fingerprint',
                                            street = streetLabel:gsub("%'", ''),
                                            fingerprint = Fingerprints[CurrentFingerprint].fingerprint
                                        }
                                        TriggerServerEvent('evidence:server:AddFingerprintToInventory', CurrentFingerprint, info)
                                        if Config.Inventory == "ox" then
                                            exports.ox_inventory:displayMetadata({
                                                label = 'Label',
                                                type = 'Type',
                                                street = 'Street',
                                                fingerprint = 'Fingerprint'
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if next(Bullethole) then
                        local pos = GetEntityCoords(PlayerPedId(), true)
                        for k, v in pairs(Bullethole) do
                            local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                            local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                            if dist < 20 then
                                CurrentBullethole = k
                                if Config.ShowShootersLine then
                                    DrawLine(v.coords.x, v.coords.y, v.coords.z -0.05, v.pedcoord.x, v.pedcoord.y, v.pedcoord.z, v.drawLine_r, v.drawLine_g, v.drawLine_b, 255)
                                end
                                if pos.z < v.coords.z then
                                    DrawMarker(6, v.coords.x, v.coords.y, v.coords.z -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.5, 0.1, Config.BulletholeMarkerRGBA.r, Config.BulletholeMarkerRGBA.g, Config.BulletholeMarkerRGBA.b, Config.BulletholeMarkerRGBA.a, false, true, 2, nil, nil, false)
                                else
                                    DrawMarker(0, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 0.1, Config.BulletholeMarkerRGBA.r, Config.BulletholeMarkerRGBA.g, Config.BulletholeMarkerRGBA.b, Config.BulletholeMarkerRGBA.a, false, true, 2, nil, nil, false)
                                end
                                if raycastdist < 0.25 and dist < 2.5 then
                                    DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                    if IsControlJustReleased(0, 23) then
                                        local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                        local street1 = GetStreetNameFromHashKey(s1)
                                        local street2 = GetStreetNameFromHashKey(s2)
                                        local streetLabel = street1
                                        if street2 then
                                            streetLabel = streetLabel .. ' | ' .. street2
                                        end
                                        local info = {
                                            label = Lang:t('info.bullet'),
                                            type = 'bullet',
                                            street = streetLabel:gsub("%'", ''),
                                            ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']],
                                            ammotype = Bullethole[CurrentBullethole].type,
                                            serie = Bullethole[CurrentBullethole].serie
                                        }
                                        TriggerServerEvent('evidence:server:AddBulletToInventory', CurrentBullethole, info)
                                        if Config.Inventory == "ox" then
                                            exports.ox_inventory:displayMetadata({
                                                label = 'Label',
                                                type = 'Type',
                                                street = 'Street',
                                                ammolabel = 'Ammo Label',
                                                ammotype = 'Ammo Type',
                                                serie = 'Serial'
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if next(Fragements) then
                        local pos = GetEntityCoords(PlayerPedId(), true)
                        for k, v in pairs(Fragements) do
                            local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                            local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                            if dist < 20 then
                                CurrentVehicleFragement = k
                                if Config.ShowShootersLine then
                                    DrawLine(v.coords.x, v.coords.y, v.coords.z -0.05, v.pedcoord.x, v.pedcoord.y, v.pedcoord.z, v.drawLine_r, v.drawLine_g, v.drawLine_b, 255)
                                end
                                if GetEntityType(entityHit) then
                                    if dist < 7.5 and dist > 1.5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.05, Lang:t('info.vehicle_fragement'))
                                    end
                                    DrawMarker(36, v.coords.x, v.coords.y, v.coords.z -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.3, 0.2, v.r, v.g, v.b, 220, false, true, 2, nil, nil, false)
                                end
                                if dist < 1.5 then
                                    DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                    if IsControlJustReleased(0, 23) then
                                        local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                        local street1 = GetStreetNameFromHashKey(s1)
                                        local street2 = GetStreetNameFromHashKey(s2)
                                        local streetLabel = street1
                                        if street2 then
                                            streetLabel = streetLabel .. ' | ' .. street2
                                        end
                                        local info = {
                                            label = Lang:t('info.bullet'),
                                            type = 'vehiclefragement',
                                            street = streetLabel:gsub("%'", ''),
                                            rgb = "R: " ..v.r.. " / G: " ..v.g.. " / B: " ..v.b,
                                            ammotype = Fragements[CurrentVehicleFragement].type,
                                            serie = Fragements[CurrentVehicleFragement].serie
                                        }
                                        TriggerServerEvent('evidence:server:AddFragementToInventory', CurrentVehicleFragement, info)
                                        if Config.Inventory == "ox" then
                                            exports.ox_inventory:displayMetadata({
                                                label = 'Label',
                                                type = 'Type',
                                                street = 'Street',
                                                rgb = '',
                                                ammotype = 'Ammo Type',
                                                serie = 'Serial'
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                else
                    Wait(1000)
                end
            else
                Wait(5000)
            end
        end
    end
end)