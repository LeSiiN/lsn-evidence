local Translations = {
    error = {
        blood_not_cleared = 'Blod ikke ryddet',
        bullet_casing_not_removed = 'Kulehylse ikke fjernet',
        bullet_hole_not_removed = 'Kulehull fjernet ikke',
        vehicle_fragments_not_removed = 'Kjøretøyfragmenter ikke fjernet',
        scene_not_removed = 'Åsted ikke fjernet',
        config_error = 'LSN-EVIDENCE: Noe er galt i din config',
        no_player = 'Ingen spiller i rekkevidde!',
        have_evidence_bag = 'Du må ha en tom bevispose med deg',
        plate_nil = 'Skilt nr er nil!',
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
        footprint = 'Fotspor',
        player_id = 'Spiller ID',
        unknown = 'Ukjent',
    },
    evidence = {
        serial_not_visible = 'Serienummer ikke synlig...',
    },
    commands = {
        clear_casign = 'Fjern hylser fra område (Bare politi)',
        clear_bullethole = 'Fjern kulehull fra området (Bare politi)',
        clear_fragments = 'Fjern fragmenter fra bil (Bare politi)',
        clear_crime_scene = 'Fjern ALLE bevis fra området (Bare politi)',
        clearblood = 'Fjern blod fra området (Bare politi)',
        clearfootprint = 'Fjern området for fotspor (Bare politi)', 
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
