Config = {}
Config.Graffitis = {}
QBCore = exports['qb-core']:GetCoreObject()

Config.MinGangMembers = 1 -- Minimum active gang members required to protect territory

-- Blacklisted zones where no graffiti can be placed
Config.BlacklistedZones = {
    {coords = vector3(455.81, -997.04, 43.69), radius = 200.0}, -- Police
    {coords = vector3(324.76, -585.72, 59.15), radius = 300.0}, -- Hospital
    {coords = vector3(-376.73, -119.47, 40.73), radius = 400.0}, -- Mechanic
}

Config.Sprays = {
    -- Non-gang sprays (available to everyone)

    [GetHashKey('sprays_cerberus')] = {
        name = 'Spray Cerberus',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = nil, -- Available to everyone
    },

    [GetHashKey('sprays_ramee')] = {
        name = 'Spray Ramee',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = nil, -- Available to everyone
    },

    [GetHashKey('sprays_ron')] = {
        name = 'Spray Ron',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = nil, -- Available to everyone
    },

    [GetHashKey('sprays_angels')] = {
        name = 'Spray Angels',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'angels', -- Available to everyone
    },

    [GetHashKey('sprays_ballas')] = {
        name = 'Spray Ballas',
        price = 5000,
        blip = true,
        blipcolor = 27,
        gang = 'ballas',
    },

    [GetHashKey('sprays_bbmc')] = {
        name = 'Spray BBMC',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'bbmc',
    },

    [GetHashKey('sprays_bcf')] = {
        name = 'Spray BCF',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'bcf',
    },

    [GetHashKey('sprays_bsk')] = {
        name = 'Spray BSK',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'bsk',
    },

    [GetHashKey('sprays_cg')] = {
        name = 'Spray CG',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'cg',
    },

    [GetHashKey('sprays_gg')] = {
        name = 'Spray GG',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'gg',
    },

    [GetHashKey('sprays_gsf')] = {
        name = 'Spray GSF',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'gsf',
    },

    [GetHashKey('sprays_guild')] = {
        name = 'Spray Guild',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'guild',
    },

    [GetHashKey('sprays_hoa')] = {
        name = 'Spray Hoa',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'hoa',
    },

    [GetHashKey('sprays_hydra')] = {
        name = 'Spray Hydra',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'hydra',
    },

    [GetHashKey('sprays_kingz')] = {
        name = 'Spray Kingz',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'kingz',
    },

    [GetHashKey('sprays_lost')] = {
        name = 'Spray Lost',
        price = 5000,
        blip = true,
        blipcolor = 22,
        gang = 'lost',
    },

    [GetHashKey('sprays_mandem')] = {
        name = 'Spray Mandem',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'mandem',
    },

    [GetHashKey('sprays_mayhem')] = {
        name = 'Spray Mayhem',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'mayhem',
    },

    [GetHashKey('sprays_nbc')] = {
        name = 'Spray NBC',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'nbc',
    },

    [GetHashKey('sprays_rust')] = {
        name = 'Spray Rust',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'rust',
    },

    [GetHashKey('sprays_scu')] = {
        name = 'Spray SCU',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'scu',
    },

    [GetHashKey('sprays_seaside')] = {
        name = 'Spray Seaside',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'seaside',
    },

    [GetHashKey('sprays_st')] = {
        name = 'Spray ST',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = 'st',
    },

    [GetHashKey('sprays_vagos')] = {
        name = 'Spray Vagos',
        price = 5000,
        blip = true,
        blipcolor = 28,
        gang = 'vagos',
    },
}