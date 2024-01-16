# lsn-evidence
    This Script was made from the evidence Code from qb-policejob! Please follow the Installation!

# Dependencies
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib/releases)

# Installation
- Download the script and put it in the `resources` directory.
- Add the following code to your server.cfg/resouces.cfg ( Make sure that ox_lib starts before qb-core and lsn-evidence at last )
```
ensure ox_lib
ensure qb-core
ensure lsn-evidence
```
- Place the next code inside your items.lua
```
rag                         = { name = 'rag', label = 'Rag', weight = 100, type = 'item', image = 'rag.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'Could get Handy.' },
evidencecleaningkit         = { name = 'evidencecleaningkit', label = 'Evidence Cleaning Kit', weight = 250, type = 'item', image = 'cleaningkit.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'Cleans every Evidence near a police Officer.' },
policepointer         = { name = 'policepointer', label = 'Laserpointer', weight = 250, type = 'item', image = 'laserpointer.png', unique = true, useable = true, shouldClose = true, combinable = nil, description = 'Can be placed inside Bulletholes.' },
```
- Place the image inside your images folder in your inventory. ( ox-inventory will follow! )
- Add the following code to your app.js of your inventory (31.12.2023 Version  ->  line 365 )
```
        case "filled_evidence_bag":
            if (itemData.info.type == "casing") {
                return `<p><strong>Evidence material: </strong><span>${itemData.info.label}</span></p>
                <p><strong>Type number: </strong><span>${itemData.info.ammotype}</span></p>
                <p><strong>Caliber: </strong><span>${itemData.info.ammolabel}</span></p>
                <p><strong>Serial Number: </strong><span>${itemData.info.serie}</span></p>
                <p><strong>Crime scene: </strong><span>${itemData.info.street}</span></p><br /><p>${itemData.description}</p>`;
            } else if (itemData.info.type == "bullet") {
                return `<p><strong>Evidence material: </strong><span>${itemData.info.label}</span></p>
                <p><strong>Type number: </strong><span>${itemData.info.ammotype}</span></p>
                <p><strong>Bullet: </strong><span>${itemData.info.ammolabel}</span></p>
                <p><strong>Serial Number: </strong><span>${itemData.info.serie}</span></p>
                <p><strong>Crime scene: </strong><span>${itemData.info.street}</span></p><br /><p>${itemData.description}</p>`;
            } else if (itemData.info.type == "vehiclefragement") {
                return `<p><strong>Evidence material: </strong><span>${itemData.info.label}</span></p>
                <p><strong>Type number: </strong><span>${itemData.info.ammotype}</span></p>
                <p><strong>Serial Number: </strong><span>${itemData.info.serie}</span></p>
                <p><strong>Color: </strong><span>${itemData.info.rgb}</span></p>
                <p><strong>Crime scene: </strong><span>${itemData.info.street}</span></p><br /><p>${itemData.description}</p>`;
            } else if (itemData.info.type == "blood") {
                return `<p><strong>Evidence material: </strong><span>${itemData.info.label}</span></p>
                <p><strong>Blood type: </strong><span>${itemData.info.bloodtype}</span></p>
                <p><strong>DNA Code: </strong><span>${itemData.info.dnalabel}</span></p>
                <p><strong>Crime scene: </strong><span>${itemData.info.street}</span></p><br /><p>${itemData.description}</p>`;
            } else if (itemData.info.type == "fingerprint") {
                return `<p><strong>Evidence material: </strong><span>${itemData.info.label}</span></p>
                <p><strong>Fingerprint: </strong><span>${itemData.info.fingerprint}</span></p>
                <p><strong>Crime Scene: </strong><span>${itemData.info.street}</span></p><br /><p>${itemData.description}</p>`;
            } else if (itemData.info.type == "dna") {
                return `<p><strong>Evidence material: </strong><span>${itemData.info.label}</span></p>
                <p><strong>DNA Code: </strong><span>${itemData.info.dnalabel}</span></p><br /><p>${itemData.description}</p>`;
            }
```
- Replace `evidence.lua` inside `REPLACE FOLDERS` with the `qb-policejob/client/evidence.lua`
- Replace `main.lua` inside `REPLACE FOLDERS` with the `qb-policejob/server/main.lua`
- Remove the following code from your `qb-policejob/config.lua`
```
Config.AmmoLabels = {
    ['AMMO_PISTOL'] = '9x19mm parabellum bullet',
    ['AMMO_SMG'] = '9x19mm parabellum bullet',
    ['AMMO_RIFLE'] = '7.62x39mm bullet',
    ['AMMO_MG'] = '7.92x57mm mauser bullet',
    ['AMMO_SHOTGUN'] = '12-gauge bullet',
    ['AMMO_SNIPER'] = 'Large caliber bullet',
}
```

# IF USING HI-DEV POLICEJOB ALSO DO THIS:
- Replace `police:client:FindEvidenceBag` inside your client/main.lua
```
RegisterNetEvent('police:client:FindEvidenceBag', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local FindEvidence = {}
    FindEvidence[#FindEvidence+1] = {opthead = Lang:t('evidence.examine_menu_blood_h'), optdesc = Lang:t('evidence.examine_menu_blood_b'), opticon = 'droplet',
        optparams = {
            event = 'police:client:SelectEvidence',
            args = {type = 'blood', label = 'Blood', icon = 'droplet'}
        }}
    FindEvidence[#FindEvidence+1] = {opthead = Lang:t('evidence.examine_menu_casing_h'), optdesc = Lang:t('evidence.examine_menu_casing_b'), opticon = 'joint',
        optparams = {
            event = 'police:client:SelectEvidence',
            args = {type = 'casing', label = 'Bullet casing', icon = 'joint'}
        }}
    FindEvidence[#FindEvidence+1] = {opthead = Lang:t('evidence.examine_menu_fingerprint_b'),optdesc = Lang:t('evidence.examine_menu_fingerprint_h'), opticon = 'fingerprint',
        optparams = {
            event = 'police:client:SelectEvidence',
            args = {type = 'fingerprint', label = 'Fingerprint', icon = 'fingerprint',}
        }}
    FindEvidence[#FindEvidence+1] = {opthead = Lang:t('evidence.examine_menu_bullet_b'),optdesc = Lang:t('evidence.examine_menu_bullet_h'), opticon = 'joint',
        optparams = {
            event = 'police:client:SelectEvidence',
            args = {type = 'bullet', label = 'Bullet', icon = 'joint',}
        }}
    FindEvidence[#FindEvidence+1] = {opthead = Lang:t('evidence.examine_menu_frags_b'),optdesc = Lang:t('evidence.examine_menu_frags_h'), opticon = 'car',
        optparams = {
            event = 'police:client:SelectEvidence',
            args = {type = 'vehiclefragement', label = 'Vehicle Fragment', icon = 'car',}
        }}         
    FindEvidence[#FindEvidence+1] = {opthead = Lang:t('menu.close_x'), opticon = 'xmark', optparams = {event = ''}}

    local header = {
        disabled = true,
        header = PlayerData.job.label,
        headerid = 'police_evidencebags_menu', -- unique
        desc = '',
        icon = 'microscope'
    }
    ContextSystem.Open(header, FindEvidence)
end)
```
- Place the following locales inside your locales folder make sure its in the evidence table(en.lua for example)
```
examine_menu_bullet_h = "Examine ammunition fragment",
examine_menu_bullet_b = "Examine ammunition fragment",
examine_menu_frags_h = "Examine vehicle fragment",
examine_menu_frags_b = "Examine vehicle fragment",
```

# Features
- Bullet casings as Evidence
- Blood drop as Evidence
- Fingerprint drops as Evidence
- Bulletholes as Evidence
- Vehicle Fragements as Evidence
- DrawLine of the Shooting Position
- Evidence can be checked via weapon_flashlight ( can be picked up )
- Criminals can remove evidence
- Also work when Player is using a Camera ( must be playing a specific animation )
- By using the Laserpointer near a Bullethole u can see the DrawLines of each shoot
- Evidence automatically removes after 45Min. (Performance thing)

# Commands ( OPTIONAL )
- /clearblood - Clears nearby blood drops.
- /clearcasings - Clears nearby bullet casings.
- /clearholes - Clears nearby Bullet Holes drops.
- /clearfragements - Clears nearby Vehicle Fragements drops.
- /clearscene - Clears all nearby evidence drops.
- /takedna [id] - Takes a DNA sample from the player.

# New Items
- rag - Allows Criminals to delete nearby Evidence.
- evidencecleaningkit - Allows Police Officers to remove evidence. ( No need for the commands then )
- policepointer - Allows Police Officers to see the DrawLines.

## 💰 You can help me by Donating
[![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/LeSiiN)
  
# Credits
- [RazerGhost](https://github.com/RazerGhost)
- [My little Family](https://github.com/Project-Sloth)
