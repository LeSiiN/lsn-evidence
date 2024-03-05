local Translations = {
    error = {
        blood_not_cleared = 'Blod ikke ryddet',
        bullet_casing_not_removed = 'Kulehylse ikke fjernet',
        bullet_hole_not_removed = 'Kulehull fjernet ikke',
        vehicle_fragments_not_removed = 'Kjøretøyfragmenter ikke fjernet',
        scene_not_removed = 'Åsted ikke fjernet',
        config_error = 'LSN-EVIDENCE: Something is wrong in the Config',
        no_player = 'Ingen spiller i rekkevidde!',
        have_evidence_bag = 'Du må ha en tom bevispose med deg',
        plate_nil = 'Plate is nil!',
            },
    success = {
        blood_clear = 'Blod ryddet',
        bullet_casing_removed = 'Kulehylse fjernet...',
        bullet_hole_removed = 'Kulehull fjernet...',
        vehicle_fragment_removed = 'Kjøretøyfragmenter fjernet...',
        crime_scene_removed = 'Åsted ble ryddet...',
    },
    info = {
        dna_sample = 'DNA Prøve',
        casing = 'Kulehylse',
        bullet = 'Ammunisjonsfragment',
        blood = 'Blod',
        vehicle_fragment = 'kjøretøy fragment',
        fingerprint = 'Fingeravtrykk',
        player_id = 'ID of Player',
        unknown = 'Ukjent',
    },
    evidence = {
        serial_not_visible = 'Serienummer ikke synlig...',
    },
    commands = {
        clear_casign = 'Clear Area of Casings (Bare politi)',
        clear_bullethole = 'Clear Area of Bulletholes (Bare politi)',
        clear_fragments = 'Clear Area of Vehicle Fragments (Bare politi)',
        clear_crime_scene = 'Clear Area of all Evidence (Bare politi)',
        clearblood = 'Clear The Area of Blood (Bare politi)',
        takedna = 'Ta en DNA -prøve fra en person (tom bevispose nødvendig) (Bare politi)',
    },
    progressbar = {
        blood_clear = 'Fjerner blod...',
        bullet_casing = 'Fjerner kulehylster..',
        bullet_hole = 'Fjerner Kulehull..',
        vehicle_fragments = 'Fjerner kjøretøyfragment..',
        crime_scene = 'Fjerner alle bevis..',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
