-- LazyPI Core
-- Simple spell macro management - targets your mouseover
-- Supports Power Infusion (Priest) and Misdirection (Hunter)

local addonName, addon = ...

-- Create main frame for event handling
local LazyPI = CreateFrame("Frame", "LazyPIFrame")
addon.frame = LazyPI

-- Addon state
addon.macroName = "LazyPI"
addon.currentTarget = nil
addon.spellName = nil
addon.spellIcon = nil
addon.fallbackCondition = nil
addon.fallbackChain = nil

-- Configure spell based on player class
local function ConfigureForClass()
    local _, playerClass = UnitClass("player")

    if playerClass == "HUNTER" then
        addon.spellName = "Misdirection"
        addon.spellIcon = "ability_hunter_misdirection"
        addon.fallbackCondition = "@pet,exists,nodead"
        addon.fallbackChain = "[@mouseover,help,nodead][@target,help,nodead][@pet,exists,nodead][@focus,help,nodead]"
    else
        addon.spellName = "Power Infusion"
        addon.spellIcon = "spell_holy_powerinfusion"
        addon.fallbackCondition = "@player"
        addon.fallbackChain = "[@mouseover,help,nodead][@target,help,nodead][@player]"
    end
end

ConfigureForClass()

-- Print function
function addon:Print(...)
    print("|cFF9966FF[LazyPI]|r", ...)
end

-- Update the LazyPI macro to target current mouseover
function addon:UpdateMacroToMouseover()
    if InCombatLockdown() then
        self:Print("Cannot update macro during combat")
        return
    end

    local mouseoverName = UnitName("mouseover")

    if not mouseoverName then
        self:Print("No mouseover target")
        return
    end

    if not UnitIsPlayer("mouseover") then
        self:Print("Mouseover is not a player")
        return
    end

    if not UnitIsFriend("player", "mouseover") then
        self:Print("Mouseover is not friendly")
        return
    end

    self.currentTarget = mouseoverName

    local macroBody = string.format(
        "#showtooltip %s\n/cast [@%s,help,nodead][%s] %s",
        self.spellName, mouseoverName, self.fallbackCondition, self.spellName
    )

    local macroIndex = GetMacroIndexByName(self.macroName)

    if macroIndex > 0 then
        EditMacro(macroIndex, self.macroName, nil, macroBody)
        self:Print("Target set: " .. mouseoverName)
    else
        local numGlobal = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            CreateMacro(self.macroName, self.spellIcon, macroBody, false)
            self:Print("Created macro for: " .. mouseoverName)
        else
            self:Print("Cannot create macro - maximum global macros reached!")
        end
    end
end

-- Create the update macro if it doesn't exist
local function CreateUpdateMacro()
    local updateMacroName = "LazyPI Update"
    local macroIndex = GetMacroIndexByName(updateMacroName)

    if macroIndex == 0 then
        local numGlobal = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            CreateMacro(updateMacroName, "INV_Misc_Gear_01", "/lpi update", false)
            addon:Print("Created '" .. updateMacroName .. "' macro.")
        end
    end
end

-- Create fallback LazyPI macro if it doesn't exist
local function CreateMainMacro()
    local macroIndex = GetMacroIndexByName(addon.macroName)

    if macroIndex == 0 then
        local numGlobal = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            local macroBody = string.format(
                "#showtooltip %s\n/cast %s %s",
                addon.spellName, addon.fallbackChain, addon.spellName
            )
            CreateMacro(addon.macroName, addon.spellIcon, macroBody, false)
        end
    end
end

-- Event handler
function LazyPI:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            addon:Print("Loaded. Mouseover a player and click 'LazyPI Update' to set target.")
        end
    elseif event == "PLAYER_LOGIN" then
        CreateMainMacro()
        CreateUpdateMacro()
    end
end

-- Register events
LazyPI:RegisterEvent("ADDON_LOADED")
LazyPI:RegisterEvent("PLAYER_LOGIN")
LazyPI:SetScript("OnEvent", LazyPI.OnEvent)

-- Slash commands
SLASH_LAZYPI1 = "/lazypi"
SLASH_LAZYPI2 = "/lpi"

SlashCmdList["LAZYPI"] = function(msg)
    local cmd = msg:match("^(%S*)") or ""
    cmd = cmd:lower()

    if cmd == "update" then
        addon:UpdateMacroToMouseover()

    elseif cmd == "status" then
        if addon.currentTarget then
            addon:Print("Current target: " .. addon.currentTarget)
        else
            addon:Print("No target set")
        end

    elseif cmd == "clear" then
        if InCombatLockdown() then
            addon:Print("Cannot update macro during combat")
            return
        end
        addon.currentTarget = nil
        local macroIndex = GetMacroIndexByName(addon.macroName)
        if macroIndex > 0 then
            local macroBody = string.format(
                "#showtooltip %s\n/cast %s %s",
                addon.spellName, addon.fallbackChain, addon.spellName
            )
            EditMacro(macroIndex, addon.macroName, nil, macroBody)
            addon:Print("Target cleared (using fallback)")
        end

    else
        addon:Print("Commands:")
        addon:Print("  /lpi update - Set target to mouseover")
        addon:Print("  /lpi status - Show current target")
        addon:Print("  /lpi clear - Clear target (use fallback)")
    end
end

_G.LazyPI = addon
