local Translations = {
    error = {
        have_evidence_bag = 'You need an evidence bag to take the evidence',
        blood_not_cleared = 'Blood NOT cleared',
        bullet_casing_not_removed = 'Bullet Casings NOT Removed',
        bullet_hole_not_removed = 'Bullet Holes NOT Removed',
        vehicle_fragements_not_removed = 'Vehicle Fragements NOT Removed',
        scene_not_removed = 'Crime Scene NOT Removed',
        config_error = 'LSN-EVIDENCE: Something is wrong in the Config',
    },
    success = {
        blood_clear = 'Blood Cleared',
        bullet_casing_removed = 'Bullet Casings Removed...',
        bullet_hole_removed = 'Bullet Holes Removed...',
        vehicle_fragement_removed = 'Vehicle Fragements Removed...',
        crime_scene_removed = 'Crime Scene Removed...',
    },
    info = {
        dna_sample = 'DNA Sample',
        bullet_casing = '[~g~F~s~] Pick up',
        casing = 'Bullet Casing',
        bullet = 'Bullet',
        blood = 'Blood',
        blood_text = '[~g~F~s~] Pick up',
        fingerprint_text = '[~g~F~s~] Pick up',
        vehicle_fragement = 'Vehicle Fragement',
        fingerprint = 'Fingerprint',
        player_id = 'ID of Player',
    },
    evidence = {
        serial_not_visible = 'Serial number not visible...',
    },
    commands = {
        clear_casign = 'Clear Area of Casings (Police Only)',
        clear_bullethole = 'Clear Area of Bulletholes (Police Only)',
        clear_fragements = 'Clear Area of Vehicle Fragements (Police Only)',
        clear_crime_scene = 'Clear Area of all Evidence (Police Only)',
        clearblood = 'Clear The Area of Blood (Police Only)',
        takedna = 'Take a DNA sample from a person (empty evidence bag needed) (Police Only)',
    },
    progressbar = {
        blood_clear = 'Clearing Blood...',
        bullet_casing = 'Removing bullet casings..',
        bullet_hole = 'Removing bullet holes..',
        vehicle_fragements = 'Removing vehicle fragements..',
        crime_scene = 'Removing all evidence..',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
