# lsn-evidence
    This Script was made from the evidence Code from qb-policejob! Please follow the Installation!

## Dependencies
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib/releases)

## Installation
### Manual
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
- If your using default qb-policejob use files inside here `[qb-policejob] REPLACE THESE` if your using hi-dev's version, use the files inside here `[hi-dev - qb-policejob] REPLACE THESE`
 
- Replace `evidence.lua` inside `[qb-policejob] REPLACE THESE` or `[hi-dev - qb-policejob] REPLACE THESE` with the `qb-policejob/client/evidence.lua`
 
- Replace `main.lua` inside `[qb-policejob] REPLACE THESE` or `[hi-dev - qb-policejob] REPLACE THESE` with the `qb-policejob/server/main.lua`
 
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
## Features
- Bullet casings as Evidence
- Blood drop as Evidence
- Fingerprint drops as Evidence
- Bulletholes as Evidence
- Vehicle Fragements as Evidence
- DrawLine of the Shooting Position
- Evidence can be checked via weapon_flashlight ( can be picked up )
- Criminals can remove evidence
- Evidence automatically removes after 45Min. (Performance thing)

### Commands
- /clearblood - Clears nearby blood drops.
- /clearcasings - Clears nearby bullet casings.
- /clearholes - Clears nearby Bullet Holes drops.
- /clearfragements - Clears nearby Vehicle Fragements drops.
- /clearscene - Clears all nearby evidence drops.
- /takedna [id] - Takes a DNA sample from the player.

### New Items
- rag - Allows Criminals to delete nearby Evidence.
- evidencecleaningkit - Allows Police Officers to remove evidence. ( No need for the commands then )
