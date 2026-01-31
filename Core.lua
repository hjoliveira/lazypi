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
    specPriorities = {},  -- Will be populated from SpecInfo defaults
    enabled = true,
    debugMode = false,
    autoUpdateMacro = true,
    includeSelf = false,  -- Whether to include self as a potential target
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

    -- Initialize spec priorities from defaults if empty
    if not next(LazyPIDB.specPriorities) then
        for specID, info in pairs(addon.SpecInfo) do
            LazyPIDB.specPriorities[specID] = info.defaultPriority
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

-- Get the priority for a given spec ID
function addon:GetSpecPriority(specID)
    if not specID then return 0 end
    return LazyPIDB.specPriorities[specID] or 0
end

-- Set the priority for a given spec ID
function addon:SetSpecPriority(specID, priority)
    if not specID then return end
    LazyPIDB.specPriorities[specID] = priority
    self:UpdateBestTarget()
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
        -- Solo - only self if includeSelf is enabled
        if LazyPIDB.includeSelf then
            local specID = self:GetUnitSpecInfo("player")
            if specID then
                table.insert(members, {
                    unit = "player",
                    name = UnitName("player"),
                    specID = specID,
                    priority = self:GetSpecPriority(specID),
                })
            end
        end
        return members
    end

    local prefix = inRaid and "raid" or "party"
    local numMembers = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1

    -- Add party/raid members
    for i = 1, numMembers do
        local unit = prefix .. i
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsDeadOrGhost(unit) then
            local specID = self:GetUnitSpecInfo(unit)
            local priority = self:GetSpecPriority(specID)

            table.insert(members, {
                unit = unit,
                name = UnitName(unit),
                specID = specID,
                priority = priority,
            })
        end
    end

    -- Add self if in party (not included in party1-4) or if includeSelf is enabled for raids
    if not inRaid or LazyPIDB.includeSelf then
        local playerUnit = inRaid and "player" or "player"
        if UnitExists(playerUnit) and not UnitIsDeadOrGhost(playerUnit) then
            local specID = self:GetUnitSpecInfo("player")
            local priority = self:GetSpecPriority(specID)

            -- In party mode, always include self; in raid, only if includeSelf
            if not inRaid or LazyPIDB.includeSelf then
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

    -- Sort by priority (highest first)
    table.sort(members, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)

    local best = members[1]

    -- Only return if priority is greater than 0
    if best and best.priority and best.priority > 0 then
        self:Debug("Best target:", best.name, "Priority:", best.priority)
        return best
    end

    self:Debug("No target with priority > 0 found")
    return nil
end

-- Update the best target and refresh macro
function addon:UpdateBestTarget()
    if not LazyPIDB.enabled then
        return
    end

    local newBest = self:FindBestTarget()

    if newBest then
        if not self.bestTarget or self.bestTarget.name ~= newBest.name then
            self.bestTarget = newBest
            self:Debug("New best target:", newBest.name)

            if LazyPIDB.autoUpdateMacro then
                self:UpdateMacro()
            end
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

    if self.bestTarget and self.bestTarget.name then
        local targetName = self.bestTarget.name
        local specInfo = self.SpecInfo[self.bestTarget.specID]
        local specName = specInfo and specInfo.name or "Unknown"

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

-- Event handler
function LazyPI:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            InitializeDB()
            addon.initialized = true
            addon:Print("Loaded. Type /lazypi or /lpi for options.")

            -- Initial update after a short delay
            C_Timer.After(2, function()
                addon:RequestGroupInspect()
                addon:UpdateBestTarget()
            end)
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        if addon.initialized then
            addon:Debug("Group roster changed")
            C_Timer.After(1, function()
                addon:RequestGroupInspect()
            end)
            C_Timer.After(2, function()
                addon:UpdateBestTarget()
            end)
        end

    elseif event == "INSPECT_READY" then
        local guid = ...
        addon:Debug("Inspect ready for:", guid)
        C_Timer.After(0.5, function()
            addon:UpdateBestTarget()
        end)

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        addon:Debug("Spec changed for:", unit or "unknown")
        C_Timer.After(0.5, function()
            addon:UpdateBestTarget()
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        if addon.initialized then
            C_Timer.After(3, function()
                addon:RequestGroupInspect()
                addon:UpdateBestTarget()
            end)
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if addon.initialized then
            C_Timer.After(2, function()
                addon:RequestGroupInspect()
                addon:UpdateBestTarget()
            end)
        end
    end
end

-- Register events
LazyPI:RegisterEvent("ADDON_LOADED")
LazyPI:RegisterEvent("GROUP_ROSTER_UPDATE")
LazyPI:RegisterEvent("INSPECT_READY")
LazyPI:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
LazyPI:RegisterEvent("PLAYER_ENTERING_WORLD")
LazyPI:RegisterEvent("ZONE_CHANGED_NEW_AREA")
LazyPI:SetScript("OnEvent", LazyPI.OnEvent)

-- Slash commands
SLASH_LAZYPI1 = "/lazypi"
SLASH_LAZYPI2 = "/lpi"

SlashCmdList["LAZYPI"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "toggle" then
        LazyPIDB.enabled = not LazyPIDB.enabled
        addon:Print("Addon " .. (LazyPIDB.enabled and "enabled" or "disabled"))
        if LazyPIDB.enabled then
            addon:UpdateBestTarget()
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
        addon:Print("  Enabled: " .. tostring(LazyPIDB.enabled))
        addon:Print("  Auto-update: " .. tostring(LazyPIDB.autoUpdateMacro))
        if addon.bestTarget then
            local specInfo = addon.SpecInfo[addon.bestTarget.specID]
            local specName = specInfo and specInfo.name or "Unknown"
            addon:Print("  Best target: " .. addon.bestTarget.name .. " (" .. specName .. ", priority: " .. addon.bestTarget.priority .. ")")
        else
            addon:Print("  Best target: None")
        end

    elseif cmd == "list" then
        addon:Print("Current group members and priorities:")
        local members = addon:GetGroupMembers()
        table.sort(members, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
        for _, member in ipairs(members) do
            local specInfo = addon.SpecInfo[member.specID]
            local specName = specInfo and specInfo.name or "Unknown"
            addon:Print("  " .. member.name .. " - " .. specName .. " (Priority: " .. (member.priority or 0) .. ")")
        end

    elseif cmd == "config" or cmd == "options" or cmd == "" then
        addon:OpenSettings()

    elseif cmd == "reset" then
        -- Reset priorities to defaults
        for specID, info in pairs(addon.SpecInfo) do
            LazyPIDB.specPriorities[specID] = info.defaultPriority
        end
        addon:Print("Priorities reset to defaults!")
        addon:UpdateBestTarget()

    else
        addon:Print("Commands:")
        addon:Print("  /lpi - Open settings")
        addon:Print("  /lpi toggle - Enable/disable addon")
        addon:Print("  /lpi update - Force macro update")
        addon:Print("  /lpi status - Show current status")
        addon:Print("  /lpi list - List group members and priorities")
        addon:Print("  /lpi reset - Reset priorities to defaults")
        addon:Print("  /lpi debug - Toggle debug mode")
    end
end

-- Store addon table globally for settings access
_G.LazyPI = addon
