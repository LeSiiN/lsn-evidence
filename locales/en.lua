local Translations = {
    error = {
        blood_not_cleared = 'Blood NOT cleared',
        bullet_casing_not_removed = 'Bullet Casings NOT Removed',
        bullet_hole_not_removed = 'Bullet Holes NOT Removed',
        vehicle_fragments_not_removed = 'Vehicle Fragments NOT Removed',
        scene_not_removed = 'Crime Scene NOT Removed',
        config_error = 'LSN-EVIDENCE: Something is wrong in the Config',
        no_player = 'No Player in reach!',
        have_evidence_bag = 'You must have an empty evidence bag with you',
        plate_nil = 'Plate is nil!',
    },
    success = {
        blood_clear = 'Blood Cleared',
        bullet_casing_removed = 'Bullet Casings Removed...',
        bullet_hole_removed = 'Bullet Holes Removed...',
        vehicle_fragment_removed = 'Vehicle Fragments Removed...',
        crime_scene_removed = 'Crime Scene Removed...',
    },
    info = {
        dna_sample = 'DNA Sample',
        casing = 'Bullet Casing',
        bullet = 'Bullet',
        blood = 'Blood',
        vehiclefragment = 'Fragment',
        fingerprint = 'Fingerprint',
        footprint = 'Footprint',
        player_id = 'ID of Player',
        unknown = 'Unknown',
    },
    evidence = {
        serial_not_visible = 'Serial number not visible...',
    },
    commands = {
        clear_casign = 'Clear Area of Casings (Police Only)',
        clear_bullethole = 'Clear Area of Bulletholes (Police Only)',
        clear_fragments = 'Clear Area of Vehicle Fragments (Police Only)',
        clear_crime_scene = 'Clear Area of all Evidence (Police Only)',
        clearblood = 'Clear The Area of Blood (Police Only)',
        clearfootprint = 'Clear The Area of Footprints (Police Only)',
        takedna = 'Take a DNA sample from a person (empty evidence bag needed) (Police Only)',
    },
    progressbar = {
        blood_clear = 'Clearing Blood...',
        bullet_casing = 'Removing bullet casings..',
        bullet_hole = 'Removing bullet holes..',
        vehicle_fragments = 'Removing vehicle fragments..',
        crime_scene = 'Removing all evidence..',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
