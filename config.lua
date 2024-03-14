Config = {}

---------[ If TRUE it shows the Line from where the Shooter shoot the bullet DEFAULT = RED (Deactivates the Laserpointer) ]---------
Config.ShowShootersLine = true

---------[ If TRUE Police will create evidence aswell ]---------
Config.PoliceCreatesEvidence = true

---------[ Enable or Disable Commands ]---------
Config.Commands = true

---------[ Enable or Disable Footprints ]---------
Config.AllowFootprints = true

---------[ "qb" for qb-core Notify    or    "ox" for ox_lib Notify ]---------
Config.Notify = "qb"

---------[ "qb" for default qb-policejob    or    "hi-dev" for hi-dev qb-policejob ]---------
Config.PoliceJob = "qb"

Config.Inventory = "qb" -- "qb" for qb/ps/lj-inventory    or    "ox" for ox_inventory

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

Config.EvidenceDelay = {  -- in ms  //  Delay between each evidence drop (Higher number less evidence drops)
    Evidence = 200,
    Footprints = 2500
}

Config.TimerName = {
    Evidence = true,
    Footprints = true
}

---------[ These are the Events that can be added to ANY Client to make people drop Finger/Blood Drops. ]---------
--TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
--TriggerServerEvent('evidence:server:CreateBloodDrop', QBCore.Functions.GetPlayerData().citizenid, QBCore.Functions.GetPlayerData().metadata['bloodtype'], coords)
