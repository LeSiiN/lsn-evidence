------------------------------------------------------------------------------[ VARIABLES ]------------------------------------------------------------------------------
PlayerJob = {}

local QBCore = exports['qb-core']:GetCoreObject()
local resourceState = GetResourceState('lsn-evidence')
local ox_inventoryState = GetResourceState('ox_inventory')

local Casings = {}
local CurrentCasing = nil

local Blooddrops = {}
local CurrentBlooddrop = nil

local Fingerprints = {}
local CurrentFingerprint = 0

local Bullethole = {}
local CurrentBullethole = nil

local Fragments = {}
local CurrentVehicleFragment = nil

local Footprints = {}
local CurrentFootprints = 0

local currentTime = 0
local r, g, b = 0, 0, 0

local drawLine_r, drawLine_g, drawLine_b = 0, 0, 0
local FingerprintsList = {}

local timer = {}

local WhitelistedWeapons = {
    `weapon_unarmed`,
    `weapon_snowball`,
    `weapon_stungun`,
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`
}

local whitelistedMaleShoes = {
    [33] = true, -- barefoot
    [34] = true -- barefoot
}

local whitelistedFemaleShoes = {
    [34] = true, -- barefoot
    [35] = true -- barefoot
}

------------------------------------------------------------------------------[ FUNCTIONS ]------------------------------------------------------------------------------
local function WhitelistedWeapon(weapon)
    for i = 1, #WhitelistedWeapons do
        if WhitelistedWeapons[i] == weapon then
            return true
        end
    end
    return false
end

local function IsWearingWhitelistedShoes()
    local ped = PlayerPedId()
    local shoeIndex = GetPedDrawableVariation(ped, 6)
    local model = GetEntityModel(ped)
    if model == `mp_m_freemode_01` then
        if whitelistedMaleShoes[shoeIndex] then
            return true
        end
    else
        if whitelistedFemaleShoes[shoeIndex] then
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
            TriggerServerEvent('evidence:server:CreateVehicleFragment', weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
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

local function WaitTimer(name, action, ...)
    if not Config.TimerName[name] then return end

    if not timer[name] then
        timer[name] = true
        action(...)
        Wait(Config.EvidenceDelay[name])
        timer[name] = false
    end
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

    if ox_inventoryState == 'started' then
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
            rgb = 'RGB',
            shoes = 'Shoe Number',
        })
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerJob = {}
    FingerprintsList = {}
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
RegisterNetEvent('evidence:client:AddVehicleFragment', function(vehiclefragmentId, weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b, serie)
    Fragments[vehiclefragmentId] = {
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

RegisterNetEvent('evidence:client:RemoveVehicleFragment', function(vehiclefragmentId)
    Fragments[vehiclefragmentId] = nil
    CurrentVehicleFragment = 0
end)

RegisterNetEvent('evidence:client:ClearVehicleFragmentsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local vehiclefragmentList = {}
    QBCore.Functions.Progressbar('clear_fragments', Lang:t('progressbar.vehicle_fragments'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Fragments and next(Fragments) then
            for vehiclefragmentId, _ in pairs(Fragments) do
                if #(pos - vector3(Fragments[vehiclefragmentId].coords.x, Fragments[vehiclefragmentId].coords.y, Fragments[vehiclefragmentId].coords.z)) <
                    10.0 then
                        vehiclefragmentList[#vehiclefragmentList + 1] = vehiclefragmentId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.vehicle_fragment_removed'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.vehicle_fragment_removed'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearVehicleFragments', vehiclefragmentList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.vehicle_fragments_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.vehicle_fragments_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ FOOTPRINTS ]-----------------------------------------
RegisterNetEvent('evidence:client:AddFootPrint', function(footprintId, shoes, coords, currentTime)
    Footprints[footprintId] = {
        shoes = shoes,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        },
        time = currentTime
    }
end)

RegisterNetEvent('evidence:client:RemoveFootPrint', function(footprintId)
    Footprints[footprintId] = nil
    CurrentFootprints = 0
end)

RegisterNetEvent('evidence:client:ClearFootprintInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local footprintList = {}
    QBCore.Functions.Progressbar('clear_casings', Lang:t('progressbar.bullet_casing'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Footprints and next(Footprints) then
            for footprintId, _ in pairs(Footprints) do
                if #(pos - vector3(Footprints[footprintId].coords.x, Footprints[footprintId].coords.y, Footprints[footprintId].coords.z)) <
                    10.0 then
                        footprintList[#footprintList + 1] = footprintId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.bullet_casing_removed'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.bullet_casing_removed'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearFootPrints', footprintList)
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

-----------------------------------------[ EVENTS FOR COMMANDS/ITEMS ]-----------------------------------------

local function ClearScene(progressDuration)
    local pos = GetEntityCoords(PlayerPedId())
    local bulletholeList, casingList, blooddropList, fingerprintList, vehiclefragmentList, footprintList = {}, {}, {}, {}, {}, {}

    QBCore.Functions.Progressbar('clear_scene', Lang:t('progressbar.crime_scene'), progressDuration, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'amb@medic@standing@tendtodead@idle_a',
        anim = 'idle_a',
        flags = 1,
    }, {}, {}, function() -- Done
        local function removeEvidence(evidenceTable, evidenceType, event, list)
            if evidenceTable and next(evidenceTable) then
                for evidenceId, _ in pairs(evidenceTable) do
                    local evidenceCoords = vector3(evidenceTable[evidenceId].coords.x, evidenceTable[evidenceId].coords.y, evidenceTable[evidenceId].coords.z)
                    if #(pos - evidenceCoords) < 30.0 then
                        list[#list + 1] = evidenceId
                    end
                end
                TriggerServerEvent('evidence:server:' .. event, list)
            end
        end

        removeEvidence(Bullethole, "bullethole", 'ClearBullethole', bulletholeList)
        removeEvidence(Casings, "casing", 'ClearCasings', casingList)
        removeEvidence(Blooddrops, "blood", 'ClearBlooddrops', blooddropList)
        removeEvidence(Fingerprints, "fingerprint", 'ClearFingerprints', fingerprintList)
        removeEvidence(Fragments, "vehiclefragment", 'ClearVehicleFragments', vehiclefragmentList)
        removeEvidence(Footprints, "footprint", 'ClearFootPrints', footprintList)

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
end

RegisterNetEvent('evidence:client:ClearScene', function() 
    ClearScene(5000)
end)

RegisterNetEvent('evidence:client:ClearSceneCrime', function() 
    ClearScene(30000)
end)
------------------------------------------------------------------------------[ WAS THREADS AT SOME POINT ]------------------------------------------------------------------------------

-----------------------------------------[ DROP EVIDENCE ]-----------------------------------------
AddEventHandler('CEventGunShot', function(witnesses, ped)
    WaitTimer('Evidence', function()
        if cache.ped ~= ped then return end

        if PlayerJob.type == 'leo' and not Config.PoliceCreatesEvidence then return end
        if IsPedShooting(ped) then
            local pedcoords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)

            local hit, entityHit, raycastcoords = lib.raycast.cam(511, 4, 1000)
            local weapon = GetSelectedPedWeapon(ped)
            if not WhitelistedWeapon(weapon) then
                currentTime = GetGameTimer()
                r, g, b = GetVehicleColor(entityHit)

                SendBulletHole(weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
                DropBulletCasing(weapon, ped, currentTime)
            end
        end
    end)
end)

if Config.AllowFootprints then
    AddEventHandler('CEventFootStepHeard', function(witnesses, ped)
        WaitTimer('Footprints', function()
            if cache.ped ~= ped then return end
            if PlayerJob.type == 'leo' and not Config.PoliceCreatesEvidence then return end

            local speed = GetEntitySpeed(ped)
            if speed > 6.5 then
                local shoes = GetPedDrawableVariation(ped, 6)
                if not IsWearingWhitelistedShoes() then
                    currentTime = GetGameTimer()
                    local coords = GetEntityCoords(ped)
                    TriggerServerEvent('evidence:server:CreateFootPrint', shoes, coords, currentTime)
                end
            end
        end)
    end)
end

-----------------------------------------[ REMOVE EVIDENCE ]-----------------------------------------
RegisterNetEvent('evidence:client:deleteEvidence', function()
    local RemoveEvidence = Config.RemoveEvidence * 60 * 1000
    local function cleanupEvidence(evidenceType, evidenceList)
        if evidenceList and next(evidenceList) then
            local evidenceToRemove = {}
            for k, v in pairs(evidenceList) do
                local currentEvidence = k
                local timer = GetGameTimer()
                local currentTimer = v.time + RemoveEvidence
                if timer > v.time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    evidenceList[currentEvidence] = nil
                end
            end
        end
    end
    
    cleanupEvidence("Casings", Casings)
    
    cleanupEvidence("Blooddrops", Blooddrops)
    
    cleanupEvidence("Fingerprints", Fingerprints)
    
    cleanupEvidence("Bullethole", Bullethole)
    
    cleanupEvidence("Fragments", Fragments)

    cleanupEvidence("Footprints", Footprints)
end)

-----------------------------------------[ CHECK WITH FLASHLIGHT OR CAMERA ]-----------------------------------------
local isLoopActive = false

lib.onCache('weapon', function(value)
    if not value then
        isLoopActive = false
        return
    end
    if value == joaat('WEAPON_FLASHLIGHT') then
        if LocalPlayer.state.isLoggedIn then
            if QBCore.Functions.GetPlayerData().job.type == 'leo' then
                if not isLoopActive then
                    isLoopActive = true  -- Enable the loop only if it's not already active
                    CreateThread(function()
                        while isLoopActive do
                            local sleep = 5
                            if IsPlayerFreeAiming(PlayerId()) then
                                sleep = 5
                                ProcessMarkers(Blooddrops, "blood")
                                ProcessMarkers(Fingerprints, "fingerprint")
                                ProcessMarkers(Casings, "casing")
                                ProcessMarkers(Bullethole, "bullet")
                                ProcessMarkers(Fragments, "vehiclefragment")
                                ProcessMarkers(Footprints, "footprint")
                                Wait(sleep)
                            else
                                sleep = 500
                                Wait(sleep)
                            end
                        end
                    end)
                end
            end
        end
    end
end)

CreateThread(function()
    local ped = PlayerPedId()
    local sleep = 2500
    while true do
        if IsEntityPlayingAnim(ped, "amb@world_human_paparazzi@male@base", "base",3) and PlayerJob.type == 'leo' then
            sleep = 5
            ProcessMarkers(Blooddrops, "blood")
            ProcessMarkers(Fingerprints, "fingerprint")
            ProcessMarkers(Casings, "casing")
            ProcessMarkers(Bullethole, "bullet")
            ProcessMarkers(Fragments, "vehiclefragment")
            ProcessMarkers(Footprints, "footprint")
            Wait(sleep)
        else
            sleep = 2500
            Wait(sleep)
        end
    end
end)

function DrawMarkerIfInRange(v, type)
    SetDrawOrigin(v.coords.x, v.coords.y, v.coords.z, 0)
    local textureDict = {
        blood = "blooddrops",
        fingerprint = "fingerprints",
        casing = "casings",
        bullet = "bullethole",
        footprint = "footprint",
    }
    if textureDict[type] then
        while not HasStreamedTextureDictLoaded(textureDict[type]) do
            Wait(10)
            RequestStreamedTextureDict(textureDict[type], true)
        end
        DrawSprite(textureDict[type], textureDict[type], 0, 0, 0.02, 0.035, 0, 255, 255, 255, 255)
        if type == "bullet" or type == "vehiclefragment" and Config.ShowShootersLine then
            DrawLine(v.coords.x, v.coords.y, v.coords.z, v.pedcoord.x, v.pedcoord.y, v.pedcoord.z, 255, 0, 0, 255)
        end
    elseif type == "vehiclefragment" then
        DrawMarker(36, v.coords.x, v.coords.y, v.coords.z - 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.3, 0.2, v.r, v.g, v.b, 220, false, true, 2, nil, nil, false)
        if Config.ShowShootersLine then
            DrawLine(v.coords.x, v.coords.y, v.coords.z, v.pedcoord.x, v.pedcoord.y, v.pedcoord.z, 255, 0, 0, 255)
        end
    end
end

if Config.PoliceJob == "hi-dev" then
    function CheckInteraction(marker, type, key)
        local pos = GetEntityCoords(PlayerPedId(), true)
        local coords = vector3(marker.coords.x, marker.coords.y, marker.coords.z)
        SetDrawOrigin(coords, 0)
        while not HasStreamedTextureDictLoaded("interact") do
            Wait(10)
            RequestStreamedTextureDict("interact", true)
        end

        DrawSprite("interact", "interact", 0, 0, 0.02, 0.035, 0, 255, 255, 255, 255)
        ClearDrawOrigin()
        if IsControlJustReleased(0, 38) then
            local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street1 = GetStreetNameFromHashKey(s1)
            local street2 = GetStreetNameFromHashKey(s2)
            local streetLabel = street1
            if street2 then
                streetLabel = streetLabel .. ' | ' .. street2
            end
            local info = {
                label = Lang:t('info.' .. type),
                type = type,
                street = streetLabel:gsub("%'", ''),
            }
            if type == "blood" then
                info.dnalabel = Lang:t('info.unknown')
                info.dnalabel2 = DnaHash(marker.citizenid)
                info.bloodtype = Lang:t('info.unknown')
                info.bloodtype2 = marker.bloodtype
                TriggerServerEvent('evidence:server:AddBlooddropToInventory', key, info)
            elseif type == "fingerprint" then
                info.fingerprint = Lang:t('info.unknown')
                info.fingerprint2 = marker.fingerprint
                TriggerServerEvent('evidence:server:AddFingerprintToInventory', key, info)
            elseif type == "casing" then
                info.ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[key].type]['ammotype']]
                info.ammotype = Lang:t('info.unknown')
                info.ammotype2 = Casings[key].type
                info.serie = Lang:t('info.unknown')
                info.serie2 = Casings[key].serie
                TriggerServerEvent('evidence:server:AddCasingToInventory', key, info)
            elseif type == "bullet" then
                info.ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Bullethole[key].type]['ammotype']]
                info.ammotype = Lang:t('info.unknown')
                info.ammotype2 = Bullethole[key].type
                info.serie = Lang:t('info.unknown')
                info.serie2 = Bullethole[key].serie
                TriggerServerEvent('evidence:server:AddBulletToInventory', key, info)
            elseif type == "vehiclefragment" then
                info.rgb = Lang:t('info.unknown')
                info.rgb2 = "R: " ..marker.r.. " / G: " ..marker.g.. " / B: " ..marker.b
                info.ammotype = Lang:t('info.unknown')
                info.ammotype2 = Fragments[key].type
                info.serie = Lang:t('info.unknown')
                info.serie2 = Fragments[key].serie
                TriggerServerEvent('evidence:server:AddFragmentToInventory', key, info)
            elseif type == "footprint" then
                info.shoes = Lang:t('info.unknown')
                info.shoes2 = Footprints[key].shoes
                TriggerServerEvent('evidence:server:AddFootPrintToInventory', key, info)
            end
        end
    end
elseif Config.PoliceJob == "qb" then
    function CheckInteraction(marker, type, key)
        local pos = GetEntityCoords(PlayerPedId(), true)
        local coords = vector3(marker.coords.x, marker.coords.y, marker.coords.z)
        SetDrawOrigin(coords, 0)
        while not HasStreamedTextureDictLoaded("interact") do
            Wait(10)
            RequestStreamedTextureDict("interact", true)
        end

        DrawSprite("interact", "interact", 0, 0, 0.02, 0.035, 0, 255, 255, 255, 255)
        ClearDrawOrigin()
        if IsControlJustReleased(0, 38) then
            local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street1 = GetStreetNameFromHashKey(s1)
            local street2 = GetStreetNameFromHashKey(s2)
            local streetLabel = street1
            if street2 then
                streetLabel = streetLabel .. ' | ' .. street2
            end
            local info = {
                label = Lang:t('info.' .. type),
                type = type,
                street = streetLabel:gsub("%'", ''),
            }
            if type == "blood" then
                info.dnalabel = DnaHash(marker.citizenid)
                info.bloodtype = marker.bloodtype
                TriggerServerEvent('evidence:server:AddBlooddropToInventory', key, info)
            elseif type == "fingerprint" then
                info.fingerprint = marker.fingerprint
                TriggerServerEvent('evidence:server:AddFingerprintToInventory', key, info)
            elseif type == "casing" then
                info.ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[key].type]['ammotype']]
                info.ammotype = Casings[key].type
                info.serie = Casings[key].serie
                TriggerServerEvent('evidence:server:AddCasingToInventory', key, info)
            elseif type == "bullet" then
                info.ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Bullethole[key].type]['ammotype']]
                info.ammotype = Bullethole[key].type
                info.serie = Bullethole[key].serie
                TriggerServerEvent('evidence:server:AddBulletToInventory', key, info)
            elseif type == "vehiclefragment" then
                info.rgb = "R: " ..marker.r.. " / G: " ..marker.g.. " / B: " ..marker.b
                info.ammotype = Fragments[key].type
                info.serie = Fragments[key].serie
                TriggerServerEvent('evidence:server:AddFragmentToInventory', key, info)
            elseif type == "footprint" then
                info.shoes = Footprints[key].shoes
                TriggerServerEvent('evidence:server:AddFootPrintToInventory', key, info)
            end
        end
    end
end

function ProcessMarkers(markers, type)
    local pos = GetEntityCoords(PlayerPedId(), true)
    for k, v in pairs(markers) do
        local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
        if dist > 1.1 and dist < 20 then
            DrawMarkerIfInRange(v, type)
        elseif dist < 1 then
            CheckInteraction(v, type, k)
        end
    end
end
