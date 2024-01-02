Config = {}

---------[ If TRUE it shows the Line from where the Shooter shoot the bullet DEFAULT = RED ]---------
Config.ShowShootersLine = true

---------[ If TRUE Police will create evidence aswell ]---------
---------[ If Config.PoliceCreatesEvidence on TRUE DrawLine will be Green if the shoot was from a Police Officer ]---------
Config.PoliceCreatesEvidence = true

---------[ Enable or Disable Commands ]---------
Config.Commands = true

---------[ "qb" for qb-core Notify    or    "ox" for ox_lib Notify ]---------
Config.Notify = "qb"

-- SOON -- Config.Inventory = "qb" -- "qb" for qb/ps/lj-inventory    or    "ox" for ox_inventory
Config.Inventory = "ox"

---------[ Sets the MINUTES of how long Evidence should be visible. After this time, evidence will be removed one by one. DEFAULT: 45 Min ]---------
---------[ WARNING: Dont make this to low, otherwise Cops cant really do anything to make a Report ]---------
Config.RemoveEvidence = 45


Config.AmmoLabels = {
    ['AMMO_PISTOL'] = '9x19mm',
    ['AMMO_SMG'] = '9x19mm',
    ['AMMO_RIFLE'] = '7.62x39mm',
    ['AMMO_MG'] = '7.92x57mm',
    ['AMMO_SHOTGUN'] = '12-gauge',
    ['AMMO_SNIPER'] = 'Large caliber',
}

---------[ Change the Colour of the Casing Markers ]---------
Config.CasingMarkerRGBA = {
    r = 0,
    g = 0,
    b = 255,
    a = 175,
}

---------[ Change the Colour of the Blooddrops Markers ]---------
Config.BloodMarkerRGBA = { --Change the Colour of the Blooddrops Markers
    r = 255,
    g = 0,
    b = 0,
    a = 175,
}

---------[ Change the Colour of the Fingerprint Markers ]---------
Config.FingerprintMarkerRGBA = { --Change the Colour of the Fingerprint Markers
    r = 255,
    g = 127,
    b = 80,
    a = 175,
}

---------[ Change the Colour of the Bullethole Markers ]---------
Config.BulletholeMarkerRGBA = { --Change the Colour of the Bullethole Markers
    r = 160,
    g = 32,
    b = 240,
    a = 255,
}

---------[ These are the Events that can be added to ANY Client to make people drop Finger/Blood Drops. ]---------
--TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
--TriggerServerEvent('evidence:server:CreateBloodDrop', QBCore.Functions.GetPlayerData().citizenid, QBCore.Functions.GetPlayerData().metadata['bloodtype'], coords)
