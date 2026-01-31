-- LazyPI Specialization Data
-- Contains all DPS class specializations with their IDs

local addonName, addon = ...

-- Specialization IDs from the game (DPS specs only)
-- Format: [specID] = { name = "Spec Name", class = "CLASS" }

addon.SpecInfo = {
    -- Death Knight
    [251] = { name = "Frost", class = "DEATHKNIGHT" },
    [252] = { name = "Unholy", class = "DEATHKNIGHT" },

    -- Demon Hunter
    [577] = { name = "Havoc", class = "DEMONHUNTER" },

    -- Druid
    [102] = { name = "Balance", class = "DRUID" },
    [103] = { name = "Feral", class = "DRUID" },

    -- Evoker
    [1467] = { name = "Devastation", class = "EVOKER" },
    [1473] = { name = "Augmentation", class = "EVOKER" },

    -- Hunter
    [253] = { name = "Beast Mastery", class = "HUNTER" },
    [254] = { name = "Marksmanship", class = "HUNTER" },
    [255] = { name = "Survival", class = "HUNTER" },

    -- Mage
    [62] = { name = "Arcane", class = "MAGE" },
    [63] = { name = "Fire", class = "MAGE" },
    [64] = { name = "Frost", class = "MAGE" },

    -- Monk
    [269] = { name = "Windwalker", class = "MONK" },

    -- Paladin
    [70] = { name = "Retribution", class = "PALADIN" },

    -- Priest
    [258] = { name = "Shadow", class = "PRIEST" },

    -- Rogue
    [259] = { name = "Assassination", class = "ROGUE" },
    [260] = { name = "Outlaw", class = "ROGUE" },
    [261] = { name = "Subtlety", class = "ROGUE" },

    -- Shaman
    [262] = { name = "Elemental", class = "SHAMAN" },
    [263] = { name = "Enhancement", class = "SHAMAN" },

    -- Warlock
    [265] = { name = "Affliction", class = "WARLOCK" },
    [266] = { name = "Demonology", class = "WARLOCK" },
    [267] = { name = "Destruction", class = "WARLOCK" },

    -- Warrior
    [71] = { name = "Arms", class = "WARRIOR" },
    [72] = { name = "Fury", class = "WARRIOR" },
}

-- Default priority order (best to worst)
addon.DefaultPriorityOrder = {
    62,   -- Arcane Mage
    265,  -- Affliction Warlock
    63,   -- Fire Mage
    266,  -- Demonology Warlock
    1473, -- Augmentation Evoker
    102,  -- Balance Druid
    258,  -- Shadow Priest
    267,  -- Destruction Warlock
    1467, -- Devastation Evoker
    262,  -- Elemental Shaman
    64,   -- Frost Mage
    252,  -- Unholy Death Knight
    72,   -- Fury Warrior
    70,   -- Retribution Paladin
    261,  -- Subtlety Rogue
    251,  -- Frost Death Knight
    259,  -- Assassination Rogue
    71,   -- Arms Warrior
    263,  -- Enhancement Shaman
    269,  -- Windwalker Monk
    577,  -- Havoc Demon Hunter
    260,  -- Outlaw Rogue
    103,  -- Feral Druid
    254,  -- Marksmanship Hunter
    253,  -- Beast Mastery Hunter
    255,  -- Survival Hunter
}

-- Class colors for UI display
addon.ClassColors = {
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    DRUID = { r = 1.00, g = 0.49, b = 0.04 },
    EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
    MONK = { r = 0.00, g = 1.00, b = 0.60 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
    ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
    SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
    WARLOCK = { r = 0.53, g = 0.53, b = 0.93 },
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
}

-- Localized class names
addon.ClassNames = {
    DEATHKNIGHT = "Death Knight",
    DEMONHUNTER = "Demon Hunter",
    DRUID = "Druid",
    EVOKER = "Evoker",
    HUNTER = "Hunter",
    MAGE = "Mage",
    MONK = "Monk",
    PALADIN = "Paladin",
    PRIEST = "Priest",
    ROGUE = "Rogue",
    SHAMAN = "Shaman",
    WARLOCK = "Warlock",
    WARRIOR = "Warrior",
}
