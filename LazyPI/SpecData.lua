-- LazyPI Specialization Data
-- Contains all class specializations with their IDs and default priority values

local addonName, addon = ...

-- Specialization IDs from the game
-- Format: [specID] = { name = "Spec Name", class = "CLASS", role = "role", defaultPriority = number }
-- Higher priority number = more valuable target for Power Infusion

addon.SpecInfo = {
    -- Death Knight
    [250] = { name = "Blood", class = "DEATHKNIGHT", role = "TANK", defaultPriority = 0 },
    [251] = { name = "Frost", class = "DEATHKNIGHT", role = "DAMAGER", defaultPriority = 50 },
    [252] = { name = "Unholy", class = "DEATHKNIGHT", role = "DAMAGER", defaultPriority = 55 },

    -- Demon Hunter
    [577] = { name = "Havoc", class = "DEMONHUNTER", role = "DAMAGER", defaultPriority = 45 },
    [581] = { name = "Vengeance", class = "DEMONHUNTER", role = "TANK", defaultPriority = 0 },

    -- Druid
    [102] = { name = "Balance", class = "DRUID", role = "DAMAGER", defaultPriority = 70 },
    [103] = { name = "Feral", class = "DRUID", role = "DAMAGER", defaultPriority = 40 },
    [104] = { name = "Guardian", class = "DRUID", role = "TANK", defaultPriority = 0 },
    [105] = { name = "Restoration", class = "DRUID", role = "HEALER", defaultPriority = 0 },

    -- Evoker
    [1467] = { name = "Devastation", class = "EVOKER", role = "DAMAGER", defaultPriority = 65 },
    [1468] = { name = "Preservation", class = "EVOKER", role = "HEALER", defaultPriority = 0 },
    [1473] = { name = "Augmentation", class = "EVOKER", role = "DAMAGER", defaultPriority = 75 },

    -- Hunter
    [253] = { name = "Beast Mastery", class = "HUNTER", role = "DAMAGER", defaultPriority = 35 },
    [254] = { name = "Marksmanship", class = "HUNTER", role = "DAMAGER", defaultPriority = 40 },
    [255] = { name = "Survival", class = "HUNTER", role = "DAMAGER", defaultPriority = 35 },

    -- Mage
    [62] = { name = "Arcane", class = "MAGE", role = "DAMAGER", defaultPriority = 100 },
    [63] = { name = "Fire", class = "MAGE", role = "DAMAGER", defaultPriority = 80 },
    [64] = { name = "Frost", class = "MAGE", role = "DAMAGER", defaultPriority = 60 },

    -- Monk
    [268] = { name = "Brewmaster", class = "MONK", role = "TANK", defaultPriority = 0 },
    [270] = { name = "Mistweaver", class = "MONK", role = "HEALER", defaultPriority = 0 },
    [269] = { name = "Windwalker", class = "MONK", role = "DAMAGER", defaultPriority = 45 },

    -- Paladin
    [65] = { name = "Holy", class = "PALADIN", role = "HEALER", defaultPriority = 0 },
    [66] = { name = "Protection", class = "PALADIN", role = "TANK", defaultPriority = 0 },
    [70] = { name = "Retribution", class = "PALADIN", role = "DAMAGER", defaultPriority = 55 },

    -- Priest
    [256] = { name = "Discipline", class = "PRIEST", role = "HEALER", defaultPriority = 0 },
    [257] = { name = "Holy", class = "PRIEST", role = "HEALER", defaultPriority = 0 },
    [258] = { name = "Shadow", class = "PRIEST", role = "DAMAGER", defaultPriority = 70 },

    -- Rogue
    [259] = { name = "Assassination", class = "ROGUE", role = "DAMAGER", defaultPriority = 50 },
    [260] = { name = "Outlaw", class = "ROGUE", role = "DAMAGER", defaultPriority = 45 },
    [261] = { name = "Subtlety", class = "ROGUE", role = "DAMAGER", defaultPriority = 55 },

    -- Shaman
    [262] = { name = "Elemental", class = "SHAMAN", role = "DAMAGER", defaultPriority = 65 },
    [263] = { name = "Enhancement", class = "SHAMAN", role = "DAMAGER", defaultPriority = 50 },
    [264] = { name = "Restoration", class = "SHAMAN", role = "HEALER", defaultPriority = 0 },

    -- Warlock
    [265] = { name = "Affliction", class = "WARLOCK", role = "DAMAGER", defaultPriority = 85 },
    [266] = { name = "Demonology", class = "WARLOCK", role = "DAMAGER", defaultPriority = 75 },
    [267] = { name = "Destruction", class = "WARLOCK", role = "DAMAGER", defaultPriority = 70 },

    -- Warrior
    [71] = { name = "Arms", class = "WARRIOR", role = "DAMAGER", defaultPriority = 50 },
    [72] = { name = "Fury", class = "WARRIOR", role = "DAMAGER", defaultPriority = 55 },
    [73] = { name = "Protection", class = "WARRIOR", role = "TANK", defaultPriority = 0 },
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

-- Get sorted list of specs by class for UI
function addon:GetSpecsByClass()
    local specsByClass = {}

    for specID, info in pairs(self.SpecInfo) do
        if not specsByClass[info.class] then
            specsByClass[info.class] = {}
        end
        table.insert(specsByClass[info.class], {
            specID = specID,
            name = info.name,
            role = info.role,
        })
    end

    -- Sort specs within each class alphabetically
    for class, specs in pairs(specsByClass) do
        table.sort(specs, function(a, b)
            return a.name < b.name
        end)
    end

    return specsByClass
end

-- Class display order for UI
addon.ClassOrder = {
    "DEATHKNIGHT",
    "DEMONHUNTER",
    "DRUID",
    "EVOKER",
    "HUNTER",
    "MAGE",
    "MONK",
    "PALADIN",
    "PRIEST",
    "ROGUE",
    "SHAMAN",
    "WARLOCK",
    "WARRIOR",
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
