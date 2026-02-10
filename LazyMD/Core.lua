-- LazyMD Core
-- Simple Misdirection macro management - targets your mouseover

local addonName, addon = ...

-- Create main frame for event handling
local LazyMD = CreateFrame("Frame", "LazyMDFrame")
addon.frame = LazyMD

-- Addon state
addon.macroName = "LazyMD"
addon.currentTarget = nil

-- Print function
function addon:Print(...)
    print("|cFFABD473[LazyMD]|r", ...)
end

-- Update the LazyMD macro to target current mouseover
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
        "#showtooltip Misdirection\n/cast [@%s,help,nodead][@pet,exists,nodead] Misdirection",
        mouseoverName
    )

    local macroIndex = GetMacroIndexByName(self.macroName)

    if macroIndex > 0 then
        EditMacro(macroIndex, self.macroName, nil, macroBody)
        self:Print("Target set: " .. mouseoverName)
    else
        local numGlobal = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            CreateMacro(self.macroName, "ability_hunter_misdirection", macroBody, false)
            self:Print("Created macro for: " .. mouseoverName)
        else
            self:Print("Cannot create macro - maximum global macros reached!")
        end
    end
end

-- Create the update macro if it doesn't exist
local function CreateUpdateMacro()
    local updateMacroName = "LazyMD Update"
    local macroIndex = GetMacroIndexByName(updateMacroName)

    if macroIndex == 0 then
        local numGlobal = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            CreateMacro(updateMacroName, "INV_Misc_Gear_01", "/lmd update", false)
            addon:Print("Created '" .. updateMacroName .. "' macro.")
        end
    end
end

-- Create fallback LazyMD macro if it doesn't exist
local function CreateMainMacro()
    local macroIndex = GetMacroIndexByName(addon.macroName)

    if macroIndex == 0 then
        local numGlobal = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            local macroBody = "#showtooltip Misdirection\n/cast [@mouseover,help,nodead][@target,help,nodead][@pet,exists,nodead][@focus,help,nodead] Misdirection"
            CreateMacro(addon.macroName, "ability_hunter_misdirection", macroBody, false)
        end
    end
end

-- Event handler
function LazyMD:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            addon:Print("Loaded. Mouseover a player and click 'LazyMD Update' to set target.")
        end
    elseif event == "PLAYER_LOGIN" then
        CreateMainMacro()
        CreateUpdateMacro()
    end
end

-- Register events
LazyMD:RegisterEvent("ADDON_LOADED")
LazyMD:RegisterEvent("PLAYER_LOGIN")
LazyMD:SetScript("OnEvent", LazyMD.OnEvent)

-- Slash commands
SLASH_LAZYMD1 = "/lazymd"
SLASH_LAZYMD2 = "/lmd"

SlashCmdList["LAZYMD"] = function(msg)
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
            local macroBody = "#showtooltip Misdirection\n/cast [@mouseover,help,nodead][@target,help,nodead][@pet,exists,nodead][@focus,help,nodead] Misdirection"
            EditMacro(macroIndex, addon.macroName, nil, macroBody)
            addon:Print("Target cleared (using fallback)")
        end

    else
        addon:Print("Commands:")
        addon:Print("  /lmd update - Set target to mouseover")
        addon:Print("  /lmd status - Show current target")
        addon:Print("  /lmd clear - Clear target (use fallback)")
    end
end

_G.LazyMD = addon
