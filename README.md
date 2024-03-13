# lsn-evidence
    This Script was made from the evidence Code from qb-policejob! Please follow the Installation!

# To-Do
    Only allow to pick up a single Evidence Marker when near 2 (and show the 'E' Interact to just 1 Evidence Marker)
    
# Features
- Bullet casings as Evidence
- Blood drop as Evidence
- Fingerprint drops as Evidence
- Bulletholes as Evidence
- Vehicle Fragments as Evidence
- DrawLine of the Shooting Position
- Evidence can be checked via weapon_flashlight ( can be picked up )
- Criminals can remove evidence
- Also work when Player is using a Camera ( must be playing a specific animation )
- Evidence automatically removes after 45Min. (Performance thing)

# Commands ( OPTIONAL )
- /clearblood - Clears nearby blood drops.
- /clearcasings - Clears nearby bullet casings.
- /clearholes - Clears nearby Bullet Holes drops.
- /clearfragments - Clears nearby Vehicle Fragments drops.
- /clearscene - Clears all nearby evidence drops.
- /takedna [id] - Takes a DNA sample from the player.

# New Items
- rag - Allows Criminals to delete nearby Evidence.
- evidencecleaningkit - Allows Police Officers to remove evidence. ( No need for the commands then )

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

<details><summary> If you use New QBCore</summary>

```
rag                         = { name = 'rag', label = 'Rag', weight = 100, type = 'item', image = 'rag.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'Could get Handy.' },
evidencecleaningkit         = { name = 'evidencecleaningkit', label = 'Evidence Cleaning Kit', weight = 250, type = 'item', image = 'cleaningkit.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'Cleans every Evidence near a police Officer.' },
```
</details>

<details><summary> If you use Old QBCore</summary>

```
["rag"]                          = { ["name"] = 'rag', ["label"] = 'Rag', ["weight"] = 100, ["type"] = 'item', ["image"] = 'rag.png', ["unique"] = false, ["useable"] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = 'Could get Handy.' },
["evidencecleaningkit"]          = { ["name"] = 'evidencecleaningkit', ["label"] = 'Evidence Cleaning Kit', ["weight"] = 250, ["type"] = 'item', ["image"] = 'cleaningkit.png', ["unique"] = false, ["useable"] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = 'Cleans every Evidence near a police Officer.' },
```
</details>

# Inventory
- Place the image inside your images folder in your inventory.

<details><summary> If you use New qb inventory</summary>

Add the following code to your app.js of your inventory (31.12.2023 Version  ->  line 365 )
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
            } else if (itemData.info.type == "vehiclefragment") {
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

</details>

<details><summary> If you use ps/lj inventory or old qb inventory( From Nov 3 2023)</summary>

lj line 559~
ps line 560~
qb line 375~

Replace the following code to your app.js of your inventory
```
        else if (itemData.name == "filled_evidence_bag") {
            $(".item-info-title").html("<p>" + itemData.label + "</p>");
            if (itemData.info.type == "casing") {
                $(".item-info-description").html(
                    "<p><strong>Evidence material: </strong><span>" +
                    itemData.info.label +
                    "</span></p><p><strong>Type number: </strong><span>" +
                    itemData.info.ammotype +
                    "</span></p><p><strong>Caliber: </strong><span>" +
                    itemData.info.ammolabel +
                    "</span></p><p><strong>Serial: </strong><span>" +
                    itemData.info.serie +
                    "</span></p><p><strong>Crime scene: </strong><span>" +
                    itemData.info.street +
                    "</span></p><br /><p>" +
                    itemData.description +
                    "</p>"
                );
            } else if (itemData.info.type == "bullet") {
                $(".item-info-description").html(
                    "<p><strong>Evidence material: </strong><span>" +
                    itemData.info.label +
                    "<p><strong>Type number: </strong><span>" +
                    itemData.info.ammotype +
                    "</span></p><p><strong>Bullet: </strong><span>" +
                    itemData.info.ammolabel +
                    "</span></p><p><strong>Serial Number: </strong><span>" +
                    itemData.info.serie +
                    "</span></p><p><strong>Crime scene: </strong><span>" +
                    itemData.info.street +
                    "</span></p><br /><p>" +
                    itemData.description +
                    "</p>"
                );
            } else if (itemData.info.type == "vehiclefragment") {
                $(".item-info-description").html(
                    "<p><strong>Evidence material: </strong><span>" +
                    itemData.info.label +
                    "</span></p><p><strong>Type number: </strong><span>" +
                    itemData.info.ammotype +
                    "</span></p><p><strong>Serial Number: </strong><span>" +
                    itemData.info.serie +
                    "</span></p><p><strong>Color: </strong><span>" +
                    itemData.info.rgb +
                    "</span></p><p><strong>Crime scene: </strong><span>" +
                    itemData.info.street +
                    "</span></p><br /><p>" +
                    itemData.description +
                    "</p>"
                );
            } else if (itemData.info.type == "blood") {
                $(".item-info-description").html(
                    "<p><strong>Evidence material: </strong><span>" +
                    itemData.info.label +
                    "</span></p><p><strong>Blood type: </strong><span>" +
                    itemData.info.bloodtype +
                    "</span></p><p><strong>DNA Code: </strong><span>" +
                    itemData.info.dnalabel +
                    "</span></p><p><strong>Crime scene: </strong><span>" +
                    itemData.info.street +
                    "</span></p><br /><p>" +
                    itemData.description +
                    "</p><p style=\"font-size:11px\"><b>Weight: </b>" + itemData.weight + " | <b>Amount: </b> " + itemData.amount + " | <b>Quality: </b> " + "<a style=\"font-size:11px;color:green\">" + Math.floor(itemData.info.quality) + "</a>"
                );
            } else if (itemData.info.type == "fingerprint") {
                $(".item-info-description").html(
                    "<p><strong>Evidence material: </strong><span>" +
                    itemData.info.label +
                    "</span></p><p><strong>Fingerprint: </strong><span>" +
                    itemData.info.fingerprint +
                    "</span></p><p><strong>Crime Scene: </strong><span>" +
                    itemData.info.street +
                    "</span></p><br /><p>" +
                    itemData.description +
                    "</p><p style=\"font-size:11px\"><b>Weight: </b>" + itemData.weight + " | <b>Amount: </b> " + itemData.amount + " | <b>Quality: </b> " + "<a style=\"font-size:11px;color:green\">" + Math.floor(itemData.info.quality) + "</a>"
                );
            } else if (itemData.info.type == "dna") {
                $(".item-info-description").html(
                    "<p><strong>Evidence material: </strong><span>" +
                    itemData.info.label +
                    "</span></p><p><strong>DNA Code: </strong><span>" +
                    itemData.info.dnalabel +
                    "</span></p><br /><p>" +
                    itemData.description +
                    "</p><p style=\"font-size:11px\"><b>Weight: </b>" + itemData.weight + " | <b>Amount: </b> " + itemData.amount + " | <b>Quality: </b> " + "<a style=\"font-size:11px;color:green\">" + Math.floor(itemData.info.quality) + "</a>"
                );
            }
        }
```

</details>

# QB-Policejob

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
- Place the following locales inside your locales folder make sure its in the evidence table(en.lua for example)
```
examine_menu_bullet_h = "Ammunition fragment",
examine_menu_bullet_b = "By examining the ammunition fragment you can determine the model and serial number of the weapon",
examine_menu_frags_h = "Vehicle fragment",
examine_menu_frags_b = "By examining the vehicle fragment you can determine the model and serial number of the vehicle",
```

## 💰 You can help me by Donating
[![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/LeSiiN)

# Credits
- [RazerGhost](https://github.com/RazerGhost)
- [My little Family](https://github.com/Project-Sloth)
