-- LazyPI Core
-- Main addon functionality for Power Infusion macro management

local addonName, addon = ...

-- Create main frame for event handling
local LazyPI = CreateFrame("Frame", "LazyPIFrame")
addon.frame = LazyPI

-- Addon state
addon.initialized = false
addon.macroName = "LazyPI"
addon.bestTarget = nil

-- Default saved variables
local defaults = {
    specPriorityOrder = {},  -- Will be populated from DefaultPriorityOrder
    debugMode = false,
}

-- Initialize saved variables
local function InitializeDB()
    if not LazyPIDB then
        LazyPIDB = {}
    end

    -- Apply defaults
    for key, value in pairs(defaults) do
        if LazyPIDB[key] == nil then
            LazyPIDB[key] = value
        end
    end

    -- Initialize spec priority order from defaults if empty
    if not LazyPIDB.specPriorityOrder or #LazyPIDB.specPriorityOrder == 0 then
        LazyPIDB.specPriorityOrder = {}
        for i, specID in ipairs(addon.DefaultPriorityOrder) do
            LazyPIDB.specPriorityOrder[i] = specID
        end
    end
end

-- Debug print function
function addon:Debug(...)
    if LazyPIDB and LazyPIDB.debugMode then
        print("|cFF00FF00[LazyPI Debug]|r", ...)
    end
end

-- Print function
function addon:Print(...)
    print("|cFF9966FF[LazyPI]|r", ...)
end

-- Get the priority for a given spec ID (lower number = higher priority)
function addon:GetSpecPriority(specID)
    if not specID then return 999 end

    -- Find position in the ordered list
    for i, id in ipairs(LazyPIDB.specPriorityOrder) do
        if id == specID then
            return i
        end
    end

    -- Not in list (tank/healer spec) - lowest priority
    return 999
end

-- Get spec info for a unit
function addon:GetUnitSpecInfo(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        return nil
    end

    local specID

    if UnitIsUnit(unit, "player") then
        specID = GetSpecializationInfo(GetSpecialization())
    else
        local inspectSpec = GetInspectSpecialization(unit)
        if inspectSpec and inspectSpec > 0 then
            specID = inspectSpec
        end
    end

    return specID
end

-- Get all group/raid members with their specs
function addon:GetGroupMembers()
    local members = {}
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()

    if not inRaid and not inGroup then
        return members
    end

    local prefix = inRaid and "raid" or "party"
    local numMembers = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1

    -- Add party/raid members
    for i = 1, numMembers do
        local unit = prefix .. i
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsDeadOrGhost(unit) then
            local specID = self:GetUnitSpecInfo(unit)
            -- Only add DPS specs (those in SpecInfo)
            if specID and self.SpecInfo[specID] then
                local priority = self:GetSpecPriority(specID)
                table.insert(members, {
                    unit = unit,
                    name = UnitName(unit),
                    specID = specID,
                    priority = priority,
                })
            end
        end
    end

    -- Add self if in party (not included in party1-4)
    if not inRaid then
        if UnitExists("player") and not UnitIsDeadOrGhost("player") then
            local specID = self:GetUnitSpecInfo("player")
            -- Only add if DPS spec
            if specID and self.SpecInfo[specID] then
                local priority = self:GetSpecPriority(specID)
                table.insert(members, {
                    unit = "player",
                    name = UnitName("player"),
                    specID = specID,
                    priority = priority,
                })
            end
        end
    end

    return members
end

-- Find the best target based on spec priorities
function addon:FindBestTarget()
    local members = self:GetGroupMembers()

    if #members == 0 then
        self:Debug("No valid group members found")
        return nil
    end

    -- Sort by priority (lower number = higher priority)
    table.sort(members, function(a, b)
        return (a.priority or 999) < (b.priority or 999)
    end)

    local best = members[1]

    -- Only return if the spec is in our list (priority < 999)
    if best and best.priority and best.priority < 999 then
        self:Debug("Best target:", best.name, "Priority:", best.priority)
        return best
    end

    self:Debug("No valid DPS target found")
    return nil
end

-- Update the best target and refresh macro
function addon:UpdateBestTarget()
    local newBest = self:FindBestTarget()

    if newBest then
        if not self.bestTarget or self.bestTarget.name ~= newBest.name then
            self.bestTarget = newBest
            self:Debug("New best target:", newBest.name)

            self:UpdateMacro()
        end
    else
        self.bestTarget = nil
        if LazyPIDB.autoUpdateMacro then
            self:UpdateMacro()
        end
    end
end

-- Create or update the Power Infusion macro
function addon:UpdateMacro()
    local macroIndex = GetMacroIndexByName(self.macroName)
    local macroBody
    local targetName = nil
    local specName = nil

    if self.bestTarget and self.bestTarget.name then
        targetName = self.bestTarget.name
        local specInfo = self.SpecInfo[self.bestTarget.specID]
        specName = specInfo and specInfo.name or "Unknown"

        -- Create macro that targets the best player and casts PI
        macroBody = string.format(
            "#showtooltip Power Infusion\n/cast [@%s,help,nodead] Power Infusion",
            targetName
        )

        self:Debug("Updating macro for:", targetName, "(" .. specName .. ")")
    else
        -- Fallback macro - cast on mouseover or target
        macroBody = "#showtooltip Power Infusion\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Power Infusion"
        self:Debug("No best target, using fallback macro")
    end

    if macroIndex > 0 then
        -- Update existing macro
        EditMacro(macroIndex, self.macroName, nil, macroBody)
        if targetName then
            self:Print("Macro updated: " .. targetName .. " (" .. specName .. ")")
        else
            self:Print("Macro updated: No target (using fallback)")
        end
    else
        -- Create new macro
        local numGlobal, numPerChar = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            CreateMacro(self.macroName, "INV_MISC_QUESTIONMARK", macroBody, false)
            self:Print("Created macro '" .. self.macroName .. "'. Drag it to your action bar!")
        else
            self:Print("Cannot create macro - maximum global macros reached!")
        end
    end
end

-- Request inspection of group members to get their specs
function addon:RequestGroupInspect()
    if not CanInspect then return end

    local inRaid = IsInRaid()
    local inGroup = IsInGroup()

    if not inRaid and not inGroup then
        return
    end

    local prefix = inRaid and "raid" or "party"
    local numMembers = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1

    for i = 1, numMembers do
        local unit = prefix .. i
        if UnitExists(unit) and UnitIsPlayer(unit) and CanInspect(unit) and UnitIsConnected(unit) then
            -- Check if we can inspect (in range, etc.)
            if CheckInteractDistance(unit, 1) then
                NotifyInspect(unit)
            end
        end
    end
end

-- Create the update macro if it doesn't exist
local function CreateUpdateMacro()
    local updateMacroName = "LazyPI Update"
    local macroIndex = GetMacroIndexByName(updateMacroName)

    if macroIndex == 0 then
        local numGlobal, numPerChar = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            CreateMacro(updateMacroName, "INV_Misc_Gear_01", "/lpi update", false)
            addon:Print("Created '" .. updateMacroName .. "' macro.")
        end
    end
end

-- Event handler
function LazyPI:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            InitializeDB()
            addon.initialized = true
            addon:Print("Loaded. Type /lpi update to set target.")
        end
    elseif event == "PLAYER_LOGIN" then
        -- Create update macro after login (macros not available during ADDON_LOADED)
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
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "options" or cmd == "" then
        if addon.settingsCategory then
            Settings.OpenToCategory(addon.settingsCategory:GetID())
        else
            addon:Print("Settings not yet loaded. Try again in a moment.")
        end

    elseif cmd == "update" then
        addon:RequestGroupInspect()
        C_Timer.After(1, function()
            addon:UpdateBestTarget()
            addon:Print("Macro updated!")
        end)

    elseif cmd == "debug" then
        LazyPIDB.debugMode = not LazyPIDB.debugMode
        addon:Print("Debug mode " .. (LazyPIDB.debugMode and "enabled" or "disabled"))

    elseif cmd == "status" then
        addon:Print("Status:")
        if addon.bestTarget then
            local specInfo = addon.SpecInfo[addon.bestTarget.specID]
            local specName = specInfo and specInfo.name or "Unknown"
            addon:Print("  Best target: " .. addon.bestTarget.name .. " (" .. specName .. ", rank: " .. addon.bestTarget.priority .. ")")
        else
            addon:Print("  Best target: None")
        end

    elseif cmd == "list" then
        addon:Print("Current group members and priorities:")
        local members = addon:GetGroupMembers()
        table.sort(members, function(a, b) return (a.priority or 999) < (b.priority or 999) end)
        for _, member in ipairs(members) do
            local specInfo = addon.SpecInfo[member.specID]
            local specName = specInfo and specInfo.name or "Unknown"
            addon:Print("  " .. member.name .. " - " .. specName .. " (Rank: " .. (member.priority or "N/A") .. ")")
        end

    elseif cmd == "config" or cmd == "options" or cmd == "" then
        addon:OpenSettings()

    elseif cmd == "reset" then
        -- Reset priorities to defaults
        LazyPIDB.specPriorityOrder = {}
        for i, specID in ipairs(addon.DefaultPriorityOrder) do
            LazyPIDB.specPriorityOrder[i] = specID
        end
        addon:Print("Priorities reset to defaults!")
        addon:UpdateBestTarget()

    else
        addon:Print("Commands:")
        addon:Print("  /lpi - Open settings")
        addon:Print("  /lpi update - Force macro update")
        addon:Print("  /lpi status - Show current status")
        addon:Print("  /lpi list - List group members and priorities")
        addon:Print("  /lpi reset - Reset priorities to defaults")
        addon:Print("  /lpi debug - Toggle debug mode")
    end
end

-- Store addon table globally for settings access
_G.LazyPI = addon
